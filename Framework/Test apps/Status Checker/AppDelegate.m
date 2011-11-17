//
//  AppDelegate.m
//  Status Checker
//
//  Created by Peter Hosey on 2009-08-07.
//  Copyright 2009 Peter Hosey. All rights reserved.
//

#import "AppDelegate.h"

#import "StatusDisplayer.h"
#import "YesOrNoValueTransformer.h"

#import <Growl/Growl.h>

@implementation AppDelegate

- (void) awakeFromNib {
	YesOrNoValueTransformer *imageTransformer = [[YesOrNoValueTransformer alloc] init];
	imageTransformer.yesObject = [NSImage imageNamed:@"Yes"];
	imageTransformer.noObject = [NSImage imageNamed:@"No"];
	[NSValueTransformer setValueTransformer:imageTransformer forName:@"YesOrNoImageTransformer"];
	[imageTransformer release];

	YesOrNoValueTransformer *stringTransformer = [[YesOrNoValueTransformer alloc] init];
	stringTransformer.yesObject = NSLocalizedString(@"Yes", /*comment*/ @"Strings for Boolean values");
	stringTransformer.noObject = NSLocalizedString(@"No", /*comment*/ @"Strings for Boolean values");
	[NSValueTransformer setValueTransformer:stringTransformer forName:@"YesOrNoLocalizedStringTransformer"];
	[stringTransformer release];
}

- (void) applicationWillFinishLaunching:(NSNotification *)notification {
	displayer = [[StatusDisplayer alloc] init];
}
- (void) applicationWillTerminate:(NSNotification *)notification {
	[displayer release];
}

- (void) applicationWillBecomeActive:(NSNotification *)notification {
	displayer.isGrowlInstalled = [GrowlApplicationBridge isGrowlInstalled];
	displayer.isGrowlRunning = [GrowlApplicationBridge isGrowlRunning];
}

@end
