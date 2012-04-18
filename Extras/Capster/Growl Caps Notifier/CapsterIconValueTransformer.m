//
//  CapsterIconValueTransformer.m
//  Capster
//
//  Created by Vasileios Georgitzikis on 6/12/11.
//  Copyright (c) 2011 Tzikis. All rights reserved.
//

#import "CapsterIconValueTransformer.h"
#import "CommonTitles.h"

enum { kDontShowIcon = 0, kShowBlackIcons, kShowColorIcons };

@implementation CapsterIconValueTransformer
- (id)transformedValue:(id)value
{
    NSString *result = nil;
    NSNumber *number = (NSNumber*)value;
    NSInteger index = [number integerValue];
    switch (index) {
        case kDontShowIcon: 
            result = NoneTitle;            
            break;
        case kShowBlackIcons:
            result = BlackIcons;            
            break;
        case kShowColorIcons:
        default:
            result = ColorIcons;            
            break;
    }
    return result;
}

- (id)reverseTransformedValue:(id)value
{
    NSNumber *result = nil;
    NSString *textual = (NSString*)value;
    if([textual isEqualToString:ColorIcons])
        result = [NSNumber numberWithInteger:kShowColorIcons];
    else if([textual isEqualToString:BlackIcons])
        result = [NSNumber numberWithInteger:kShowBlackIcons];
    else if([textual isEqualToString:NoneTitle])
        result = [NSNumber numberWithInteger:kDontShowIcon];
    return result;
}

@end
