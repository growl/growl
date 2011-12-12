//
//  GTLevelIndicatorCell.m
//  GrowlTunes
//
//  Created by Travis Tilley on 11/30/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GTLevelIndicator.h"


@implementation GTLevelIndicator

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
