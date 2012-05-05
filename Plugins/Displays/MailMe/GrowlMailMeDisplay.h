//
//  GrowlMailMeDisplay.h
//  Growl Display Plugins
//
//  Copyright 2004 Peter Hosey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GrowlDisplayPlugin.h"

@interface GrowlMailMeDisplay: GrowlDisplayPlugin {
	NSString *pathToMailSenderProgram;
	NSDictionary *defaultSMTPAccount;
	NSString *fromAddress; //May be a "Name <Address>" string.
	NSMutableArray *tasks;
}

- (void) displayNotification:(GrowlNotification *)notification;

@end
