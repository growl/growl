//
//  HWGrowlNetworkMonitor.m
//  HardwareGrowler
//
//  Created by Daniel Siemer on 5/2/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "HWGrowlNetworkMonitor.h"

@interface HWGrowlNetworkMonitor ()

@property (nonatomic, assign) id<HWGrowlPluginControllerProtocol> delegate;

@end

@implementation HWGrowlNetworkMonitor

@synthesize delegate;

-(id)init {
	if((self = [super init])){
		NSLog(@"Loaded HWGrowlNetworkMonitor!");
	}
	return self;
}

-(void)setDelegate:(id<HWGrowlPluginControllerProtocol>)aDelegate{
	delegate = aDelegate;
}
-(id<HWGrowlPluginControllerProtocol>)delegate {
	return delegate;
}

-(id)preferencePane {
	return nil;
}
-(NSArray*)noteNames {
	return nil;
}
-(NSDictionary*)localizedNames {
	return nil;
}
-(NSDictionary*)noteDescriptions {
	return nil;
}
-(NSArray*)defaultNotifications {
	return nil;
}

@end
