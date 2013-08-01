//
//  GrowlIdleStatusObserver.m
//  Growl
//
//  Created by Daniel Siemer on 3/14/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlIdleStatusObserver.h"
#import <Cocoa/Cocoa.h>

//Poll every 30 seconds when the user is active
#define MACHINE_ACTIVE_POLL_INTERVAL	5.0f
//Poll every second when the user is idle
#define MACHINE_IDLE_POLL_INTERVAL		1.0f

static NSTimeInterval currentIdleTime(void) {
	NSTimeInterval idleTime = CGEventSourceSecondsSinceLastEventType(kCGEventSourceStateHIDSystemState, kCGAnyInputEventType);
	return idleTime;
}

@interface GrowlIdleStatusObserver ()

@property (nonatomic) NSTimeInterval idleThreshold;
@property (nonatomic) BOOL useScreensaver;
@property (nonatomic) BOOL useLock;
@property (nonatomic) BOOL useSleep;
@property (nonatomic) BOOL useTime;
@property (nonatomic, retain) NSArray *applicationExceptions;

@property (nonatomic) BOOL screensaverActive;
@property (nonatomic) BOOL screenLocked;
@property (nonatomic) BOOL asleep;
@property (nonatomic) BOOL screenAsleep;
@property (nonatomic) BOOL idleByTime;

@property (nonatomic) NSTimeInterval lastSeenIdle;

@property (nonatomic, retain) NSString *activeApplicationID;

- (void)updateIdleByTime;

@end

@implementation GrowlIdleStatusObserver

@synthesize idleThreshold;
@synthesize useScreensaver;
@synthesize useLock;
@synthesize useSleep;
@synthesize useTime;
@synthesize applicationExceptions;

@synthesize isIdle;
@synthesize screensaverActive;
@synthesize screenLocked;
@synthesize asleep;
@synthesize screenAsleep;
@synthesize idleByTime;

@synthesize lastSeenIdle;

@synthesize activeApplicationID;

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
		self.useSleep = YES;
		
		__block GrowlIdleStatusObserver *blockSelf = self;
		NSDistributedNotificationCenter *nsdnc = [NSDistributedNotificationCenter defaultCenter];
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
								blockSelf.screenLocked = NO;
							}];
		NSNotificationCenter *workspaceNC = [[NSWorkspace sharedWorkspace] notificationCenter];
		[workspaceNC addObserverForName:NSWorkspaceWillSleepNotification
										 object:nil
										  queue:[NSOperationQueue mainQueue]
									usingBlock:^(NSNotification *note) {
										blockSelf.asleep = YES;
									}];
		[workspaceNC addObserverForName:NSWorkspaceDidWakeNotification
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
		
		[workspaceNC addObserverForName:NSWorkspaceDidActivateApplicationNotification 
										 object:nil 
										  queue:[NSOperationQueue mainQueue] 
									usingBlock:^(NSNotification *note) {
										NSString *newID = [[[note userInfo] valueForKey:NSWorkspaceApplicationKey] bundleIdentifier];
										blockSelf.activeApplicationID = newID;
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
		keySet = [[NSSet alloc] initWithObjects:@"activeApplicationID",
					 @"screensaverActive",
					 @"screenLocked",
					 @"screenAsleep",
					 @"asleep", 
					 @"idleByTime",
					 @"idleThreshold",
					 @"useScreensaver",
					 @"useLock",
					 @"useSleep",
					 @"useTime",
					 @"applicationExceptions", nil];
	});
	return keySet;
}

- (void)updateIdleByTime {
	NSTimeInterval currentIdle = currentIdleTime();
	if (idleByTime) {
		/* If the machine is less idle than the last time we recorded, it means
		 * that activity has occured and the user is no longer idle.
		 */
		if (currentIdle < lastSeenIdle && currentIdle < idleThreshold)
			self.idleByTime = NO;
	} else {
		//If machine inactivity is over the threshold, the user has gone idle.
		if (currentIdle > idleThreshold)
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
	
	//Check idle by time, and whether the active app is in the exception to time list
	if(idleByTime && useTime)
		result = YES;
	if([applicationExceptions containsObject:activeApplicationID])
		result = NO;
	
	//Screen settings
	if(screensaverActive && useScreensaver)
		result = YES;
	if(screenLocked && useLock	)
		result = YES;
	if(screenAsleep && (useScreensaver || useLock))
		result = YES;
	if(asleep && useSleep)
		result = YES;
	
	return result;
}

-(NSDate*)lastActive {
	return [NSDate dateWithTimeIntervalSinceNow:-currentIdleTime()];
}

@end
