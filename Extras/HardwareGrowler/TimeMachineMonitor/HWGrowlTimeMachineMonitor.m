//
//  HWGrowlTimeMachineMonitor.m
//  HardwareGrowler
//
//  Created by Daniel Siemer on 5/19/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "HWGrowlTimeMachineMonitor.h"
#include <asl.h>

@interface HWGrowlTimeMachineMonitor ()

@property (nonatomic, assign) id<HWGrowlPluginControllerProtocol> delegate;

@property (nonatomic, assign) dispatch_queue_t tmQueue;
@property (nonatomic, retain) NSTimer *pollTimer;
@property (nonatomic, retain) NSDate *lastSearchTime, *lastStartTime, *lastEndTime;
@property (nonatomic, assign) BOOL postGrowlNotifications;
@property (nonatomic, assign) BOOL parsing;

@end

@implementation HWGrowlTimeMachineMonitor

@synthesize delegate;

@synthesize tmQueue;
@synthesize pollTimer;
@synthesize lastStartTime;
@synthesize lastSearchTime;
@synthesize lastEndTime;
@synthesize postGrowlNotifications;
@synthesize parsing;

-(id)init {
	if((self = [super init])){
		parsing = NO;
		
		self.tmQueue = dispatch_queue_create("com.growl.HardwareGrowler.tmmonitorqueue", DISPATCH_QUEUE_SERIAL);
	}
	return self;
}

-(void)dealloc {
	dispatch_release(tmQueue);
	[pollTimer invalidate];
	[pollTimer release];
	[lastStartTime release];
	[lastSearchTime release];
	[lastEndTime release];
	[super dealloc];
}

-(void)postRegistrationInit {
	[self startMonitoringTheLogs];
}

-(NSData*)timeMachineIcon {
	static NSData *data = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString *path = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"Time Machine"];
		NSImage *appIcon = path ? [[NSWorkspace sharedWorkspace] iconForFile:path] : nil;
		data = [[appIcon TIFFRepresentation] retain];
	});
	return data;
}

- (void) startMonitoringTheLogs {
	self.pollTimer = [NSTimer scheduledTimerWithTimeInterval:10.0
																	  target:self
																	selector:@selector(pollLogDatabase:)
																	userInfo:nil
																	 repeats:YES];
   [[NSRunLoop mainRunLoop] addTimer:pollTimer forMode:NSRunLoopCommonModes];
   [self pollLogDatabase:pollTimer];
}
- (void) stopMonitoringTheLogs {
	[pollTimer invalidate];
	self.pollTimer = nil;
}

- (NSDate *) dateFromASLMessage:(aslmsg)msg {
	NSTimeInterval unixTime = strtod(asl_get(msg, ASL_KEY_TIME), NULL);
	const char *nanosecondsUTF8 = asl_get(msg, ASL_KEY_TIME_NSEC);
	if (nanosecondsUTF8) {
		NSTimeInterval unixTimeNanoseconds = strtod(nanosecondsUTF8, NULL);
		unixTime += (unixTimeNanoseconds / 1.0e9);
	}
	return [NSDate dateWithTimeIntervalSince1970:unixTime];
}

- (NSString *) stringWithTimeInterval:(NSTimeInterval)units {
	NSString *unitNames[] = {
		NSLocalizedString(@"seconds", /*comment*/ @"Unit names"),
		NSLocalizedString(@"minutes", /*comment*/ @"Unit names"),
		NSLocalizedString(@"hours", /*comment*/ @"Unit names")
	};
	NSUInteger unitNameIndex = 0UL;
	if (units >= 60.0) {
		units /= 60.0;
		++unitNameIndex;
	}
	if (units >= 60.0) {
		units /= 60.0;
		++unitNameIndex;
	}
	return [NSString localizedStringWithFormat:@"%.03f %@", units, unitNames[unitNameIndex]];
}

- (void) postBackupStartedNotification {
   __block HWGrowlTimeMachineMonitor *blockSelf = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		NSString *description = nil;
		if(blockSelf.lastEndTime)
			description = [NSString stringWithFormat:NSLocalizedString(@"%@ since last back-up", @""), [blockSelf stringWithTimeInterval:[blockSelf.lastStartTime timeIntervalSinceDate:blockSelf.lastEndTime]]];
		else
			description = NSLocalizedString(@"First backup, or no previous backup found in the system log", @"");
		[blockSelf.delegate notifyWithName:@"TimeMachineStart"
                                   title:NSLocalizedString(@"Time Machine started", @"") 
                             description:description
                                    icon:[blockSelf timeMachineIcon]
                        identifierString:@"HWGTimeMachineMonitor"
                           contextString:nil
                                  plugin:blockSelf];
	});
}

- (void) pollLogDatabase:(NSTimer *)timer {
	//We really shouldn't pile parse upon parse
	if(!parsing){
      __block HWGrowlTimeMachineMonitor *blockSelf = self;
		dispatch_async(tmQueue, ^{
			[blockSelf parseLogDatabase];
		});
	}else {
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			NSLog(@"WARNING: The Time Machine Montior relies on parsing the console log, and it is taking too long to parse due to high volume of messages, you may see high CPU usage as a result");
		});
	}
}

- (void) parseLogDatabase {
	__block HWGrowlTimeMachineMonitor *blockSelf = self;
	
	aslmsg query = asl_new(ASL_TYPE_QUERY);
	const char *backupd_sender = "com.apple.backupd";
	asl_set_query(query, ASL_KEY_SENDER, backupd_sender, ASL_QUERY_OP_EQUAL);
	if (lastSearchTime) {
		char *lastSearchTimeUTF8 = NULL;
		asprintf(&lastSearchTimeUTF8, "%lu", (unsigned long)[lastSearchTime timeIntervalSince1970]);
		if(lastSearchTimeUTF8 != NULL){
			asl_set_query(query, ASL_KEY_TIME, lastSearchTimeUTF8, ASL_QUERY_OP_GREATER);
			free(lastSearchTimeUTF8);
		}
	}
	aslresponse response = asl_search(NULL, query);
	
	BOOL lastWasCanceled = NO;
	
	NSUInteger numFoundMessages = 0UL;
	NSDate *lastFoundMessageDate = nil;
	
	aslmsg msg;
	while ((msg = aslresponse_next(response))) {
		++numFoundMessages;
		lastFoundMessageDate = [self dateFromASLMessage:msg];
		
		const char *msgUTF8 = asl_get(msg, ASL_KEY_MSG);
		NSString *message = [NSString stringWithUTF8String:msgUTF8];
		if ([message compare:@"Starting standard backup"] == NSOrderedSame) {
			self.lastStartTime = lastFoundMessageDate;
			lastWasCanceled = NO;
			
			if (postGrowlNotifications) {
				[self postBackupStartedNotification];
			}
			
		} else if (strcmp(msgUTF8, "Backup completed successfully.") == NSOrderedSame) {
			self.lastEndTime = lastFoundMessageDate;
			lastWasCanceled = NO;
			
			if (postGrowlNotifications) {
				dispatch_async(dispatch_get_main_queue(), ^{
					NSString *timeString = [blockSelf stringWithTimeInterval:[blockSelf.lastEndTime timeIntervalSinceDate:blockSelf.lastStartTime]];
					[blockSelf.delegate notifyWithName:@"TimeMachineFinish"
														  title:NSLocalizedString(@"Time Machine finished", @"")
												  description:[NSString stringWithFormat:NSLocalizedString(@"Back-up took %@", @""), timeString]
															icon:[blockSelf timeMachineIcon]
											identifierString:@"HWGTimeMachineMonitor"
												contextString:nil
														 plugin:blockSelf];
				});
			}
			
		} 
		else if ([message compare:@"Backup canceled."] == NSOrderedSame || 
					[message compare:@"Backup failed"] == NSOrderedSame) 
		{
			NSDate *date = lastFoundMessageDate;
			lastWasCanceled = YES;
			BOOL wasFailure = ([message compare:@"Backup failed"] == NSOrderedSame);
			
			if (postGrowlNotifications) {
				dispatch_async(dispatch_get_main_queue(), ^{
					NSString *description = nil;
					NSString *timeString = [blockSelf stringWithTimeInterval:[date timeIntervalSinceDate:blockSelf.lastStartTime]];
					if(wasFailure)
						description = [NSString stringWithFormat:NSLocalizedString(@"Failed after %@", @""), timeString];
					else
						description = [NSString stringWithFormat:NSLocalizedString(@"Canceled after %@", @""), timeString];
					[blockSelf.delegate notifyWithName:wasFailure ? @"TimeMachineFailed" : @"TimeMachineCanceled"
														  title:wasFailure ? NSLocalizedString(@"Time Machine Failed", @"") : NSLocalizedString(@"Time Machine Canceled", @"")
												  description:description
															icon:[blockSelf timeMachineIcon]
											identifierString:@"HWGTimeMachineMonitor"
												contextString:nil
														 plugin:blockSelf];
				});
			}
		} 
	}
	aslresponse_free(response);
	asl_free(query);
	
	//If a Time Machine back-up is running now, post the notification even if we are on our first run.
	if ((!postGrowlNotifications) && (!lastWasCanceled) && ((!lastEndTime) || ([lastStartTime compare:lastEndTime] == NSOrderedDescending))) {
		[self postBackupStartedNotification];
	}
	
	if (numFoundMessages > 0) {
		self.lastSearchTime = lastFoundMessageDate;
	}
	postGrowlNotifications = YES;
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[blockSelf setParsing:NO]; 
	});
}

#pragma mark HWGrowlPluginProtocol

-(void)setDelegate:(id<HWGrowlPluginControllerProtocol>)aDelegate{
	delegate = aDelegate;
}
-(id<HWGrowlPluginControllerProtocol>)delegate {
	return delegate;
}
-(NSString*)pluginDisplayName {
	return NSLocalizedString(@"TimeMachine Monitor", @"");
}
-(NSView*)preferencePane {
	return nil;
}

#pragma mark HWGrowlPluginNotifierProtocol

-(NSArray*)noteNames {
	return [NSArray arrayWithObjects:@"TimeMachineStart", @"TimeMachineFinish", @"TimeMachineCanceled", @"TimeMachineFailed", nil];
}
-(NSDictionary*)localizedNames {
	return [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Time Machine Started", @""), @"TimeMachineStart",
			  NSLocalizedString(@"Time Machine Finished", @""), @"TimeMachineFinish",
			  NSLocalizedString(@"Time Machine Canceled", @""), @"TimeMachineCanceled",
			  NSLocalizedString(@"Time Machine Failed", @""), @"TimeMachineFailed", nil];
}
-(NSDictionary*)noteDescriptions {
	return [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Sent when Time Machine starts backing up", @""), @"TimeMachineStart",
			  NSLocalizedString(@"Sent when Time Machine finishes backing up", @""), @"TimeMachineFinish",
			  NSLocalizedString(@"Sent when Time Machine is canceled", @""), @"TimeMachineCanceled",
			  NSLocalizedString(@"Sent when Time Machine failed to back up", @""), @"TimeMachineFailed", nil];
}
-(NSArray*)defaultNotifications {
	return [NSArray arrayWithObjects:@"TimeMachineStart", @"TimeMachineFinish", @"TimeMachineCanceled", @"TimeMachineFailed", nil];
}

@end
