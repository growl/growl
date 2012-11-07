//
//  GrowlWebKitWindowTransition.m
//  Growl
//
//  Created by Daniel Siemer on 10/30/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlWebKitWindowTransition.h"
#import "GrowlWebKitWindowView.h"

@implementation GrowlWebKitWindowTransition

-(void)startAnimation {
	if([self direction] == GrowlReverseTransition){
		GrowlWebKitWindowView *webView = (GrowlWebKitWindowView*)[[self window] contentView];
		[[webView windowScriptObject] callWebScriptMethod:@"animateOut" withArguments:nil];
	}
}

@end
