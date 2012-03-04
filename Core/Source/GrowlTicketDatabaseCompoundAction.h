//
//  GrowlTicketDatabaseCompoundAction.h
//  Growl
//
//  Created by Daniel Siemer on 3/2/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "GrowlTicketDatabaseAction.h"

@class GrowlTicketDatabaseAction;

@interface GrowlTicketDatabaseCompoundAction : GrowlTicketDatabaseAction

@property (nonatomic, retain) NSSet *actions;
@end

@interface GrowlTicketDatabaseCompoundAction (CoreDataGeneratedAccessors)

- (void)addActionsObject:(GrowlTicketDatabaseAction *)value;
- (void)removeActionsObject:(GrowlTicketDatabaseAction *)value;
- (void)addActions:(NSSet *)values;
- (void)removeActions:(NSSet *)values;

-(NSSet*)resolvedActionConfigSet;

@end
