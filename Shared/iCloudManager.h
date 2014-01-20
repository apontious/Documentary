//
//  iCloudManager.h
//  Documentary
//
//  Created by Andrew Pontious on 1/12/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some right reserved: http://opensource.org/licenses/mit-license.php
//

#import <Foundation/Foundation.h>

@interface iCloudManager : NSObject

@property NSArray *documentURLs;

- (id)init;

// Asynchronous method.
// If error is nil, document creation succeeded.
// It would be better not to call again before a previous call has returned.
- (void)createNewDocument:(void (^)(NSError *error))callback;

// Asynchronous method.
// If error is nil, document deletion succeeded.
- (void)deleteDocument:(NSURL *)documentURL callback:(void (^)(NSError *error))callback;

// Asynchronous method.
// If error is nil, document rename succeeded.
- (void)renameDocument:(NSURL *)documentURL newName:(NSString *)newName callback:(void (^)(NSError *error))callback;

- (NSString *)userVisibleNameForDocumentURL:(NSURL *)documentURL;

@end

// Notifications

NSString *const kICloudManagerDocumentURLsUpdatedNotification;
// Keys for Notification Info Dictionary
// NSArray of URLs, sorted by last path component, case- and diacritic-insensitively
NSString *const kICloudManagerDocumentURLsKey;
