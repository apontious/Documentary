//
//  TextDocument.m
//  Documentary
//
//  Created by Andrew Pontious on 1/5/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some right reserved: http://opensource.org/licenses/mit-license.php
//

#import "TextDocument.h"

@implementation TextDocument

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    NSData *result = nil;
    
    NSString *contentsString = self.text;
    
    result = [contentsString dataUsingEncoding:NSUTF8StringEncoding];
    
    return result;
}

- (BOOL)loadFromContents:(NSData *)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    BOOL result = YES;

    self.text = [[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding];
    
    // TODO: handle if nil, return error
    
    return result;
}

@end
