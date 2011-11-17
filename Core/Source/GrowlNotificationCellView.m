//
//  GrowlNotificationCellView.m
//  Growl
//
//  Created by Daniel Siemer on 7/8/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlNotificationCellView.h"
#import "GrowlHistoryNotification.h"

@implementation GrowlNotificationCellView

@synthesize description;
@synthesize icon;
@synthesize deleteButton;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)setObjectValue:(id)newValue
{
    if([newValue isKindOfClass:[GrowlHistoryNotification class]])
        [super setObjectValue:newValue];
    else
        [super setObjectValue:nil];

    [icon setImage:[[self objectValue] valueForKeyPath:@"Image.Image"]];
}

@end
