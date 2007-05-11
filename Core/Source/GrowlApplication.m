//
//  GrowlApplication.m
//  Growl
//
//  Created by Evan Schoenberg on 5/10/07.
//

#import "GrowlApplication.h"

@implementation GrowlApplication
static NSAutoreleasePool *globalPool = nil;
- (void)resetAutoreleasePool:(NSTimer *)timer
{
#pragma unused (timer)
	[globalPool release];
	globalPool = [[NSAutoreleasePool alloc] init];
}

- (void)run
{
	globalPool = [[NSAutoreleasePool alloc] init];
	[[NSTimer scheduledTimerWithTimeInterval:30
									  target:self
									selector:@selector(resetAutoreleasePool:)
									userInfo:nil
									 repeats:YES] retain];
	[super run];
	[globalPool release]; globalPool = nil;
}

@end
