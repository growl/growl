//
//  GrowlController.m
//  Capster
//
//  Created by Vasileios Georgitzikis on 9/3/11.
//  Copyright 2011 Tzikis. All rights reserved.
//

#import "GrowlController.h"

#define startingTitle @"Starting"
#define capsOnTitle @"Caps On"
#define capsOffTitle @"Caps Off"
#define numlockOnTitle @"Num Lock On"
#define numlockOffTitle @"Num Lock Off"
#define fnOnTitle @"Function Key Pressed"
#define fnOffTitle @"Function Key Pressed"

#define CapsterTitle	NSLocalizedString(@"Capster", nil)
#define StartingDescription 	NSLocalizedString(@"Starting", nil)
#define capsOnDescription 	NSLocalizedString(@"Caps Lock on", nil)
#define capsOffDescription 	NSLocalizedString(@"Caps Lock off", nil)
#define numlockOnDescription 	NSLocalizedString(@"Num Lock on", nil)
#define numlockOffDescription 	NSLocalizedString(@"Num Lock off", nil)
#define fnOnDescription 	NSLocalizedString(@"Function key on", nil)
#define fnOffDescription 	NSLocalizedString(@"Function key off", nil)



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
	[GrowlApplicationBridge notifyWithTitle: CapsterTitle
								description: StartingDescription
						   notificationName: startingTitle
								   iconData: ter
								   priority: 0
								   isSticky: NO
							   clickContext:nil];	
}

- (void) sendNotification:(NSUInteger) newState forFlag: (NSString*) type;
{
#define CHECK_FLAG(NAME)\
if([type isEqualToString:@"" #NAME])\
	{\
	NSString* NAME ## _path_on = [[NSBundle mainBundle] pathForResource:@"" #NAME "_on" ofType:@"png"];\
	NSString* NAME ## _path_off = [[NSBundle mainBundle] pathForResource:@"" #NAME "_off" ofType:@"png"];\
	\
	/*Initialize the images for capslock on and off*/\
	NSData* on = [NSData dataWithContentsOfFile:NAME ## _path_on];\
	NSData* off = [NSData dataWithContentsOfFile:NAME ## _path_off];\
	\
	/*prepare the stuff for the growl notification*/\
	NSString* descriptions[] = {NAME ## OffDescription, NAME ## OnDescription};\
	NSString* names[] = {NAME ## OffTitle, NAME ## OnTitle};\
	NSData* data[] = {off, on};\
	\
	/*send the apropriate growl notification*/\
	[GrowlApplicationBridge notifyWithTitle: @"Capster"\
								description: descriptions[newState]\
						   notificationName: names[newState]\
								   iconData: data[newState]\
								   priority: 0\
								   isSticky: NO\
							   clickContext:nil\
								 identifier:@"status changed"];\
	}
	
	CHECK_FLAG(caps)
	CHECK_FLAG(numlock)
	CHECK_FLAG(fn)
}

@end
