//
//  TrackRatingLevelIndicatorValueTransformer.m
//  GrowlTunes
//
//  Created by Travis Tilley on 11/30/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "TrackRatingLevelIndicatorValueTransformer.h"

@implementation TrackRatingLevelIndicatorValueTransformer

static int ddLogLevel = DDNS_LOG_LEVEL_DEFAULT;

+ (int)ddLogLevel
{
    return ddLogLevel;
}

+ (void)ddSetLogLevel:(int)logLevel
{
    ddLogLevel = logLevel;
}

+ (void)initialize
{
    if (self == [TrackRatingLevelIndicatorValueTransformer class]) {
        NSNumber *logLevel = [[NSUserDefaults standardUserDefaults] objectForKey:
                              [NSString stringWithFormat:@"%@LogLevel", [self class]]];
        if (logLevel)
            ddLogLevel = [logLevel intValue];
    }
}

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
