//
//  AppDelegate.h
//  GNTPTestServer
//
//  Created by Daniel Siemer on 6/20/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GNTPServer.h"
#import "GrowlMiniDispatch.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, GNTPServerDelegate, GrowlMiniDispatchDelegate>

@property (assign) IBOutlet NSWindow *window;

@end
