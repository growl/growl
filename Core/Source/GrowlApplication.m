//
//  GrowlApplication.m
//  Growl
//
//  Created by Evan Schoenberg on 5/10/07.
//

#import "GrowlApplication.h"

@implementation GrowlApplication

- (void)resetAutoreleasePool:(NSTimer *)timer
{
	[NSApp postEvent:[NSEvent otherEventWithType:NSApplicationDefined
										location:NSZeroPoint
								   modifierFlags:0
									   timestamp: (double)(AbsoluteToDuration(UpTime())) / 1000.0
									windowNumber:0
										 context:NULL
										 subtype:0
										   data1:0 
										   data2:0]
			 atStart:YES];
}

- (void)run
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	autoreleasePoolRefreshTimer = [[NSTimer scheduledTimerWithTimeInterval:30
									  target:self
									selector:@selector(resetAutoreleasePool:)
									userInfo:nil
									 repeats:YES] retain];
	[pool release];

	[super run];

	[autoreleasePoolRefreshTimer invalidate];
	[autoreleasePoolRefreshTimer release];
	autoreleasePoolRefreshTimer = nil;
}

- (BOOL)paused
{
    return [[GrowlPreferencesController sharedController] squelchMode];
}

@end
