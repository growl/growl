//
//  GTLevelIndicatorCell.m
//  GrowlTunes
//
//  Created by Travis Tilley on 11/30/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GTLevelIndicator.h"
#import "macros.h"


@implementation GTLevelIndicator

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
    if (self == [GTLevelIndicator class]) {
        NSNumber *logLevel = [[NSUserDefaults standardUserDefaults] objectForKey:
                              [NSString stringWithFormat:@"%@LogLevel", [self class]]];
        if (logLevel)
            ddLogLevel = [logLevel intValue];
    }
}

+(Class)cellClass {
	return [GTLevelIndicatorCell class];
}

@end


@implementation GTLevelIndicatorCell

-(BOOL)isHighlighted
{
    return YES;
}

@end
