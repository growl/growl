//
//  HGIconValueTransformer.m
//  HardwareGrowler
//
//  Created by Rudy Richter on 10/18/11.
//  Copyright 2011 The Growl Project, LLC. All rights reserved.
//

#import "HGIconValueTransformer.h"
#import "HGCommon.h"

@implementation HGIconValueTransformer

- (id)transformedValue:(id)value
{
    NSString *result = nil;
    NSNumber *number = (NSNumber*)value;
    NSInteger index = [number integerValue];
    switch (index) {
        case kDontShowIcon: 
            result = noIcon;            
            break;
        case kShowIconInBoth:
            result = iconInBoth;            
            break;
        case kShowIconInDock:
            result = iconInDock;            
            break;
        case kShowIconInMenu:
        default:
            result = iconInMenu;            
            break;
    }
    return result;
}

- (id)reverseTransformedValue:(id)value
{
    NSNumber *result = nil;
    NSString *textual = (NSString*)value;
    if([textual isEqualToString:iconInMenu])
        result = [NSNumber numberWithInteger:kShowIconInMenu];
    else if([textual isEqualToString:iconInDock])
        result = [NSNumber numberWithInteger:kShowIconInDock];
    else if([textual isEqualToString:iconInBoth])
        result = [NSNumber numberWithInteger:kShowIconInBoth];
    else if([textual isEqualToString:noIcon])
        result = [NSNumber numberWithInteger:kDontShowIcon];
    return result;
}
@end
