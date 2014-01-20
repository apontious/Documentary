//
//  DocumentViewController.m
//  Documentary
//
//  Created by Andrew Pontious on 1/19/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some right reserved: http://opensource.org/licenses/mit-license.php
//

#import "DocumentViewController.h"

#import "AppDelegate.h"
#import "iCloudManager.h"
#import "TextDocument.h"
#import "RenameViewController.h"

@interface DocumentViewController ()

@property (nonatomic, weak) IBOutlet UITextView *textView;

@property (nonatomic) TextDocument *document;

@end

NSString *const kRenameDocumentSegueIdentifier = @"renameDocument";

@implementation DocumentViewController

#pragma mark Standard Methods

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:self.textView];
    
    [self.document closeWithCompletionHandler:^(BOOL success) {
        // TODO show error on failure?
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.document == nil) {
        self.title = [[AppDelegate appDelegate].iCloudManager userVisibleNameForDocumentURL:self.documentURL];
        
        self.document = [[TextDocument alloc] initWithFileURL:self.documentURL];
    }

    [self.document openWithCompletionHandler:^(BOOL success) {
        if (success == YES) {
            self.textView.text = self.document.text;
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(textDidChange:)
                                                         name:UITextViewTextDidChangeNotification
                                                       object:self.textView];
        } else {
            // TODO: show error
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kRenameDocumentSegueIdentifier] == YES) {
        RenameViewController *renameViewController = segue.destinationViewController;
        
        renameViewController.document = self.document;
        renameViewController.documentViewController = self;
    }
}

#pragma mark Notifications

- (void)textDidChange:(NSNotification *)notification {
    // In a real app, we would only register a change after a certain amount of typing, or after a certain time. But not for this sample app.
    
    [[self.document.undoManager prepareWithInvocationTarget:self.document] setText:self.document.text];
    [self.document.undoManager setActionName:NSLocalizedString(@"Typing", @"Undo/redo label")];
    
    self.document.text = self.textView.text;
}

@end

