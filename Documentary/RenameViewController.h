//
//  RenameViewController.h
//  Documentary
//
//  Created by Andrew Pontious on 1/19/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some right reserved: http://opensource.org/licenses/mit-license.php
//

#import <UIKit/UIKit.h>

@class TextDocument;
@class DocumentViewController;

@interface RenameViewController : UIViewController

@property (nonatomic) TextDocument *document;
@property (nonatomic, weak) DocumentViewController *documentViewController;

@end
