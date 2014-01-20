//
//  AppDelegate.h
//  Documentary
//
//  Created by Andrew Pontious on 1/3/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some right reserved: http://opensource.org/licenses/mit-license.php
//

#import <Cocoa/Cocoa.h>

@class iCloudManager;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (nonatomic, readonly) iCloudManager *iCloudManager;

+ (AppDelegate *)appDelegate;

@end
