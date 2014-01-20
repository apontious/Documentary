//
//  TextDocument.m
//  Documentary
//
//  Created by Andrew Pontious on 1/11/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some right reserved: http://opensource.org/licenses/mit-license.php
//

#import "TextDocument.h"

@interface TextDocument () <NSTextViewDelegate>

@property (nonatomic, copy) NSString *text;

@property (nonatomic) IBOutlet NSTextView *textView;

@end

@implementation TextDocument

#pragma mark Standard Methods

- (NSString *)windowNibName {
    return @"TextDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)controller {
    [super windowControllerDidLoadNib:controller];

    self.textView.string = self.text;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    NSData *result = nil;
    
    NSString *contentsString = self.text;
    
    result = [contentsString dataUsingEncoding:NSUTF8StringEncoding];
    
    return result;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    self.text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    // TODO: handle if nil, return error
    
    return YES;
}

+ (BOOL)autosavesInPlace {
    // Per docs: "For your app to participate with iCloud, you must enable Auto Save."
    return YES;
}

#pragma mark NSTextViewDelegate Methods

- (void)textDidChange:(NSNotification *)notification {
    // In a real app, we would only register a change after a certain amount of typing, or after a certain time. But not for this sample app.
    
    [[self.undoManager prepareWithInvocationTarget:self] setText:self.text];
    [self.undoManager setActionName:NSLocalizedString(@"Typing", @"Undo/redo label")];

    self.text = self.textView.string;
}

@end
