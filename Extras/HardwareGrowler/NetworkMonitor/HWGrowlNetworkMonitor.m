//
//  HWGrowlNetworkMonitor.m
//  HardwareGrowler
//
//  Created by Daniel Siemer on 5/2/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "HWGrowlNetworkMonitor.h"
#import "GrowlNetworkObserver.h"

@interface HWGrowlNetworkMonitor ()

@property (nonatomic, assign) id<HWGrowlPluginControllerProtocol> delegate;

@end

@implementation HWGrowlNetworkMonitor

@synthesize delegate;

-(id)init {
	if((self = [super init])){
		[[GrowlNetworkObserver sharedObserver] startObserving];
		[[NSNotificationCenter defaultCenter] addObserver:self 
															  selector:@selector(updateIP:) 
																	name:IPAddressesUpdateNotification 
																 object:nil];
	}
	return self;
}

-(void)updateIP:(NSNotification*)note {
	[delegate notifyWithName:@"IPAddressChange"
							 title:@"Changed IP!"
					 description:[[GrowlNetworkObserver sharedObserver] routableCombined] ? [[GrowlNetworkObserver sharedObserver] routableCombined] : @"NO IP"
							  icon:nil
			  identifierString:@"HWGrowlIPAddressChange"
				  contextString:[[GrowlNetworkObserver sharedObserver] primaryIP] ? [[GrowlNetworkObserver sharedObserver] primaryIP] : @"NO IP"
							plugin:self];

}

#pragma mark HWGrowlPluginProtocol

-(void)setDelegate:(id<HWGrowlPluginControllerProtocol>)aDelegate{
	delegate = aDelegate;
}
-(id<HWGrowlPluginControllerProtocol>)delegate {
	return delegate;
}
-(NSString*)pluginDisplayName {
	return @"Network Monitor";
}
-(NSView*)preferencePane {
	return nil;
}

#pragma mark HWGrowlPluginNotifierProtocol

-(NSArray*)noteNames {
	return [NSArray arrayWithObject:@"IPAddressChange"];
}
-(NSDictionary*)localizedNames {
	return [NSDictionary dictionaryWithObject:@"IP Address Changed" forKey:@"IPAddressChange"];
}
-(NSDictionary*)noteDescriptions {
	return [NSDictionary dictionaryWithObject:@"Sent when the systems IP address changes" forKey:@"IPAddressChange"];
}
-(NSArray*)defaultNotifications {
	return [NSArray arrayWithObject:@"IPAddressChange"];
}

-(void)noteClosed:(NSString*)contextString byClick:(BOOL)clicked {
	NSLog(@"testing! %@ was %@", contextString, clicked ? @"clicked" : @"timed out/closed");
}

@end
