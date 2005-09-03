//
//  SyncNotifier.m
//  HardwareGrowler
//
//  Created by Ingmar Stein on 03.09.05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "SyncNotifier.h"


@implementation SyncNotifier
- (id) initWithDelegate:(id)object {
	if ((self = [super init])) {
		delegate = object;
		NSDistributedNotificationCenter *nsdnc = [NSDistributedNotificationCenter defaultCenter];
		[nsdnc addObserver:self
				  selector:@selector(syncStarted:)
					  name:@"com.apple.syncservices.ISyncPlanChangedNotification"
					object:@"ISyncPlanCreated"];
		[nsdnc addObserver:self
				  selector:@selector(syncFinished:)
					  name:@"com.apple.syncservices.ISyncPlanChangedNotification"
					object:@"ISyncPlanEnded"];
	}

	return self;
}

- (void) syncStarted:(NSNotification *)notification {
	[delegate syncStarted];
}

- (void) syncFinished:(NSNotification *)notification {
	NSString *status = [[notification userInfo] objectForKey:@"ISyncPlanStatus"];
	if ([status isEqualToString:@"Finished"])
		[delegate syncFinished];
	// else if ([status isEqualToString:@"Cancelled"])
}

- (void) dealloc {
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self
															   name:nil
															 object:nil];
	[super dealloc];
}

@end
