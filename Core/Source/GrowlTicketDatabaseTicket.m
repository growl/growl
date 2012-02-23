//
//  GrowlTicketDatabaseTicket.m
//  Growl
//
//  Created by Daniel Siemer on 2/22/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlTicketDatabaseTicket.h"
#import "GrowlTicketDatabase.h"
#import "GrowlTicketDatabaseAction.h"

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

-(void)setNewDisplayName:(NSString*)name {
	if(!name){
		self.display = nil;
		return;
	}
	GrowlTicketDatabaseAction *action = [[GrowlTicketDatabase sharedInstance] actionForName:name];
	
	if(!action){
		NSLog(@"make new display name %@", name);
		action = [NSEntityDescription insertNewObjectForEntityForName:@"GrowlDisplay" inManagedObjectContext:[self managedObjectContext]];
		action.name = name;
	}
	self.display = action;
	[[GrowlTicketDatabase sharedInstance] saveDatabase:NO];
}

-(void)importDisplayOrActionForName:(NSString*)name {
	if(!name)
		return;
	
	GrowlTicketDatabaseAction *action = [[GrowlTicketDatabase sharedInstance] actionForName:name];
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
		action.name = name;
	}
	
	if(addAsAction){
		[self addActionsObject:(NSManagedObject*)action];
	}else
		self.display = action;
}

@end
