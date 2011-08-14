//
//  GroupedArrayController.m
//  Growl
//
//  Created by Daniel Siemer on 7/29/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GroupedArrayController.h"
#import "GroupController.h"

@implementation GroupedArrayController

@synthesize delegate;
@synthesize grouped;
@synthesize context;
@synthesize entityName;
@synthesize basePredicateString;
@synthesize groupKey;
@synthesize currentGroups;
@synthesize groupControllers;
@synthesize countController;
@synthesize arrangedObjects;

- (id)initWithEntityName:(NSString*)entity
     basePredicateString:(NSString*)predicate
                groupKey:(NSString*)key
    managedObjectContext:(NSManagedObjectContext*)aContext
{
    self = [super init];
    if (self) {
        self.entityName = entity;
        self.basePredicateString = predicate;
        self.groupKey = key;
        self.context = aContext;
        
        // Initialization code here.
        self.countController = [[[NSArrayController alloc] init] autorelease];
        [countController setManagedObjectContext:self.context];
        [countController setEntityName:entityName];
        [countController setFetchPredicate:[NSPredicate predicateWithFormat:self.basePredicateString]];
        [countController setAutomaticallyPreparesContent:YES];
        [countController setAutomaticallyRearrangesObjects:YES];
        [countController setUsesLazyFetching:YES];
        [countController setEditable:YES];

        [countController addObserver:self 
                           forKeyPath:@"arrangedObjects.count" 
                              options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                              context:nil];
        
        [countController fetch:nil];
        
        self.groupControllers = [NSMutableDictionary dictionary];
        self.currentGroups = [NSMutableArray array];
        self.grouped = YES;
    }
    
    return self;
}

-(void)toggleGrouped
{
    if(grouped){
        [self setGrouped:NO];
    }else{
        [self setGrouped:YES];
    }
}

-(void)toggleShowGroup:(NSString*)groupID
{
    GroupController *controller = [groupControllers valueForKey:groupID];
    if(!controller)
        return;
    
    [controller setShowGroup:[controller showGroup] ? NO : YES];
    if(grouped)
        [self updateArray];
}

-(void)setGrouped:(BOOL)newGroup
{
    [self willChangeValueForKey:@"grouped"];
    grouped = newGroup;
    [self didChangeValueForKey:@"grouped"];
    [self updateArray];
}

-(void)updateArray
{
    NSArray *destination = [self updatedArray];
    NSArray *current = [arrangedObjects retain];
    self.arrangedObjects = destination;
    
    if(!delegate || [destination isEqualToArray:current]){
        //No changes, easiest to do nothing, current is released below if block, so just let it drop to the bottom
    }else if([current count] == 0){
        //Add all
        [delegate groupedControllerBeginUpdates:self];
        [delegate groupedController:self insertIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [destination count])]];
        [delegate groupedControllerEndUpdates:self];
    }else if([destination count] == 0){
        //Remove all
        [delegate groupedControllerBeginUpdates:self];
        [delegate groupedController:self removeIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [current count])]];
        [delegate groupedControllerEndUpdates:self];
    }else{
        //Add/Remove in the right order to make NSTableView happy
        NSMutableArray *currentCopy = [current mutableCopy];
        [delegate groupedControllerBeginUpdates:self];
        
        __block GroupedArrayController *blockSafeSelf = self;
        
        [destination enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
            NSInteger oldIndex = [currentCopy indexOfObject:obj];
            if(oldIndex == NSNotFound){
                [delegate groupedController:blockSafeSelf insertIndexes:[NSIndexSet indexSetWithIndex:idx]];
            }else{
                [delegate groupedController:blockSafeSelf moveIndex:idx + oldIndex toIndex:idx];
                [currentCopy removeObjectAtIndex:0];
            }
        }];
        
        if([currentCopy count] > 0){
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange([destination count], [currentCopy count])];
            [delegate groupedController:self removeIndexes:indexSet];
        }
        
        [currentCopy release];
        [delegate groupedControllerEndUpdates:self];
    }
    [current release];
}

/* Our new arranged objects, based on whether we are grouped or not
 * Cached array keeps value so we don't have to redo this every call to it
 * If we are grouped, we build the array, if not, we simply ask countController for its
 */
-(NSArray*)updatedArray
{
    NSArray *array = nil;
    if(!grouped){
        array = [countController arrangedObjects];
    }else{
        NSMutableArray *temp = [NSMutableArray array];
        [currentGroups enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            //If the app doesn't have any count (say a timing issue with its removal, or a filter predicate)
            //Dont bother to add it
            if([[[obj groupArray] arrangedObjects] count] > 0){
                [temp addObject:obj];
                if([obj showGroup]){
                    [temp addObjectsFromArray:[[obj groupArray] arrangedObjects]];
                }
            }
        }];
        array = [[temp copy] autorelease];
    }
    return array;
}
        
-(void)updateArrayGroups
{
    __block GroupedArrayController *blockSafeSelf = self;

    //Determine which groups have been added and removed
    NSMutableSet *added = [NSMutableSet set];
    NSMutableSet *current = [NSMutableSet setWithArray:[currentGroups valueForKey:@"groupID"]];
    NSMutableSet *removed = [NSMutableSet setWithArray:[currentGroups valueForKey:@"groupID"]];
        
    [[self.countController arrangedObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *groupName = [obj valueForKey:self.groupKey];
        [added addObject:groupName];
    }];
    
    [removed minusSet:added];
    [added minusSet:current];
    
    /* There weren't any updates to groups, no need to go further
       only notify of updates if we are grouped at this point */
    if([added count] == 0 && [removed count] == 0){
        if(!grouped)
            [self updateArray];
        return;
    }
    
    //Add any new groups to the groupControllers, making new array controllers for them
    [added enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        NSString *groupID = obj;
                
        NSArrayController *newController = [[NSArrayController alloc] init];
        [newController setManagedObjectContext:context];
        [newController setEntityName:entityName];
        [newController setAutomaticallyPreparesContent:YES];
        [newController setAutomaticallyRearrangesObjects:YES];
        NSString *format = [NSString stringWithFormat:@"(%@) AND (%@ == \"%@\")", basePredicateString, groupKey, groupID];
        [newController setFetchPredicate:[NSPredicate predicateWithFormat:format]];
        [newController setSortDescriptors:[countController sortDescriptors]];

        [newController fetch:blockSafeSelf];
        GroupController *newGroup = [[GroupController alloc] initWithGroupID:groupID arrayController:newController];
        [currentGroups addObject:newGroup];
        [groupControllers setValue:newGroup forKey:groupID];
        
        [newController addObserver:blockSafeSelf 
                        forKeyPath:@"arrangedObjects.count" 
                           options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld 
                           context:newGroup];
        
        [newGroup release];
        newGroup = nil;
        [newController release];
        newController = nil;
    }];
    
    //remove any old arrayControllers
    [removed enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        NSString *groupID = obj;
        GroupController *group = [[groupControllers valueForKey:groupID] retain];
        [groupControllers removeObjectForKey:groupID];
        [currentGroups removeObject:group];
        [[group groupArray] removeObserver:self forKeyPath:@"arrangedObjects.count"];
        [group release];
    }];
    
    [currentGroups sortUsingSelector:@selector(compare:)];
    
    [self updateArray];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)ctxt
{
    if([keyPath isEqualToString:@"arrangedObjects.count"]){
        if([object isEqualTo:countController]){
            [self updateArrayGroups];
        }else{            
            if(ctxt != NULL && [(id)ctxt isKindOfClass:[GroupController class]]){
                GroupController *group = (GroupController*)ctxt;
                if(grouped && [group showGroup])
                    [self updateArray];
            }
        }
    }
}

@end
