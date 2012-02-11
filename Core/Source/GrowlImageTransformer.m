//
//  GrowlImageTransformer.m
//  Growl
//
//  Created by Rudy Richter on 2/11/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlImageTransformer.h"

@implementation GrowlImageTransformer

+ (Class)transformedValueClass
{
    return [NSImage self];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)beforeObject
{
    NSImage *result = nil;
    if (beforeObject) 
    {
        NSData *beforeData = (NSData*)beforeObject;
        result = [[[NSImage alloc] initWithData:beforeData] autorelease];
    }
    return result;
}

@end
