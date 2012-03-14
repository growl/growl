//
//  GrowlIdleStatusObserver.m
//  Growl
//
//  Created by Daniel Siemer on 3/14/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlIdleStatusObserver.h"
#import "GrowlPreferencesController.h"

//Poll every 30 seconds when the user is active
#define MACHINE_ACTIVE_POLL_INTERVAL	5.0f
//Poll every second when the user is idle
#define MACHINE_IDLE_POLL_INTERVAL		1.0f

static NSTimeInterval currentIdleTime(void) {
	NSTimeInterval idleTime = CGEventSourceSecondsSinceLastEventType(kCGEventSourceStateHIDSystemState, kCGAnyInputEventType);
	return idleTime;
}

@interface GrowlIdleStatusObserver ()

@property (nonatomic) BOOL screensaverActive;
@property (nonatomic) BOOL screenLocked;
@property (nonatomic) BOOL asleep;
@property (nonatomic) BOOL screenAsleep;
@property (nonatomic) BOOL idleByTime;

@property (nonatomic) NSTimeInterval lastSeenIdle;

- (void)updateIdleByTime;

@end

@implementation GrowlIdleStatusObserver

@synthesize isIdle;
@synthesize screensaverActive;
@synthesize screenLocked;
@synthesize asleep;
@synthesize screenAsleep;
@synthesize idleByTime;

@synthesize lastSeenIdle;

+ (GrowlIdleStatusObserver*)sharedObserver {
   static GrowlIdleStatusObserver *instance;
   static dispatch_once_t onceToken;
   dispatch_once(&onceToken, ^{
      instance = [[self alloc] init];
   });
   return instance;
}

- (id)init
{
	if((self = [super init])){
		__block GrowlIdleStatusObserver *blockSelf = self;
		NSDistributedNotificationCenter *nsdnc = [NSNotificationCenter defaultCenter];
		[nsdnc addObserverForName:@"com.apple.screensaver.didstart"
								 object:nil
								  queue:[NSOperationQueue mainQueue]
							usingBlock:^(NSNotification *note) {
								blockSelf.screensaverActive = YES;
							}];
		[nsdnc addObserverForName:@"com.apple.screensaver.didstop"
								 object:nil
								  queue:[NSOperationQueue mainQueue]
							usingBlock:^(NSNotification *note) {
								blockSelf.screensaverActive = NO;
							}];
		[nsdnc addObserverForName:@"com.apple.screenIsLocked"
								 object:nil
								  queue:[NSOperationQueue mainQueue]
							usingBlock:^(NSNotification *note) {
								blockSelf.screenLocked = YES;
							}];
		[nsdnc addObserverForName:@"com.apple.screenIsUnlocked"
								 object:nil
								  queue:[NSOperationQueue mainQueue]
							usingBlock:^(NSNotification *note) {
								blockSelf.screenLocked = YES;
							}];
		NSNotificationCenter *workspaceNC = [[NSWorkspace sharedWorkspace] notificationCenter];
		[workspaceNC addObserverForName:NSWorkspaceWillSleepNotification
										 object:nil
										  queue:[NSOperationQueue mainQueue]
									usingBlock:^(NSNotification *note) {
										blockSelf.asleep = NO;
									}];
		[workspaceNC addObserverForName:NSWorkspaceWillSleepNotification
										 object:nil
										  queue:[NSOperationQueue mainQueue]
									usingBlock:^(NSNotification *note) {
										blockSelf.asleep = NO;
									}];
		[workspaceNC addObserverForName:NSWorkspaceScreensDidSleepNotification
										 object:nil
										  queue:[NSOperationQueue mainQueue]
									usingBlock:^(NSNotification *note) {
										blockSelf.screenAsleep = YES;
									}];
		[workspaceNC addObserverForName:NSWorkspaceScreensDidWakeNotification
										 object:nil
										  queue:[NSOperationQueue mainQueue]
									usingBlock:^(NSNotification *note) {
										blockSelf.screenAsleep = NO;
									}];
		double delayInSeconds = MACHINE_ACTIVE_POLL_INTERVAL;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			[blockSelf updateIdleByTime];
		});
	}
	return self;
}

- (void)dealloc
{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[super dealloc];
}

+ (NSSet*)keyPathsForValuesAffectingIsIdle {
	static NSSet *keySet = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		keySet = [[NSSet alloc] initWithObjects:@"screensaverActive", @"screenLocked", @"screenAsleep", @"asleep", @"idleByTime", nil];
	});
	return keySet;
}

- (void)updateIdleByTime {
	NSTimeInterval currentIdle = currentIdleTime();
	NSTimeInterval threshold = [self idleThreshold];
	if (idleByTime) {
		/* If the machine is less idle than the last time we recorded, it means
		 * that activity has occured and the user is no longer idle.
		 */
		if (currentIdle < lastSeenIdle && currentIdle < threshold)
			self.idleByTime = NO;
	} else {
		//If machine inactivity is over the threshold, the user has gone idle.
		if (currentIdle > threshold)
			self.idleByTime = YES;
	}
		
	self.lastSeenIdle = currentIdle;
	
	NSTimeInterval nextFireTime = MACHINE_ACTIVE_POLL_INTERVAL;
	if(idleByTime)
		nextFireTime = MACHINE_IDLE_POLL_INTERVAL;
	__block GrowlIdleStatusObserver *blockSelf = self;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, nextFireTime * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[blockSelf updateIdleByTime];
	});
}

-(BOOL)isIdle {
	BOOL result = NO;
	
	//Check each of these against appropriate preference settings
	if(idleByTime)
		result = YES;
	if(screenAsleep)
		result = YES;
	if(asleep)
		result = YES;
	if(screenLocked)
		result = YES;
	
	return result;
}

-(NSTimeInterval)idleThreshold {
	return [[[GrowlPreferencesController sharedController] idleThreshold] doubleValue];
}

-(NSDate*)lastActive {
	return [NSDate dateWithTimeIntervalSinceNow:-currentIdleTime()];
}

@end
