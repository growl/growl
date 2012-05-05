//
//  MultiGrowlAppDelegate.h
//  MultiGrowl
//
//  Created by Rudy Richter on 11/8/11.
//  Copyright 2011 The Growl Project, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>

@interface MultiGrowlAppDelegate : NSObject <NSApplicationDelegate, GrowlApplicationBridgeDelegate> 
{
	IBOutlet NSWindow *window;
}

- (IBAction)notify:(id)sender;

@end
