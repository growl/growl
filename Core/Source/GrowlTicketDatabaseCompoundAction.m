//
//  GrowlTicketDatabaseCompoundAction.m
//  Growl
//
//  Created by Daniel Siemer on 3/2/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlTicketDatabaseCompoundAction.h"
#import "GrowlTicketDatabaseAction.h"


@implementation GrowlTicketDatabaseCompoundAction

@dynamic actions;

-(BOOL)canFindInstance {
	return YES;
}

-(GrowlPlugin*)pluginInstanceForConfiguration {
	return nil;
}

-(NSSet*)resolvedActionConfigSet {
	return [[self.actions copy] autorelease];
}

@end
