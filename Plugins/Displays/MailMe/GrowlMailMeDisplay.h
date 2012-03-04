//
//  GrowlMailMeDisplay.h
//  Growl Display Plugins
//
//  Copyright 2004 Peter Hosey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GrowlPlugins/GrowlActionPlugin.h>

@interface GrowlMailMeDisplay: GrowlActionPlugin <GrowlDispatchNotificationProtocol> {
	NSString *pathToMailSenderProgram;
	NSDictionary *defaultSMTPAccount;
	NSString *fromAddress; //May be a "Name <Address>" string.
	NSMutableArray *tasks;
}

@end
