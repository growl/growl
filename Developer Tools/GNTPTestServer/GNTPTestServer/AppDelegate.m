//
//  AppDelegate.m
//  GNTPTestServer
//
//  Created by Daniel Siemer on 6/20/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "AppDelegate.h"
#import "GrowlGNTPDefines.h"
#import "NSStringAdditions.h"

@interface AppDelegate ()

@property (nonatomic, retain) GNTPServer *server;
@property (nonatomic, retain) NSMutableDictionary *registeredApps;

@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize server = _server;
@synthesize registeredApps = _registeredApps;

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
	NSString *appName = [dictionary valueForKey:GrowlGNTPApplicationNameHeader];
	NSString *hostName = [dictionary valueForKey:GrowlGNTPOriginMachineName];
	NSString *combined = appName;
	if(hostName && ![hostName isLocalHost])
		combined = [NSString stringWithFormat:@"%@-%@", hostName, appName];
	//NSLog(@"Registering: %@\n for key: %@", dictionary, combined);
	[self.registeredApps setObject:dictionary forKey:combined];
}
//Do a crude note display for test
-(void)notifyWithDictionary:(NSDictionary*)dictionary {
	//NSLog(@"Notifying: %@", dictionary);
}
//Do nothing except log for test?
-(void)subscribeWithDictionary:(NSDictionary*)dictionary {
	
}
//
-(BOOL)isNoteRegistered:(NSString*)noteName forApp:(NSString*)appName onHost:(NSString*)host {
	BOOL registered = NO;
	NSString *combined = appName;
	if(host)
		combined = [NSString stringWithFormat:@"%@-%@", host, appName];
	NSDictionary *registeredDict = [self.registeredApps objectForKey:combined];
	if(registeredDict){
		NSArray *registeredNotes = [registeredDict objectForKey:@"AllNotifications"];
		if([registeredNotes containsObject:noteName])
			registered = YES;
	}
	return registered;
}


@end
