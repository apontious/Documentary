//
//  NSURL+Documentary.m
//  Documentary
//
//  Created by Andrew Pontious on 1/11/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some right reserved: http://opensource.org/licenses/mit-license.php
//

#import "NSURL+Documentary.h"

#import "AppDelegate.h"
#import "iCloudManager.h"

@implementation NSURL (Documentary)

// Hacky way to be able to use NSURL objects in our table bindings, instead of a custom class.

- (NSString *)doc_name {
    return [[AppDelegate appDelegate].iCloudManager userVisibleNameForDocumentURL:self];
}

- (void)setDoc_name:(NSString *)name {
    NSURL *sourceURL = [self copy];
    
    [[AppDelegate appDelegate].iCloudManager renameDocument:sourceURL newName:name callback:^(NSError *error) {
        NSLog(@"Rename error: %@", error);
    }];
}

@end
