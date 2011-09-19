//
//  GrowlController.m
//  Capster
//
//  Created by Vasileios Georgitzikis on 9/3/11.
//  Copyright 2011 Tzikis. All rights reserved.
//

#import "GrowlController.h"


@implementation GrowlController

- (id)init
{
    self = [super init];
    if (self)
	{
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

//let the user know we're live
- (void) sendStartupGrowlNotification
{
	//initialize the image needed for the growl notification
	NSString* path_ter = [[NSBundle mainBundle] pathForResource:@"caps_ter" ofType:@"png"];
	NSData* ter = [NSData dataWithContentsOfFile:path_ter];
	
	
	[GrowlApplicationBridge setGrowlDelegate:self];
	[GrowlApplicationBridge notifyWithTitle: @"Capster"
								description: @"Starting"
						   notificationName: @"starting"
								   iconData: ter
								   priority: 0
								   isSticky: NO
							   clickContext:nil];	
}

- (void) sendCapsLockNotification:(NSUInteger) newState
{
	//Initialize the images for capslock on and off
	NSString* path_on = [[NSBundle mainBundle] pathForResource:@"caps_on" ofType:@"png"];
	NSString* path_off = [[NSBundle mainBundle] pathForResource:@"caps_off" ofType:@"png"];
	NSData* on = [NSData dataWithContentsOfFile:path_on];
	NSData* off = [NSData dataWithContentsOfFile:path_off];
	
	//prepare the stuff for the growl notification		
	NSString* descriptions[] = {@"Caps Lock off", @"Caps Lock on"};
	NSString* names[] = {@"caps off", @"caps on"};
	NSData* data[] = {off, on};
	
	//send the apropriate growl notification
	[GrowlApplicationBridge notifyWithTitle: @"Capster"
								description: descriptions[newState]
						   notificationName: names[newState]
								   iconData: data[newState]
								   priority: 0
								   isSticky: NO
							   clickContext:nil
								 identifier:@"status changed"];
}

@end
