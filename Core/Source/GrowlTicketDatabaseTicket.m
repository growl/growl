//
//  GrowlTicketDatabaseTicket.m
//  Growl
//
//  Created by Daniel Siemer on 2/22/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlTicketDatabaseTicket.h"
#import "GrowlTicketDatabase.h"
#import "GrowlTicketDatabasePlugin.h"
#import "GrowlTicketDatabaseCompoundAction.h"

@implementation GrowlTicketDatabaseTicket

@dynamic enabled;
@dynamic iconData;
@dynamic loggingEnabled;
@dynamic name;
@dynamic positionType;
@dynamic selectedPosition;
@dynamic ticketDescription;
@dynamic actions;
@dynamic children;
@dynamic parent;
@dynamic display;

-(BOOL)isTicketAllowed {
   if(self.parent)
      return [self.enabled boolValue] && [self.parent isTicketAllowed];
   else
      return [self.enabled boolValue];
}

-(GrowlTicketDatabasePlugin*)resolvedDisplayConfig {
	GrowlTicketDatabasePlugin *plugin = nil;
	if(self.display)
		plugin = (GrowlTicketDatabasePlugin*)self.display;
	else {
		if(self.parent)
			plugin = [self.parent resolvedDisplayConfig];
		else {
			plugin = [[GrowlTicketDatabase sharedInstance] defaultDisplayConfig];
		}
	}
	return plugin;
}
-(NSSet*)resolvedActionConfigSet {
	NSSet *result = nil;
	if(self.actions && [self.actions count] > 0){
		__block NSMutableSet *buildSet = [NSMutableSet set];
		[self.actions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			if([[obj entityName] isEqualToString:@"GrowlCompoundAction"])
				[buildSet unionSet:[(GrowlTicketDatabaseCompoundAction*)obj resolvedActionConfigSet]];
			else
				[buildSet unionSet:[NSSet setWithObject:obj]];
		}];
		result = [[buildSet copy] autorelease];
	}else{
		if(self.parent)
			result = [self.parent resolvedActionConfigSet];
		else {
			//result = [[GrowlTicketDatabase sharedInstance] defaultActionConfigSet];
		}
	}
	return result;
}

-(void)setNewDisplayName:(NSString*)name {
	if(!name || [name isEqualToString:@""]){
		self.display = nil;
		[[GrowlTicketDatabase sharedInstance] saveDatabase:NO];
		return;
	}
	GrowlTicketDatabasePlugin *action = [[GrowlTicketDatabase sharedInstance] actionForName:name];
	
	if(!action){
		action = [NSEntityDescription insertNewObjectForEntityForName:@"GrowlDisplay" inManagedObjectContext:[self managedObjectContext]];
		action.displayName = name;
	}
	self.display = (GrowlTicketDatabaseDisplay*)action;
	[[GrowlTicketDatabase sharedInstance] saveDatabase:NO];
}

-(void)importDisplayOrActionForName:(NSString*)name {
	if(!name)
		return;
	
	GrowlTicketDatabasePlugin *action = [[GrowlTicketDatabase sharedInstance] actionForName:name];
	BOOL addAsAction = NO;
	
	//Special case import for action types
	/*if([name caseInsensitiveCompare:@"SMS"] == NSOrderedSame ||
		[name caseInsensitiveCompare:@"MailMe"] == NSOrderedSame ||
		[name caseInsensitiveCompare:@"Prowl"] == NSOrderedSame ||
		[name caseInsensitiveCompare:@"Boxcar"] == NSOrderedSame ||
		[name caseInsensitiveCompare:@"Speech"] == NSOrderedSame)
		addAsAction = YES;*/
	
	if(!action){
		NSString *entity = @"GrowlDisplay";
		if(addAsAction)
			entity = @"GrowlAction";
		
		action = [NSEntityDescription insertNewObjectForEntityForName:entity inManagedObjectContext:[self managedObjectContext]];
		action.displayName = name;
	}
	
	if(addAsAction){
		[self addActionsObject:(NSManagedObject*)action];
	}else
		self.display = (GrowlTicketDatabaseDisplay*)action;
}

@end
