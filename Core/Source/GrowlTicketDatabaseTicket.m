//
//  GrowlTicketDatabaseTicket.m
//  Growl
//
//  Created by Daniel Siemer on 2/22/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlTicketDatabaseTicket.h"
#import "GrowlTicketDatabaseTicket.h"


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

-(BOOL)isTicketAllowed {
   if(self.parent)
      return [self.enabled boolValue] && [self.parent isTicketAllowed];
   else
      return [self.enabled boolValue];
}

@end
