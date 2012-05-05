//
//  StatusDisplayer.m
//  Status Checker
//
//  Created by Peter Hosey on 2009-08-07.
//  Copyright 2009 Peter Hosey. All rights reserved.
//

#import "StatusDisplayer.h"

@implementation StatusDisplayer

- init {
	if((self = [super init])) {
		[NSBundle loadNibNamed:@"StatusDisplay" owner:self];
	}
	return self;
}
- (void) dealloc {
	[window close];
	[window release];

	[super dealloc];
}

@synthesize isGrowlInstalled, isGrowlRunning;

@end
