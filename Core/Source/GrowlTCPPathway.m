//
//  GrowlTCPPathway.m
//  Growl
//
//  Created by Peter Hosey on 2006-02-13.
//  Copyright 2006 The Growl Project. All rights reserved.
//

#import "GrowlTCPPathway.h"
#import "GNTPServer.h"
#import "GrowlNotification.h"
#import "GrowlNetworkUtilities.h"
#import "GNTPSubscriptionController.h"
#import "GrowlDefines.h"

@interface GrowlTCPPathway ()
@property (nonatomic, retain) GNTPServer *localServer;
@property (nonatomic, retain) GNTPServer *remoteServer;
@property (nonatomic, retain) NSNetService *netService;
@end

@implementation GrowlTCPPathway

@synthesize localServer = _localServer;
@synthesize remoteServer = _remoteServer;
@synthesize netService = _netService;

- (id)init
{
	if ((self = [super init])) {
		self.localServer = [[[GNTPServer alloc] initWithInterface:@"localhost"] autorelease];
		self.localServer.delegate = (id<GNTPServerDelegate>)self;
		[self.localServer startServer];
		
		self.remoteServer = [[[GNTPServer alloc] initWithInterface:nil] autorelease];
		self.remoteServer.delegate = (id<GNTPServerDelegate>)self;
		
		[[NSNotificationCenter defaultCenter] addObserverForName:GROWL_NOTIFICATION_CLICKED
																		  object:nil
																			queue:[NSOperationQueue mainQueue]
																	 usingBlock:^(NSNotification *note) {
																		 GrowlNotification *growlNote = [note object];
																		 NSDictionary *growlDict = [growlNote dictionaryRepresentation];
																		 [self.localServer notificationClicked:growlDict];
																		 [self.remoteServer notificationClicked:growlDict];
																	 }];
		[[NSNotificationCenter defaultCenter] addObserverForName:GROWL_NOTIFICATION_TIMED_OUT
																		  object:nil
																			queue:[NSOperationQueue mainQueue]
																	 usingBlock:^(NSNotification *note) {
																		 GrowlNotification *growlNote = [note object];
																		 NSDictionary *growlDict = [growlNote dictionaryRepresentation];
																		 [self.localServer notificationTimedOut:growlDict];
																		 [self.remoteServer notificationTimedOut:growlDict];
																	 }];
		
		void(^noteBlock)(NSNotification*) = ^(NSNotification *note) {
			if(![note object] || [[note object] isEqualToString:GrowlStartServerKey] ||
				[[note object] isEqualToString:GrowlSubscriptionEnabledKey])
			{
				if([[GrowlPreferencesController sharedController] isGrowlServerEnabled] ||
					[[GrowlPreferencesController sharedController] isSubscriptionAllowed])
				{
					if([self.remoteServer startServer]){
						[self publish];
					}
				}else{
					[self.remoteServer stopServer];
					[self unpublish];
				}
			}
		};
		[[NSNotificationCenter defaultCenter] addObserverForName:GrowlPreferencesChanged
																		  object:nil
																			queue:[NSOperationQueue mainQueue]
																	 usingBlock:noteBlock];
		noteBlock(nil);
	}
		
	return self;
}

- (void)dealloc
{
	[self.localServer stopServer];
	self.localServer = nil;
	[super dealloc];
}

- (void)publish
{
   // we can only publish the service if we have a type to publish with
   if (!self.netService && 
		 ([[GrowlPreferencesController sharedController] isGrowlServerEnabled] || 
		  [[GrowlPreferencesController sharedController] isSubscriptionAllowed])) 
	{
		NSLog(@"publishing");
      NSString *publishingDomain = @"";
      NSString *publishingName = nil;
		NSString *thisHostName = [GrowlNetworkUtilities localHostName];
		if ([thisHostName hasSuffix:@".local"]) {
			publishingName = [thisHostName substringToIndex:([thisHostName length] - 6)];
		}else
			publishingName = thisHostName;
      
      self.netService = [[[NSNetService alloc] initWithDomain:publishingDomain 
																			type:@"_gntp._tcp." 
																			name:publishingName 
																			port:GROWL_TCP_PORT] autorelease];
      NSDictionary * txtRecordDataDictionary = [NSDictionary dictionaryWithObjectsAndKeys: @"1.0", @"version", @"mac", @"platform", @"13", @"websocket", nil];
      [self.netService setTXTRecordData:[NSNetService dataFromTXTRecordDictionary:txtRecordDataDictionary]];
      [self.netService publish];
   }
}

- (void)unpublish
{
	if(!self.netService)
		return;
	
   NSLog(@"unpublishing");
   [self.netService stop];
	self.netService = nil;
}
 
#pragma mark GNTPServerDelegate

- (void)server:(GNTPServer*)server registerWithDictionary:(NSDictionary *)dictionary {
	[super registerApplicationWithDictionary:dictionary];
}

- (GrowlNotificationResult)server:(GNTPServer*)server notifyWithDictionary:(NSDictionary *)dictionary {
   if([server isEqual:self.remoteServer]){
      NSMutableArray *keys = [[dictionary allKeys] mutableCopy];
      [keys removeObject:GROWL_NOTIFICATION_ALREADY_SHOWN];
      dictionary = [dictionary dictionaryWithValuesForKeys:keys];
   }
   
	return [super resultOfPostNotificationWithDictionary:dictionary];
}

-(void)server:(GNTPServer*)server subscribeWithDictionary:(GNTPSubscribePacket*)packet {
	[[GNTPSubscriptionController sharedController] addRemoteSubscriptionFromPacket:packet];
}

-(NSUInteger)totalSocketCount {
	return [self.remoteServer socketCount] + [self.localServer socketCount];
}

@end
