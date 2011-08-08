//
//  GroupedArrayController.m
//  Growl
//
//  Created by Daniel Siemer on 7/29/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GroupedArrayController.h"
#import "GrowlNotificationDatabase.h"

@implementation GroupedArrayController

@synthesize grouped;
@synthesize updateArray;
@synthesize context;
@synthesize entityName;
@synthesize basePredicateString;
@synthesize groupKey;
@synthesize currentGroups;
@synthesize groupControllers;
@synthesize countController;

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
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(databaseDidChange:) 
                                                     name:NSManagedObjectContextObjectsDidChangeNotification
                                                   object:self.context];
                
        [countController addObserver:self 
                           forKeyPath:@"arrangedObjects.count" 
                              options:NSKeyValueObservingOptionNew 
                              context:nil];
        self.groupControllers = [NSMutableDictionary dictionary];
        self.currentGroups = [NSMutableArray array];
        self.grouped = YES;
        self.updateArray = YES;
        
    }
    
    return self;
}

-(void)setGrouped:(BOOL)newGroup
{
    [self willChangeValueForKey:@"grouped"];
    grouped = newGroup;
    [self notifyUpdates];
    [self didChangeValueForKey:@"grouped"];
}

/* Our arranged objects, based on whether we are grouped or not
 * Cached array keeps value so we don't have to redo this every call to it
 * If we are grouped, we build the array, if not, we simply ask countController for its
 */
-(NSArray*)arrangedObjects
{
    static NSArray *_cacheArray = nil;
    if(_cacheArray && !updateArray)
        return _cacheArray;

    if(_cacheArray){
        [_cacheArray release];
        _cacheArray = nil;
    }
    
    if(!grouped){
        return [countController arrangedObjects];
    }else{
        NSMutableArray *temp = [NSMutableArray array];
        [currentGroups enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [temp addObject:obj];
            id controller = [groupControllers valueForKey:obj];
            [temp addObjectsFromArray:[controller arrangedObjects]];
        }];
        _cacheArray = [temp copy];
    }
    return _cacheArray;
}

//Force fetch's because setAutomaticallyPreparesContent isn't working? (need to fix)
-(void)databaseDidChange:(NSNotification*)note
{
    [self.countController fetch:nil];
    [groupControllers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [obj fetch:nil];
    }];
}

-(void)notifyUpdates
{
    self.updateArray = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GroupControllerUpdated" object:self];
}
        
-(void)updateArrayGroups
{
    //Determine which groups have been added and removed
    NSMutableSet *added = [NSMutableSet set];
    NSMutableSet *current = [NSMutableSet setWithArray:currentGroups];
    NSMutableSet *removed = [NSMutableSet setWithArray:currentGroups];
        
    [[self.countController arrangedObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *groupName = [obj valueForKey:self.groupKey];
        [added addObject:groupName];
    }];
    
    [removed minusSet:added];
    [added minusSet:current];
    
    /* There weren't any updates to groups, no need to go further
       only notify of updates if we are grouped at this point */
    if([added count ] == 0 && [removed count] == 0){
        if(!grouped)
            [self notifyUpdates];
        return;
    }
    
    //Add any new groups to the groupControllers, making new array controllers for them
    [added enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        NSString *groupID = obj;
        [currentGroups addObject:groupID];
        
        NSArrayController *newController = [[NSArrayController alloc] init];
        [newController setManagedObjectContext:self.context];
        [newController setEntityName:entityName];
        [newController setAutomaticallyPreparesContent:YES];
        [newController setAutomaticallyRearrangesObjects:YES];
        NSString *format = [NSString stringWithFormat:@"(%@) AND (%@ == \"%@\")", basePredicateString, self.groupKey, groupID];
        [newController setFetchPredicate:[NSPredicate predicateWithFormat:format]];
        [newController setSortDescriptors:[countController sortDescriptors]];
        
        [newController addObserver:self 
                        forKeyPath:@"arrangedObjects.count" 
                           options:NSKeyValueObservingOptionNew 
                           context:nil];
        [newController fetch:self];
        [groupControllers setValue:newController forKey:groupID];
        [newController release];
        newController = nil;
    }];
    
    //remove any new arrayControllers
    [removed enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        NSString *groupID = obj;
        [groupControllers removeObjectForKey:groupID];
        [currentGroups removeObject:groupID];
    }];
    
    [currentGroups sortUsingSelector:@selector(compare:)];
         
    [self notifyUpdates];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"arrangedObjects.count"]){
        if([object isEqualTo:countController]){
            [self updateArrayGroups];
        }else{
            [self notifyUpdates];
        }
    }
}

@end
