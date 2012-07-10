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
@property (nonatomic, retain) NSMutableDictionary *displayedNotifications;
@property (nonatomic, retain) GrowlMiniDispatch *mistDispatch;

@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize server = _server;
@synthesize registeredApps = _registeredApps;
@synthesize displayedNotifications = _displayedNotifications;
@synthesize mistDispatch = _mistDispatch;

-(id)init {
	if((self = [super init])){
		self.registeredApps = [NSMutableDictionary dictionary];
		self.displayedNotifications = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void)dealloc
{
	self.registeredApps = nil;
	[super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	self.server = [[[GNTPServer alloc] init] autorelease];
	self.server.delegate = (id<GNTPServerDelegate>)self;
	[self.server startServer];
	
	self.mistDispatch = [[[GrowlMiniDispatch alloc] init] autorelease];
	self.mistDispatch.delegate = (id<GrowlMiniDispatchDelegate>)self;
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
	//NSLog(@"Notifying: %@", [dictionary valueForKey:GROWL_NOTIFICATION_TITLE]);
	NSString *guid = [dictionary objectForKey:@"GNTPGUID"];
	[self.displayedNotifications setObject:dictionary forKey:guid];
	
	//We stored the real dict in with a guid
	//replace the context we get from mini dispatch with the GUID so we can look
	//up the real dict and its real context
	NSMutableDictionary *growlDictCopy = [[dictionary mutableCopy] autorelease];
	[growlDictCopy setObject:guid forKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
	[self.mistDispatch displayNotification:growlDictCopy];
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

//Pass the full dict back into the server for now
- (void)growlNotificationWasClicked:(id)context {
	NSDictionary *growlDict = [[self.displayedNotifications objectForKey:context] retain];
	[self.displayedNotifications removeObjectForKey:context];
	[self.server notificationClicked:growlDict];
	[growlDict release];
}
- (void)growlNotificationTimedOut:(id)context {
	NSDictionary *growlDict = [[self.displayedNotifications objectForKey:context] retain];
	[self.displayedNotifications removeObjectForKey:context];
	[self.server notificationTimedOut:growlDict];
	[growlDict release];
}

@end
