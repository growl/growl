//
//  AppDelegate.m
//  GNTPTestServer
//
//  Created by Daniel Siemer on 6/20/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "AppDelegate.h"
#import "GNTPServer.h"

@interface AppDelegate ()

@property (nonatomic, retain) GNTPServer *server;

@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize server = _server;

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	self.server = [[[GNTPServer alloc] init] autorelease];
	[self.server startServer];
}

@end
