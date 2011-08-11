//
//  GroupedArrayController.m
//  Growl
//
//  Created by Daniel Siemer on 7/29/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GroupedArrayController.h"

@implementation GroupedArrayController

@synthesize delegate;
@synthesize grouped;
@synthesize shouldUpdateArray;
@synthesize context;
@synthesize entityName;
@synthesize basePredicateString;
@synthesize groupKey;
@synthesize currentGroups;
@synthesize groupControllers;
@synthesize showGroup;
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
        self.showGroup = [NSMutableDictionary dictionary];
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
    if(![showGroup valueForKey:groupID] || !grouped)
        return;
    
    BOOL current = [[showGroup valueForKey:groupID] boolValue];
    [showGroup setValue:[NSNumber numberWithBool:current ? NO : YES] forKey:groupID];
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
    shouldUpdateArray = YES;
    NSArray *destination = [self newArray];
    NSArray *current = arrangedObjects;
    self.arrangedObjects = destination;
    
    if(!delegate)
        return;
    
    if([destination isEqualToArray:current]){
        //No changes
        return;
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
}

/* Our new arranged objects, based on whether we are grouped or not
 * Cached array keeps value so we don't have to redo this every call to it
 * If we are grouped, we build the array, if not, we simply ask countController for its
 */
-(NSArray*)newArray
{
    NSArray *_cacheArray = nil;
    if(_cacheArray && !shouldUpdateArray)
        return _cacheArray;

    if(_cacheArray){
        [_cacheArray release];
        _cacheArray = nil;
    }
    shouldUpdateArray = NO;
    if(!grouped){
        _cacheArray = [[countController arrangedObjects] copy];
    }else{
        NSMutableArray *temp = [NSMutableArray array];
        [currentGroups enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            //If the app doesn't have any count (say a timing issue with its removal, or a filter predicate)
            //Dont bother to add it
            if([[[groupControllers valueForKey:obj] arrangedObjects] count] > 0){
                [temp addObject:obj];
                if([[showGroup valueForKey:obj] boolValue]){
                    id controller = [groupControllers valueForKey:obj];
                    [temp addObjectsFromArray:[controller arrangedObjects]];
                }
            }
        }];
        _cacheArray = [temp copy];
    }
    return _cacheArray;
}
        
-(void)updateArrayGroups
{
    __block GroupedArrayController *blockSafeSelf = self;

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
    if([added count] == 0 && [removed count] == 0){
        if(!grouped)
            [self updateArray];
        return;
    }
    
    //Add any new groups to the groupControllers, making new array controllers for them
    [added enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        NSString *groupID = obj;
        [currentGroups addObject:groupID];
        [showGroup setValue:[NSNumber numberWithBool:YES] forKey:groupID];
        
        NSArrayController *newController = [[NSArrayController alloc] init];
        [newController setManagedObjectContext:context];
        [newController setEntityName:entityName];
        [newController setAutomaticallyPreparesContent:YES];
        [newController setAutomaticallyRearrangesObjects:YES];
        NSString *format = [NSString stringWithFormat:@"(%@) AND (%@ == \"%@\")", basePredicateString, groupKey, groupID];
        [newController setFetchPredicate:[NSPredicate predicateWithFormat:format]];
        [newController setSortDescriptors:[countController sortDescriptors]];
        
        [newController addObserver:blockSafeSelf 
                        forKeyPath:@"arrangedObjects.count" 
                           options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld 
                           context:groupID];

        [newController fetch:blockSafeSelf];
        [groupControllers setValue:newController forKey:groupID];
        [newController release];
        newController = nil;
    }];
    
    //remove any old arrayControllers
    [removed enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        NSString *groupID = obj;
        [groupControllers removeObjectForKey:groupID];
        [currentGroups removeObject:groupID];
        [showGroup removeObjectForKey:groupID];
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
            NSString *groupID = ctxt;
            if(groupID){
                BOOL show = [[showGroup valueForKey:groupID] boolValue];
                if(grouped && show)
                    [self updateArray];
            }
        }
    }
}

@end
