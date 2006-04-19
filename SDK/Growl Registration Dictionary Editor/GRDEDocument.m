//
//  GRDEDocument.m
//  Growl Registration Dictionary Editor
//
//  Created by Peter Hosey on 2006-04-15.
//  Copyright 2006 Peter Hosey. All rights reserved.
//

#import "GRDEDocument.h"

#import "GRDENotification.h"

#import "GrowlDefines.h"

#define DRAG_TYPE @"org.boredzo.GrowlRegistrationDictionaryEditor.notification"
#define DRAG_INDICES_TYPE @"org.boredzo.GrowlRegistrationDictionaryEditor.notificationIndices"
#define DRAG_SRCDOCUMENTURL_TYPE @"org.boredzo.GrowlRegistrationDictionaryEditor.sourceDocumentURL"

@implementation GRDEDocument

- init {
	if((self = [super init])) {
		notificationDictionaries = [[NSMutableArray alloc] init];
		notificationNames        = [[NSMutableSet   alloc] init];
		plistFormat = NSPropertyListBinaryFormat_v1_0;
	}
	return self;
}
- (void)dealloc {
	[applicationName release];
	[bundleIdentifier release];
	[notificationDictionaries release];
	[notificationNames        release];
	[dictionaryRepresentation release];

	[super dealloc];
}

#pragma mark Actions

- (IBAction)insertNewNotification:sender {
	[arrayController commitEditing];

	unsigned idx = [arrayController selectionIndex];
	if(idx == NSNotFound)
		idx = 0U;
	else
		++idx;

	id obj = [[[arrayController objectClass] alloc] init];
	if([obj respondsToSelector:@selector(setDocument:)])
		[obj setDocument:self];
	[arrayController insertObject:obj atArrangedObjectIndex:idx];
	[obj release];

	[tableView reloadData];
	[tableView editColumn:0 row:idx withEvent:nil select:YES];
}

#pragma mark Accessors

- (NSString *)applicationName {
	return applicationName;
}
- (void)setApplicationName:(NSString *)newName {
	NSUndoManager *mgr = [self undoManager];
	[mgr registerUndoWithTarget:self
					   selector:@selector(setApplicationName:)
						 object:applicationName];
	[mgr setActionName:NSLocalizedString(@"Change Application Name", /*comment*/ nil)];

	[applicationName release];
	applicationName = [newName copy];
}
- (NSString *)bundleIdentifier {
	return bundleIdentifier;
}
- (void)setBundleIdentifier:(NSString *)newID {
	NSUndoManager *mgr = [self undoManager];
	[mgr registerUndoWithTarget:self
					   selector:@selector(setBundleIdentifier:)
						 object:bundleIdentifier];
	[mgr setActionName:NSLocalizedString(@"Change Bundle Identifier", /*comment*/ nil)];

	[bundleIdentifier release];
	bundleIdentifier = [newID copy];
}

- (NSMutableArray *)notificationDictionaries {
	return notificationDictionaries;
}
- (BOOL)validateNotificationDictionaries:(inout NSArray **)newValue error:(NSError **)outError {
	NSLog(@"validating notification dictionaries");
	NSCountedSet *set = [NSCountedSet set];

	NSEnumerator *newValueEnum = [*newValue objectEnumerator];
	GRDENotification *notification;
	while((notification = [newValueEnum nextObject])) {
		NSString *name = [notification name];
		[set addObject:name];
		if([set countForObject:name] > 1U) {
			//XXX Set *outError
			return NO;
		}
	}

	return YES;
}
- (void)setNotificationDictionaries:(NSArray *)array {
	NSUndoManager *mgr = [self undoManager];
	[mgr registerUndoWithTarget:self
					   selector:@selector(setNotificationDictionaries:)
						 object:[[notificationDictionaries copy] autorelease]];
	[mgr setActionName:NSLocalizedString(@"Replace All Notifications", /*comment*/ nil)];

	[notificationDictionaries setArray:array];
}

- (unsigned)countOfNotificationDictionaries {
	return [notificationDictionaries count];
}
- (GRDENotification *)objectInNotificationDictionariesAtIndex:(unsigned)idx {
	return [notificationDictionaries objectAtIndex:idx];
}
- (void)getNotificationDictionaries:(out GRDENotification **)outDicts range:(NSRange)range {
	[notificationDictionaries getObjects:outDicts range:range];
}

- (void)replaceObjectInNotificationDictionariesAtIndex:(unsigned)idx withObject:(GRDENotification *)notification {
	if([notificationNames containsObject:[notification name]]) {
		NSLog(@"Can't replace notification %u with %@", idx, notification);
		NSBeep(); //Assume that we got here by user interaction.

		NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:idx];
		[self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexSet forKey:@"notificationDictionaries"];
		[self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexSet forKey:@"notificationDictionaries"];
	} else {
		GRDENotification *oldNotification = [notificationDictionaries objectAtIndex:idx];
		[oldNotification removeObserver:self forKeyPath:@"name"];
		NSString *oldName = [oldNotification name];
		NSString *newName = [notification name];
		if(![oldName isEqualToString:newName]) {
			[notificationNames removeObject:oldName];
			[notificationNames addObject:newName];
		}

		NSUndoManager *mgr = [self undoManager];
		[[mgr prepareWithInvocationTarget:self] replaceObjectInNotificationDictionariesAtIndex:idx withObject:oldNotification];
		[mgr setActionName:NSLocalizedString(@"Replace Notification", /*comment*/ nil)];
		[notificationDictionaries replaceObjectAtIndex:idx withObject:notification];

		[notification addObserver:self
			   forKeyPath:@"name"
				  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
				  context:NULL];
	}
}
- (void)insertObject:(GRDENotification *)notification inNotificationDictionariesAtIndex:(unsigned)idx {
	NSLog(@"in insertObject: notificationNames is %@ (%u items)", notificationNames, [notificationNames count]);
	if([notificationNames containsObject:[notification name]]) {
		//We already have one of these. Pass.

		NSBeep(); //Assume that we got here by user interaction.

		NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:idx];
		//Insert.
		[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexSet forKey:@"notificationDictionaries"];
		[notificationDictionaries insertObject:notification atIndex:idx];
		[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexSet forKey:@"notificationDictionaries"];
		//And now pull it back out.
		[self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"notificationDictionaries"];
		[notificationDictionaries removeObjectAtIndex:idx];
		[self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"notificationDictionaries"];
	} else {
		NSUndoManager *mgr = [self undoManager];
		[[mgr prepareWithInvocationTarget:self] removeObjectFromNotificationDictionariesAtIndex:idx];
		[mgr setActionName:NSLocalizedString(@"Add Notification", /*comment*/ nil)];
		[notificationDictionaries insertObject:notification atIndex:idx];

		[notification addObserver:self
			   forKeyPath:@"name"
				  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
				  context:NULL];
		NSString *newName = [notification name];
		if([newName length])
			[notificationNames addObject:newName];
	}
}
- (void)removeObjectFromNotificationDictionariesAtIndex:(unsigned)idx {
	GRDENotification *oldNotification = [notificationDictionaries objectAtIndex:idx];
	[oldNotification removeObserver:self forKeyPath:@"name"];
	[notificationNames removeObject:[oldNotification name]];

	NSUndoManager *mgr = [self undoManager];
	[[mgr prepareWithInvocationTarget:self] insertObject:oldNotification inNotificationDictionariesAtIndex:idx];
	[mgr setActionName:NSLocalizedString(@"Delete Notification", /*comment*/ nil)];
	[notificationDictionaries removeObjectAtIndex:idx];
}

#pragma mark NSDocument subclass conformance

- (NSString *)windowNibName {
	return @"GRDEDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController {
	[super windowControllerDidLoadNib:windowController];

	//Get the name and bundle ID, but only keep them if they are non-empty.
	[self willChangeValueForKey:@"applicationName"];
	applicationName  = [[dictionaryRepresentation objectForKey:GROWL_APP_NAME] copy];
	if(applicationName && ![applicationName length])
		[applicationName release];
	[self  didChangeValueForKey:@"applicationName"];
	[self willChangeValueForKey:@"bundleIdentifier"];
	bundleIdentifier = [[dictionaryRepresentation objectForKey:GROWL_APP_ID] copy];
	if(bundleIdentifier && ![bundleIdentifier length])
		[bundleIdentifier release];
	[self  didChangeValueForKey:@"bundleIdentifier"];

	NSArray *allNotificationNames = [dictionaryRepresentation objectForKey:GROWL_NOTIFICATIONS_ALL];
	NSSet *enabledNotificationNames = [NSSet setWithArray:[dictionaryRepresentation objectForKey:GROWL_NOTIFICATIONS_DEFAULT]];
	NSDictionary *humanReadableNotificationNames = [dictionaryRepresentation objectForKey:GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES];
	NSDictionary *notificationDescriptions = [dictionaryRepresentation objectForKey:GROWL_NOTIFICATIONS_DESCRIPTIONS];

	[self willChangeValueForKey:@"notificationDictionaries"];
	[notificationDictionaries removeAllObjects];

	NSEnumerator *namesEnum = [allNotificationNames objectEnumerator];
	NSString *name;
	while((name = [namesEnum nextObject])) {
		GRDENotification *notification = [[GRDENotification alloc] init];
		[notification setName:name];
		[notification setEnabled:[enabledNotificationNames containsObject:name]];
		[notification setHumanReadableName:[humanReadableNotificationNames objectForKey:name]];
		[notification setHumanReadableDescription:[notificationDescriptions objectForKey:name]];
		//Setting the document must come last, so that the notification's undo registrations go to nil.
		//We don't want to register an undo group for filling in the file's data.
		[notification setDocument:self];

		[notificationDictionaries addObject:notification];
		[notification release];
	}
	[self didChangeValueForKey:@"notificationDictionaries"];

	[tableView registerForDraggedTypes:[NSArray arrayWithObjects:DRAG_TYPE, DRAG_INDICES_TYPE, DRAG_SRCDOCUMENTURL_TYPE, nil]];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
	NSArray *dicts = [arrayController arrangedObjects];
	unsigned numDicts = [dicts count];

	NSMutableArray *allNotificationNames = [NSMutableArray arrayWithCapacity:numDicts];
	NSMutableArray *enabledNotificationNames = [NSMutableArray arrayWithCapacity:numDicts];
	NSMutableDictionary *humanReadableNotificationNames = [NSMutableDictionary dictionaryWithCapacity:numDicts];
	NSMutableDictionary *notificationDescriptions = [NSMutableDictionary dictionaryWithCapacity:numDicts];

	NSEnumerator *dictsEnum = [dicts objectEnumerator];
#ifdef NOTIFICATION_DICTIONARIES
	NSDictionary *dict;
	while((dict = [dictsEnum nextObject])) {
#warning XXX need consistency checks
		NSString *name = [dict objectForKey:@"NotificationName"];
		[allNotificationNames addObject:name];
		NSNumber *enabledNum = [dict objectForKey:@"Enabled"];
		if([enabledNum boolValue])
			[enabledNotificationNames addObject:name];

		NSString *hrName = [dict objectForKey:@"HumanReadableName"];
		if(hrName)
			[humanReadableNotificationNames setObject:hrName forKey:name];
		NSString *desc = [dict objectForKey:@"Description"];
		if(desc)
			[notificationDescriptions setObject:desc forKey:name];
#else
	GRDENotification *notification;
	while((notification = [dictsEnum nextObject])) {
#warning XXX need consistency checks
		NSString *name = [notification name];
		[allNotificationNames addObject:name];
		if([notification isEnabled])
			[enabledNotificationNames addObject:name];

		NSString *hrName = [notification humanReadableName];
		if(hrName)
			[humanReadableNotificationNames setObject:hrName forKey:name];
		NSString *desc = [notification humanReadableDescription];
		if(desc)
			[notificationDescriptions setObject:desc forKey:name];
#endif
	}

	if(!dictionaryRepresentation)
		dictionaryRepresentation = [[NSMutableDictionary alloc] initWithCapacity:6U];

	if(applicationName && [applicationName length])
		[dictionaryRepresentation setObject:applicationName  forKey:GROWL_APP_NAME];
	if(bundleIdentifier && [bundleIdentifier length])
		[dictionaryRepresentation setObject:bundleIdentifier forKey:GROWL_APP_ID];
	[dictionaryRepresentation setObject:allNotificationNames           forKey:GROWL_NOTIFICATIONS_ALL];
	[dictionaryRepresentation setObject:enabledNotificationNames       forKey:GROWL_NOTIFICATIONS_DEFAULT];
	[dictionaryRepresentation setObject:humanReadableNotificationNames forKey:GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES];
	[dictionaryRepresentation setObject:notificationDescriptions       forKey:GROWL_NOTIFICATIONS_DESCRIPTIONS];

	NSString *errorString = nil;
	NSData *data = [NSPropertyListSerialization dataFromPropertyList:dictionaryRepresentation
															  format:plistFormat
													errorDescription:&errorString];
	if(errorString) {
		if(outError)
			*outError = [NSError errorWithDomain:@"NSPropertyListSerialization" code:2 userInfo:[NSDictionary dictionaryWithObject:errorString forKey:NSLocalizedFailureReasonErrorKey]];
		NSLog(@"Could not write dictionary:\n%@", dictionaryRepresentation);
	}

	return data;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
	NSString *errorString = nil;
	NSDictionary *dict = [NSPropertyListSerialization propertyListFromData:data
														  mutabilityOption:NSPropertyListImmutable
																	format:&plistFormat
														  errorDescription:&errorString];
	if(errorString) {
		if(outError)
			*outError = [NSError errorWithDomain:@"NSPropertyListSerialization" code:1 userInfo:[NSDictionary dictionaryWithObject:errorString forKey:NSLocalizedFailureReasonErrorKey]];
	}
	if(dict) {
		if(!dictionaryRepresentation)
			dictionaryRepresentation = [dict mutableCopy];
		else
			[dictionaryRepresentation setDictionary:dict];
	}

	return (dict != nil);
}

#pragma mark NSTableView drag validation (AXCArrayControllerWithDragAndDrop)

- (unsigned)removeRows:(NSArray *)indicesArray computingDeltaBeforeRow:(int)row {
	unsigned delta = 0U;

	NSEnumerator *indicesEnum = [indicesArray objectEnumerator];
	NSNumber *indexNum;
	while((indexNum = [indicesEnum nextObject])) {
		unsigned i = [indexNum unsignedIntValue];
		if(i < row)
			++delta;

		NSIndexSet *indexSet = [[NSIndexSet alloc] initWithIndex:i];
		[self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"notificationDictionaries"];
			[notificationDictionaries removeObjectAtIndex:i];
		[self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"notificationDictionaries"];
		[indexSet release];
	}
	return delta;
}

- (NSDragOperation) tableView:(NSTableView *)aTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation {
	NSPasteboard *pboard = [info draggingPasteboard];

	NSArray *notifications = [pboard propertyListForType:DRAG_TYPE];
	if(!notifications) return NSDragOperationNone;
	NSString *URLString = [pboard stringForType:DRAG_SRCDOCUMENTURL_TYPE];

	NSURL *URL;
	if(URLString) URL = [NSURL URLWithString:URLString];
	BOOL isMove = URLString && [URL isEqual:[self fileURL]];

	if(!isMove) {
		//Copying from one document to another.
		NSEnumerator *notificationsEnum = [notifications objectEnumerator];
		NSDictionary *dict;
		while((dict = [notificationsEnum nextObject])) {
			if([notificationNames containsObject:[GRDENotification notificationNameFromDictionaryRepresentation:dict]]) {
				//Notification names must be unique. Fail the drag.
				return NSDragOperationNone;
			}
		}
		return NSDragOperationCopy;
	} else {
		//Moving within the same document. This always succeeds.
		return NSDragOperationMove;
	}
}
- (BOOL) tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation {
	[arrayController commitEditing];

	NSPasteboard *pboard = [info draggingPasteboard];
	NSArray *notifications = [pboard propertyListForType:DRAG_TYPE];

	NSURL *URL = [NSURL URLWithString:[pboard stringForType:DRAG_SRCDOCUMENTURL_TYPE]];
	BOOL isMove = [URL isEqual:[self fileURL]];
	if(isMove) {
		//If the user is dragging within the same document, this is a move, and we should remove the old ones and adjust the destination index accordingly.
		//Otherwise, it's a copy, so we leave our contents and the destination index alone.
		row -= [self removeRows:[pboard propertyListForType:DRAG_INDICES_TYPE] computingDeltaBeforeRow:row];
	} else if(row < 0)
		row = [notificationDictionaries count];

	for(unsigned srcIdx = 0U, count = [notifications count]; srcIdx < count; ++srcIdx) {
		GRDENotification *notification = [[GRDENotification alloc] initWithDictionaryRepresentation:[notifications objectAtIndex:srcIdx]];

		NSIndexSet *indexSet = [[NSIndexSet alloc] initWithIndex:srcIdx];
		[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexSet forKey:@"notificationDictionaries"];
			[self insertObject:notification inNotificationDictionariesAtIndex:row++];
		[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexSet forKey:@"notificationDictionaries"];
		[indexSet release];

		[notification release];
	}

	//if(isMove) register undo as move
	//else register undo as add

	return YES;
}
- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndices toPasteboard:(NSPasteboard*)pboard {
	unsigned firstIdx = [rowIndices firstIndex], numIndices = [rowIndices count];
	NSMutableArray *notifications = [NSMutableArray arrayWithCapacity:numIndices];
	NSMutableArray *indicesArray = [NSMutableArray arrayWithCapacity:numIndices];
	
	for(unsigned i = firstIdx; i != NSNotFound; i = [rowIndices indexGreaterThanIndex:i]) {
		NSNumber *num = [[NSNumber alloc] initWithUnsignedInt:i];
		[indicesArray addObject:num];
		[num release];

		[notifications addObject:[[notificationDictionaries objectAtIndex:i] dictionaryRepresentation]];
	}

	[pboard declareTypes:[NSArray arrayWithObjects:DRAG_TYPE, DRAG_INDICES_TYPE, nil] owner:self];
	[pboard setPropertyList:notifications forType:DRAG_TYPE];
	[pboard setPropertyList:indicesArray forType:DRAG_INDICES_TYPE];
	[pboard setString:[[self fileURL] absoluteString] forType:DRAG_SRCDOCUMENTURL_TYPE];
	return YES;
}

#pragma mark KVO

//These two methods are used to revert an invalid new value.
- (void)delayedRevertValueForKeyPath:(NSDictionary *)dict {
	NSObject *obj = [dict objectForKey:@"GRDEObject"];
	NSString *keyPath = [dict objectForKey:@"GRDEKeyPath"];
	NSObject *oldValue = [dict objectForKey:NSKeyValueChangeOldKey];
	if(!oldValue)
		oldValue = nil;
	[obj setValue:oldValue forKeyPath:keyPath];
}
- (void)scheduleReversionOfValueForKeyPath:(NSString *)keyPath ofObject:(NSObject *)obj change:(NSDictionary *)change {
	NSMutableDictionary *dict = [change mutableCopy];
	[dict setObject:obj     forKey:@"GRDEObject"];
	[dict setObject:keyPath forKey:@"GRDEKeyPath"];
	[self performSelector:@selector(delayedRevertValueForKeyPath:)
			   withObject:dict
			   afterDelay:0.01];
	[dict release];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(NSObject *)obj change:(NSDictionary *)change context:(void *)context {
	NSNull *null = [NSNull null];
	NSString *old = [change objectForKey:NSKeyValueChangeOldKey];
	if(old == (NSString *)null) old = @"";
	NSString *new = [change objectForKey:NSKeyValueChangeNewKey];
	if(new == (NSString *)null) new = @"";
	NSLog(@"\n"
		  @"old: %@\n"
		  @"new: %@\n"
		  @"notificationNames: %@ (%u items)",
		  old, new, notificationNames, [notificationNames count]);

	if(![old length]) {
		//Adding a value.
		if([notificationNames containsObject:new]) 
			[self scheduleReversionOfValueForKeyPath:keyPath ofObject:obj change:change];
		else if([new length])
			[notificationNames addObject:new];
	} else if(![new length]) {
		//Removing a value.
		[notificationNames removeObject:old];
	} else if(![old isEqualToString:new]) {
		//Changing a value.
		if([notificationNames containsObject:new])
			[self scheduleReversionOfValueForKeyPath:keyPath ofObject:obj change:change];
		else {
			NSLog(@"value changed: %@ %C %@", old, 0x2192, new);
			[notificationNames addObject:new];
		}
	}
}

@end
