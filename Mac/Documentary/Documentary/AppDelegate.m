//
//  AppDelegate.m
//  Documentary
//
//  Created by Andrew Pontious on 1/3/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some right reserved: http://opensource.org/licenses/mit-license.php
//

#import "AppDelegate.h"

#import "iCloudManager.h"
#import "TextDocument.h"

@interface AppDelegate ()

@property (nonatomic, weak) IBOutlet iCloudManager *iCloudManager;
@property (nonatomic, weak) IBOutlet NSArrayController *tableViewArrayController;

@property (nonatomic) BOOL creatingNewDocument;

@end

@implementation AppDelegate

#pragma mark Standard Methods

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    BOOL result = NO;
    
    if ([menuItem action] == @selector(newDocument:)) {
        result = (self.creatingNewDocument == NO);
    } else if ([menuItem action] == @selector(delete:) || [menuItem action] == @selector(openDocument:) || [menuItem action] == @selector(openDocumentInternally:)) {
        result = ([[self.tableViewArrayController selectionIndexes] count] > 0);
    } else {
        result = [super validateMenuItem:menuItem];
    }
    
    return result;
}

#pragma mark Public Methods

+ (AppDelegate *)appDelegate {
    return (AppDelegate *)[NSApplication sharedApplication].delegate;
}

#pragma mark Actions

- (void)newDocument:(id)sender {
    self.creatingNewDocument = YES;
    
    [self.iCloudManager createNewDocument:^(NSError *error) {
        NSLog(@"Creation error: %@", error);
        self.creatingNewDocument = NO;
    }];
}

- (void)openDocument:(id)sender {
    NSArray *urlsToOpen = [self.iCloudManager.documentURLs objectsAtIndexes:[self.tableViewArrayController selectionIndexes]];
    
    if ([urlsToOpen count] > 0) {
        // TODO: support opening multiple files
        NSURL *documentURL = urlsToOpen[0];
        
        LSOpenCFURLRef((__bridge CFURLRef)documentURL, NULL);
    }
}

- (void)openDocumentInternally:(id)sender {
    NSArray *urlsToOpen = [self.iCloudManager.documentURLs objectsAtIndexes:[self.tableViewArrayController selectionIndexes]];
    
    if ([urlsToOpen count] > 0) {
        // TODO: support opening multiple files
        NSURL *documentURL = urlsToOpen[0];
        
        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:documentURL display:YES completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
            NSLog(@"doc %@, error %@", document, error);
        }];
    }
}

- (void)delete:(id)sender {
    NSArray *urlsToDelete = [self.iCloudManager.documentURLs objectsAtIndexes:[self.tableViewArrayController selectionIndexes]];
    
    if ([urlsToDelete count] > 0) {
        NSAlert *alert = [[NSAlert alloc] init];
        
        NSString *messageText;
        if ([urlsToDelete count] == 1) {
            messageText = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to delete the document “%@”? This cannot be undone.", @"Delete confirmation alert message text for one document"), [self.iCloudManager userVisibleNameForDocumentURL:urlsToDelete[0]]];
        } else {
            messageText = NSLocalizedString(@"Are you sure you want to delete the selected documents? This cannot be undone.", @"Delete confirmation alert message text for more than one document");
            
            // TODO: support deleting multiple files. It is possible with one file coordinator call, just more work.
        }
        
        [alert setMessageText:messageText];
        
        [alert addButtonWithTitle:NSLocalizedString(@"Delete", @"Delete confirmation alert cancel button title")];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Delete confirmation alert cancel button title")];
        
        [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSAlertFirstButtonReturn) {
                [self.iCloudManager deleteDocument:urlsToDelete[0] callback:^(NSError *error) {
                    NSLog(@"Deletion error: %@", error);
                }];
            }
        }];
    }
}

@end
