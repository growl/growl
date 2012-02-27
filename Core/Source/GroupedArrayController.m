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
@synthesize context;
@synthesize tableView;
@synthesize entityName;
@synthesize basePredicateString;
@synthesize groupKey;
@synthesize currentGroups;
@synthesize groupControllers;
@synthesize countController;
@synthesize arrangedObjects;
@synthesize groupCompareBlock;
@synthesize selection;
@synthesize grouped;
@synthesize doNotShowSingleGroupHeader;
@synthesize showEmptyGroups;
@synthesize transitionGroup;

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
		 if(basePredicateString && ![basePredicateString isEqualToString:@""])
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
		 self.showEmptyGroups = NO;
		 self.transitionGroup = NO;
		 self.doNotShowSingleGroupHeader = NO;
    }
    
    return self;
}

- (void)dealloc {
	[entityName release];
	[basePredicateString release];
	[groupKey release];
	[currentGroups release];
	[groupControllers release];
	[countController release];
	[arrangedObjects release];
	[groupCompareBlock release];
	[selection release];
	[super dealloc];
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
    grouped = newGroup;
    [self updateArray];
}

-(void)setDoNotShowSingleGroupHeader:(BOOL)doNotShow 
{
	doNotShowSingleGroupHeader = doNotShow;
	[self updateArray];
}

-(void)setTableView:(NSTableView *)newTable
{
	if(tableView){
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSTableViewSelectionDidChangeNotification object:tableView];
	}
	tableView = newTable;
	[[NSNotificationCenter defaultCenter] addObserver:self 
														  selector:@selector(tableViewSelectionDidChange:) 
																name:NSTableViewSelectionDidChangeNotification
															 object:tableView];
}

-(void)updateArray
{
	NSArray *destination = [self updatedArray];
	NSArray *current = [arrangedObjects retain];
	self.arrangedObjects = destination;
	
	//NSLog(@"Current: %lu", [current count]);
	//NSLog(@"Destination: %lu", [destination count]);
	
	if([destination count] == 0 && [current count] == 0){
		//No changes, easiest to do nothing, current is released below if block, so just let it drop to the bottom
	}else if([current count] == 0 && [destination count] > 0){
		//Add all
		[self beginUpdates];
		[self insertIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [destination count])]];
		[self endUpdates];
	}else if([destination count] == 0 && [current count] > 0){
		//Remove all
		[self beginUpdates];
		[self removeIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [current count])]];
		[self endUpdates];
	}else{
		//Add/Remove in the right order to make NSTableView happy
		[self beginUpdates];
		__block NSMutableArray *currentCopy = [current mutableCopy];
		
		__block NSUInteger added = 0;
		__block GroupedArrayController *blockSafeSelf = self;
		[destination enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
			NSInteger oldIndex = [currentCopy indexOfObject:obj];
			if(oldIndex == NSNotFound){
				added++;
				[blockSafeSelf insertIndexes:[NSIndexSet indexSetWithIndex:idx]];
			}else{
				if(oldIndex != 0)
					[blockSafeSelf moveIndex:idx + oldIndex toIndex:idx];
				[currentCopy removeObjectAtIndex:oldIndex];
			}
		}];
		//NSLog(@"Added: %lu", added);
		//NSLog(@"removed: %lu", [currentCopy count]);
				
		if([currentCopy count] > 0){
			NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange([destination count], [currentCopy count])];
			[self removeIndexes:indexSet];
		}
		
		[currentCopy release];
		[self endUpdates];
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
    if(!grouped || ([currentGroups count] <= 1 && doNotShowSingleGroupHeader)){
        array = [[[countController arrangedObjects] copy] autorelease];
    }else{
        NSMutableArray *temp = [NSMutableArray array];
        [currentGroups enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            //If the app doesn't have any count (say a timing issue with its removal, or a filter predicate)
            //Dont bother to add it
            if([[[obj groupArray] arrangedObjects] count] > 0/*|| showEmptyGroups*/){
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
		NSString *groupName = [obj valueForKeyPath:blockSafeSelf.groupKey];
		[added addObject:groupName];
	}];
	
	[removed minusSet:added];
	[added minusSet:current];
	
	/* There weren't any updates to groups, no need to go further
	 only notify of updates if we are grouped at this point */
	//NSLog(@"added: %lu groups\nremoved%lu groups", [added count], [removed count]);
	if([added count] == 0 && [removed count] == 0){
		//if(!grouped)
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
		
		NSString *predicateString = nil;
		if(basePredicateString && ![basePredicateString isEqualToString:@""])
			predicateString = [NSString stringWithFormat:@"(%@) AND (%@ == \"%@\")", basePredicateString, groupKey, groupID];
		else
			predicateString = [NSString stringWithFormat:@"(%@ == \"%@\")", groupKey, groupID];
		[newController setFetchPredicate:[NSPredicate predicateWithFormat:predicateString]];
		[newController setSortDescriptors:[countController sortDescriptors]];
		
		[newController fetch:blockSafeSelf];
		GroupController *newGroup = [[GroupController alloc] initWithGroupID:groupID arrayController:newController];
		[newGroup setOwner:blockSafeSelf];
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
	
	
	NSComparator compare = nil;
	if(groupCompareBlock)
		compare = groupCompareBlock;
	else
		compare = ^(id obj1, id obj2){
			return [obj1 compare:obj2];
		};
	[currentGroups sortUsingComparator:compare];
	
	[self updateArray];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)ctxt
{
    if([keyPath isEqualToString:@"arrangedObjects.count"]){
        if([object isEqualTo:countController]){
            [self updateArrayGroups];
				[self updatedTotalCount];
        }else{            
            if(ctxt != NULL && [(id)ctxt isKindOfClass:[GroupController class]]){
                GroupController *group = (GroupController*)ctxt;
                if(grouped && [group showGroup])
                    [self updateArray];
            }
        }
    }
}

-(void)tableViewSelectionDidChange:(NSNotification*)note {
	if(tableView){
		NSInteger index = [tableView selectedRow];
		if(index >= 0)
			self.selection = [arrangedObjects objectAtIndex:index];
	}
}

#pragma mark Selection/SelectedObjects, convenience method only usable with tableView set

-(NSUInteger)indexOfFirstNonGroupItem {
	NSUInteger index = [arrangedObjects indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
		if(![obj isKindOfClass:[GroupController class]])
			return YES;
		return NO;
	}];
	return index;
}

-(NSArray*)selectedObjects{
	NSArray *selectedObjects = nil;
	if(tableView)
		selectedObjects = [arrangedObjects objectsAtIndexes:[tableView selectedRowIndexes]];
	return selectedObjects;
}

#pragma mark Delegate forwarding, and tableview updates

-(void)updatedTotalCount{
	if([delegate respondsToSelector:@selector(groupedControllerUpdatedTotalCount:)])
		[delegate groupedControllerUpdatedTotalCount:self];
}
-(void)beginUpdates{
	if(tableView){
		[NSAnimationContext beginGrouping];
		[[NSAnimationContext currentContext] setDuration:.25];
		[tableView beginUpdates];
	}
	if([delegate respondsToSelector:@selector(groupedControllerBeginUpdates:)])
		[delegate groupedControllerBeginUpdates:self];
}
-(void)endUpdates{
	if([delegate respondsToSelector:@selector(groupedControllerEndUpdates:)])
		[delegate groupedControllerEndUpdates:self];
	if(tableView){
		[tableView endUpdates];
		[NSAnimationContext endGrouping];
	}
	transitionGroup = NO;
}
-(void)insertIndexes:(NSIndexSet*)indexSet{
	if(tableView){
		NSTableViewAnimationOptions options = NSTableViewAnimationEffectFade|NSTableViewAnimationEffectGap;
		if (!transitionGroup)
			options = options|NSTableViewAnimationSlideLeft;
		[tableView insertRowsAtIndexes:indexSet withAnimation:options];
	}
	if([delegate respondsToSelector:@selector(groupedController:insertIndexes:)])
		[delegate groupedController:self insertIndexes:indexSet];
}
-(void)removeIndexes:(NSIndexSet*)indexSet{
	if(tableView){
		NSTableViewAnimationOptions options = NSTableViewAnimationEffectFade|NSTableViewAnimationEffectGap;
		if (!transitionGroup)
			options = options|NSTableViewAnimationSlideRight;
		[tableView removeRowsAtIndexes:indexSet withAnimation:options];
	}
	if([delegate respondsToSelector:@selector(groupedController:removeIndexes:)])
		[delegate groupedController:self removeIndexes:indexSet];
}
-(void)moveIndex:(NSUInteger)start toIndex:(NSUInteger)end{
	if(tableView)
		[tableView moveRowAtIndex:start toIndex:end];
	if([delegate respondsToSelector:@selector(groupedController:moveIndex:toIndex:)])
		[delegate groupedController:self moveIndex:start toIndex:end];
}

@end
