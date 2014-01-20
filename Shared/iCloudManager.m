//
//  iCloudManager.m
//  Documentary
//
//  Created by Andrew Pontious on 1/12/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some right reserved: http://opensource.org/licenses/mit-license.php
//

#import "iCloudManager.h"

@interface iCloudManager ()

@property (copy, nonatomic) id <NSObject, NSCopying, NSCoding> currentiCloudToken;
@property (nonatomic) NSURL *ubiquityContainerURL;
@property (nonatomic) NSMetadataQuery *query;

@end

NSString *const kUbiquityIdentityTokenKey = @"ubiquityIdentityToken";

NSString *const kICloudManagerDocumentURLsUpdatedNotification = @"kICloudManagerDocumentURLsUpdated";
NSString *const kICloudManagerDocumentURLsKey = @"kICloudManagerDocumentURLs";

@implementation iCloudManager

#pragma mark - Private Methods

- (void)iCloudAccountAvailabilityChanged:(NSNotification *)notification {
    // TODO: Delete any local data associated with previous files.
}

- (void)startQuery {
    // Code originally from http://www.raywenderlich.com/6031/beginning-icloud-in-ios-5-tutorial-part-2
    
    self.query = [[NSMetadataQuery alloc] init];
    self.query.searchScopes = @[NSMetadataQueryUbiquitousDocumentsScope];
    self.query.predicate = [NSPredicate predicateWithFormat:@"%K like '*'", NSMetadataItemFSNameKey];
    self.query.notificationBatchingInterval = 0.0; // Doesn't seem to affect much
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(queryDidFinishGathering:)
                                                 name:NSMetadataQueryDidFinishGatheringNotification
                                               object:self.query];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(queryDidUpdate:)
                                                 name:NSMetadataQueryDidUpdateNotification
                                               object:self.query];
    
    [self.query startQuery];
}

- (void)listAndDownloadDocuments {
    [self.query disableUpdates];
    
    NSArray *oldDocumentURLS = [self.documentURLs copy];
    
    NSMutableArray *newDocumentURLS = [NSMutableArray array];
    
    NSArray *results = [self.query.results copy];
    
    for (NSMetadataItem *item in results) {
        NSURL *url = [item valueForAttribute:NSMetadataItemURLKey];
        
        NSError *error = nil;
        NSString *downloadingStatus = nil;
        
        if ([url getResourceValue:&downloadingStatus forKey:NSURLUbiquitousItemDownloadingStatusKey error:&error] == YES) {
            if ([downloadingStatus isEqualToString:NSURLUbiquitousItemDownloadingStatusNotDownloaded] == YES) {
                if ([[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL:url error:&error] == NO) {
                    NSLog(@"Starting download for URL %@ failed: %@", url, error);
                }
            } else {
                [newDocumentURLS addObject:url];
            }
        }
    }
    
    [newDocumentURLS sortUsingComparator:^NSComparisonResult(NSURL *url1, NSURL *url2) {
        return [[url1 lastPathComponent] compare:[url2 lastPathComponent] options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch | NSForcedOrderingSearch];
    }];
    
    if ([oldDocumentURLS isEqualToArray:newDocumentURLS] == NO) {
        self.documentURLs = newDocumentURLS;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kICloudManagerDocumentURLsUpdatedNotification object:self userInfo:@{kICloudManagerDocumentURLsKey : newDocumentURLS}];
    }
    
    [self.query enableUpdates];
}

- (void)queryDidFinishGathering:(NSNotification *)notification {
    [self listAndDownloadDocuments];
}

- (void)queryDidUpdate:(NSNotification *)notification {
    [self listAndDownloadDocuments];
}

#pragma mark - Public Methods

- (id)init {
    self = [super init];
    if (self != nil) {
        self.currentiCloudToken = [[NSFileManager defaultManager] ubiquityIdentityToken];
        
        // Regular apps should compare token against previously-saved token to determine if we're currently using a different iCloud account, and adjust UI/caches/etc. to match.
        // Code copied from iCloud Design Guide
        
        // TODO: if we do this here, we should call whatever method also handles hearing that you've logged out of an iCloud account.
        
        if (self.currentiCloudToken) {
            NSData *newTokenData = [NSKeyedArchiver archivedDataWithRootObject:self.currentiCloudToken];
            [[NSUserDefaults standardUserDefaults] setObject:newTokenData forKey:kUbiquityIdentityTokenKey];
        } else {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey: kUbiquityIdentityTokenKey];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector: @selector(iCloudAccountAvailabilityChanged:)
                                                     name:NSUbiquityIdentityDidChangeNotification
                                                   object:nil];
        
        // Normally, you'd ask the user if they want to use iCloud and remember the result. Won't do that for our little sample app.
        
        dispatch_async(dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            NSURL *url = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
            if (url != nil) {
                // Your app can write to the ubiquity container
                dispatch_async (dispatch_get_main_queue (), ^(void) {
                    self.ubiquityContainerURL = url;
 
                    [self startQuery];
                });
            }
        });
    }
    
    return self;
}

- (void)createNewDocument:(void (^)(NSError *error))callback {
    
    // Iterating through these isn't ideal, because (a) it might be further modified while we work, and (b) there might be thousands of files, but it's a good start, so we poke the file system as little as possible in the most common case (few files + no other simultaneous activity).
    NSArray *documentURLs = [self.documentURLs copy];
    NSURL *ubiquityContainerDocumentsURL = [self.ubiquityContainerURL URLByAppendingPathComponent:@"Documents" isDirectory:YES];

    dispatch_async(dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {

        NSString *localizedDocumentNameStem = NSLocalizedString(@"Document", @"Constant portion of new document names, before the digit");
        
        NSInteger highestInteger = 0;
        
        for (NSURL *documentURL in documentURLs) {
            NSString *name = [self userVisibleNameForDocumentURL:documentURL];
            const NSRange range = [name rangeOfString:localizedDocumentNameStem options:NSCaseInsensitiveSearch | NSAnchoredSearch];
            if (range.length > 0) {
                // Due to NSAnchoredSearch, location should always be 0
                NSString *integerSubstring = [[name substringFromIndex:range.length] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                const NSInteger integerValue = [integerSubstring integerValue];
                if (integerValue > 0) {
                    NSString *integerSubstring2 = [NSString stringWithFormat:@"%ld", (long)integerValue];
                    if ([integerSubstring isEqualToString:integerSubstring2] == YES) {
                        if (integerValue > highestInteger) {
                            highestInteger = integerValue;
                        }
                    }
                }
            }
        }
        
        BOOL succeeded = NO;
        
        NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        
        for (NSInteger i = highestInteger + 1; i < highestInteger + 20 && succeeded == NO; i++) {
            NSString *newDocumentNamePlusExtension = [NSString stringWithFormat:@"%@ %ld.txt", localizedDocumentNameStem, (long)i];
            
            NSURL *newDocumentURL = [ubiquityContainerDocumentsURL URLByAppendingPathComponent:newDocumentNamePlusExtension];
            
            NSError *coordinateError = nil;
            
            __block BOOL writeResult = NO;
            __block NSError *writeError = nil;
            
            [fileCoordinator coordinateWritingItemAtURL:newDocumentURL options:0 error:&coordinateError byAccessor:^(NSURL *newURL) {
                writeResult = [@"" writeToURL:newURL atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
                NSLog(@"Write %@ success: %ld, error: %@", newDocumentNamePlusExtension, (long)writeResult, writeError);
            }];
            
            if (coordinateError == nil && writeResult == YES) {
                succeeded = YES;
            }
        }
        
        NSError *error = nil;
        
        if (succeeded == NO) {
            // TODO: set error
        }
        
        if (callback != nil) {
            dispatch_async (dispatch_get_main_queue (), ^(void) {
                callback(error);
            });
        }
    });
}

- (void)deleteDocument:(NSURL *)documentURL callback:(void (^)(NSError *error))callback {
    NSArray *documentURLs = [self.documentURLs copy];
    
    const NSInteger index = [documentURLs indexOfObject:documentURL];
    NSAssert(index != NSNotFound, @"doc URL %@ not found in doc URLS %@", documentURL, documentURLs);
    if (index == NSNotFound) {
        // TODO: fill in (internal?) error
    } else {
        dispatch_async(dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            NSError *error = nil;
            
            NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
            
            NSError *coordinateError = nil;
            
            __block BOOL deleteResult = NO;
            __block NSError *deleteError = nil;
            
            [fileCoordinator coordinateWritingItemAtURL:documentURL options:NSFileCoordinatorWritingForDeleting error:&coordinateError byAccessor:^(NSURL *url) {
                deleteResult = [[NSFileManager defaultManager] removeItemAtURL:url error:&deleteError];
                NSLog(@"Delete %@ success: %ld, error: %@", [[url URLByDeletingPathExtension] lastPathComponent], (long)deleteResult, deleteError);
            }];
            
            // TODO: I haven't checked what these error actually contain. If we were to try to use them to show the user the problem, there would probably need to be some massaging involved.
            
            if (coordinateError != nil) {
                error = coordinateError;
            } else if (deleteResult == NO) {
                if (deleteError != nil) {
                    error = deleteError;
                } else {
                    // TODO: set error
                }
            }
            
            if (callback != nil) {
                dispatch_async (dispatch_get_main_queue (), ^(void) {
                    callback(error);
                });
            }
        });
    }
}

- (void)renameDocument:(NSURL *)documentURL newName:(NSString *)newName callback:(void (^)(NSError *error))callback {
    
    NSArray *documentURLs = [self.documentURLs copy];
    NSURL *destinationURL = [[[documentURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:newName] URLByAppendingPathExtension:@"txt"];
    
    // Code originally from http://stackoverflow.com/questions/14358504/rename-an-icloud-document
    
    dispatch_async(dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        BOOL foundMatch = NO;
        
        for (NSURL *documentURL in documentURLs) {
            NSString *name = [self userVisibleNameForDocumentURL:documentURL];
            if ([name compare:newName options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch] == NSOrderedSame) {
                foundMatch = YES;
                break;
            }
        }
        
        NSError *error = nil;
        
        if (foundMatch == YES) {
            // TODO: fill in with real values.
            error = [NSError errorWithDomain:@"RenameError" code:0 userInfo:nil];
        } else {
            __block BOOL moveResult = NO;
            __block NSError *moveError = nil;
            
            NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];

            NSError *coordinateError = nil;
            
            [fileCoordinator coordinateWritingItemAtURL:documentURL
                                                options:NSFileCoordinatorWritingForMoving
                                       writingItemAtURL:destinationURL
                                                options:NSFileCoordinatorWritingForReplacing
                                                  error:&coordinateError
                                             byAccessor:^(NSURL *newURL1, NSURL *newURL2) {
                                                 moveResult = [[NSFileManager defaultManager] moveItemAtURL:documentURL toURL:destinationURL error:&moveError];
                                             }];
            
            // TODO: I haven't checked what these error actually contain. If we were to try to use them to show the user the problem, there would probably need to be some massaging involved.
            
            if (coordinateError != nil) {
                error = coordinateError;
            } else if (moveResult == NO) {
                if (moveError != nil) {
                    error = moveError;
                } else {
                    // TODO: set error
                }
            }
        }
        
        if (callback != nil) {
            dispatch_async (dispatch_get_main_queue (), ^(void) {
                callback(error);
            });
        }
    });
}

- (NSString *)userVisibleNameForDocumentURL:(NSURL *)documentURL {
     return [[documentURL URLByDeletingPathExtension] lastPathComponent];
}

@end
