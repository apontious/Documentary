//
//  TextDocument.h
//  Documentary
//
//  Created by Andrew Pontious on 1/11/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some right reserved: http://opensource.org/licenses/mit-license.php
//

#import <Cocoa/Cocoa.h>

@interface TextDocument : NSDocument

@property (nonatomic, copy, readonly) NSString *text;

@end
