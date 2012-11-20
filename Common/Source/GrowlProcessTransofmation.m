//
//  GrowlProcessTransofmation.m
//  GrowlTunes
//
//  Created by Daniel Siemer on 11/20/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlProcessTransofmation.h"

@implementation GrowlProcessTransofmation

static ProcessSerialNumber _previousPSN;
static id _changeObserver = nil;

+(BOOL)makeForgroundApp {
	BOOL didSet = NO;
	if((BOOL)isgreaterequal(NSFoundationVersionNumber, NSFoundationVersionNumber10_7)) {
		didSet = YES;
		ProcessSerialNumber psn = { 0, kCurrentProcess };
		TransformProcessType(&psn, kProcessTransformToForegroundApplication);
		NSNotificationCenter *nc = [[NSWorkspace sharedWorkspace] notificationCenter];
		_changeObserver = [nc addObserverForName:NSWorkspaceDidActivateApplicationNotification
													 object:nil
													  queue:[NSOperationQueue mainQueue]
												usingBlock:^(NSNotification *note) {
													ProcessSerialNumber newFrontPSN;
													GetFrontProcess(&newFrontPSN);
													ProcessSerialNumber growlPsn = { 0, kCurrentProcess };
													Boolean result;
													SameProcess(&newFrontPSN, &growlPsn, &result);
													if(!result){
														GetFrontProcess(&_previousPSN);
													}
												}];
	}
	return didSet;
}

+(BOOL)makeBackgroundApp {
	BOOL didSet = NO;
	if((BOOL)isgreaterequal(NSFoundationVersionNumber, NSFoundationVersionNumber10_7)) {
		didSet = YES;
		NSNotificationCenter *nc = [[NSWorkspace sharedWorkspace] notificationCenter];
		[nc removeObserver:_changeObserver];
		_changeObserver = nil;
		
		dispatch_async(dispatch_get_main_queue(), ^{
			ProcessSerialNumber psn = { 0, kCurrentProcess };
			TransformProcessType(&psn, kProcessTransformToUIElementApplication);
			SetFrontProcess(&_previousPSN);
		});
	}
	return didSet;
}

@end
