//
//  AppDelegate.m
//  GNTPTestServer
//
//  Created by Daniel Siemer on 6/20/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "AppDelegate.h"
#import "NSStringAdditions.h"
#import "GrowlDefines.h"
#import "GrowlDefinesInternal.h"

@interface AppDelegate ()

@property (nonatomic, retain) GNTPServer *server;
@property (nonatomic, retain) NSMutableDictionary *registeredApps;

@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize server = _server;
@synthesize registeredApps = _registeredApps;

-(id)init {
	if((self = [super init])){
		self.registeredApps = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	self.server = [[[GNTPServer alloc] init] autorelease];
	self.server.delegate = (id<GNTPServerDelegate>)self;
	[self.server startServer];
}

//File the dictionary under its hostname - appname for test
-(void)registerWithDictionary:(NSDictionary*)dictionary {
	NSString *appName = [dictionary valueForKey:GROWL_APP_NAME];
	NSString *hostName = [dictionary valueForKey:GROWL_NOTIFICATION_GNTP_SENT_BY];
	NSString *combined = appName;
	if(hostName && ![hostName isLocalHost])
		combined = [NSString stringWithFormat:@"%@-%@", hostName, appName];
	NSLog(@"Registering: %@\n for key: %@", [dictionary valueForKey:GROWL_APP_NAME], combined);
	[self.registeredApps setObject:dictionary forKey:combined];
}
//Do a crude note display for test
-(void)notifyWithDictionary:(NSDictionary*)dictionary {
	NSLog(@"Notifying: %@", [dictionary valueForKey:GROWL_NOTIFICATION_TITLE]);
}
//Do nothing except log for test?
-(void)subscribeWithDictionary:(NSDictionary*)dictionary {
	
}
//
-(BOOL)isNoteRegistered:(NSString*)noteName forApp:(NSString*)appName onHost:(NSString*)host {
	BOOL registered = NO;
	NSString *combined = appName;
	if(host && ![host isEqualToString:@""] && ![host isLocalHost])
		combined = [NSString stringWithFormat:@"%@-%@", host, appName];
	NSDictionary *registeredDict = [self.registeredApps objectForKey:combined];
	if(registeredDict){
		NSArray *registeredNotes = [registeredDict objectForKey:GROWL_NOTIFICATIONS_ALL];
		if([registeredNotes containsObject:noteName])
			registered = YES;
	}
	return registered;
}


@end
