//
//  TrackRatingLevelIndicatorValueTransformer.m
//  GrowlTunes
//
//  Created by Travis Tilley on 11/30/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "TrackRatingLevelIndicatorValueTransformer.h"

@implementation TrackRatingLevelIndicatorValueTransformer

+ (Class)transformedValueClass
{
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(id)value
{
    float transformedValue = [value floatValue] / 20.f;
    return [NSNumber numberWithFloat:transformedValue];
}

- (id)reverseTransformedValue:(id)value
{
    float transformedValue = [value floatValue] * 20.f;
    return [NSNumber numberWithFloat:transformedValue];
}

@end
