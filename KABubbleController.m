//
//  KABubbleController.m
//  Growl
//
//  Created by Nelson Elhage on Wed Jun 09 2004.
//  Copyright (c) 2004 Nelson Elhage. All rights reserved.
//

#import "KABubbleController.h"
#import "KABubbleWindowController.h"


@implementation KABubbleController

#pragma mark Growl Gets Satisfaction

- (id) loadPlugin {
	//if I had setup procedures I would do them here
	return self; 
}

- (NSString *) author {
	//yea no need to do stringWithString, I just wanna
	return [NSString stringWithString:@"Karl Adam and Timothy Hatcher"];
}

- (NSString *) name {
	return [NSString stringWithString:@"BUBBLES!"];
}

- (NSString *) userDescription {
	return [NSString stringWithString:@"Bubbley Status Notifications"];
}

- (NSString *) version {
	return [NSString stringWithString:@"1.0a"];
}

- (void) unloadPlugin {
	// if I had things to clean up/undo I would do it here,
	// fortunately Bubbles do their job pretty cleanly without touching others.
}

- (void)  displayNotificationWithInfo:(NSDictionary *) noteDict {
	KABubbleWindowController *nuBubble = [KABubbleWindowController bubbleWithTitle:[noteDict objectForKey:GROWL_NOTIFICATION_TITLE] 
																			  text:[noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION] 
																			  icon:[noteDict objectForKey:GROWL_NOTIFICATION_ICON]];
	[nuBubble startFadeIn];
	NSLog( @"bubble - %@", nuBubble );
}

@end
