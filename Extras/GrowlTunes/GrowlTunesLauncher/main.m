//
//  main.m
//  GrowlTunesLauncher
//
//  Created by Travis Tilley on 2/2/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, char *argv[])
{
//    return NSApplicationMain(argc, (const char **)argv);
    AppDelegate * delegate = [[AppDelegate alloc] init];
    [[NSApplication sharedApplication] setDelegate:delegate];
    [NSApp run];
}
