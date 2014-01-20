//
//  RenameViewController.m
//  Documentary
//
//  Created by Andrew Pontious on 1/19/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some right reserved: http://opensource.org/licenses/mit-license.php
//

#import "RenameViewController.h"

#import "TextDocument.h"
#import "AppDelegate.h"
#import "iCloudManager.h"
#import "DocumentViewController.h"

@interface RenameViewController ()

@property (nonatomic) IBOutlet UILabel *oldNameLabel;
@property (nonatomic) IBOutlet UITextField *nameTextField;

@end

@implementation RenameViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.oldNameLabel.text = [[AppDelegate appDelegate].iCloudManager userVisibleNameForDocumentURL:self.document.fileURL];
    self.nameTextField.text = self.oldNameLabel.text;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    NSString *newName = self.nameTextField.text;
    
    if ([newName length] > 0 && [newName isEqualToString:self.oldNameLabel.text] == NO) {
        [[AppDelegate appDelegate].iCloudManager renameDocument:self.document.fileURL newName:newName callback:^(NSError *error) {
            if (error != nil) {
                // TODO: show error
            } else {
                self.documentViewController.title = newName;
            }
        }];
    }
}

@end
