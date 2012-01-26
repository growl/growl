//
//  AppDelegate.m
//  GrowlLauncher
//
//  Created by Daniel Siemer on 1/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
   NSLog(@"Launching Growl");
   if(![[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"growl://"]])
      NSLog(@"Error opening Growl! Launch Services database might be corrupt, try typing growl:// into your web browser's address field and see if growl launches");
   [NSApp terminate:self];
}

@end
