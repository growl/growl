//
//  AppDelegate.m
//  GrowlTunesLauncher
//
//  Created by Travis Tilley on 2/2/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSURL* appURL = [[[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"../../../../Contents/MacOS/GrowlTunes" isDirectory:NO] URLByResolvingSymlinksInPath];
    NSLog(@"Launching GrowlTunes at URL: %@", appURL);
    NSDictionary* conf = [NSDictionary dictionary];
    NSError* error = nil;
    [[NSWorkspace sharedWorkspace] launchApplicationAtURL:appURL options:NSWorkspaceLaunchDefault configuration:conf error:&error];
    if (error) {
        NSLog(@"%@", error);
    }
    [NSApp terminate:nil];
}

@end
