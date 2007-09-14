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

#import "NSMutableDictionary+Intersection.h"

#define DRAG_TYPE @"org.boredzo.GrowlRegistrationDictionaryEditor.notification"
#define DRAG_INDICES_TYPE @"org.boredzo.GrowlRegistrationDictionaryEditor.notificationIndices"

#define NATIVE_DOCUMENT_TYPE @"Growl auto-registration property list"
#define NATIVE_DOCUMENT_EXTENSION GROWL_REG_DICT_EXTENSION
#define GROWL_TICKET_TYPE @"Growl saved ticket"

//Methods used as a callback to perform or revert undo.
@interface GRDEDocument (UndoMethods)

- (void) undoMoveDrop:(NSDictionary *)dict;
- (void) undoCopyDropAtIndices:(NSIndexSet *)indexSet;
- (void) redoCopyDropObjects:(NSArray *)objects atIndices:(NSIndexSet *)indexSet;

@end

@implementation GRDEDocument

- init {
	if ((self = [super init])) {
		notifications     = [[NSMutableArray alloc] init];
		notificationNames = [[NSMutableSet   alloc] init];
		plistFormat = NSPropertyListBinaryFormat_v1_0;

		selectionChangeAllowed = YES;
	}
	return self;
}
- (void)dealloc {
	[applicationName release];
	[bundleIdentifier release];
	[notifications release];
	[notificationNames        release];
	[dictionaryRepresentation release];

	[super dealloc];
}

- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel {
	BOOL success = [super prepareSavePanel:savePanel];
	if (success) {
		if (![savePanel accessoryView]) {
			//Messages don't wrap unless you use explicit newlines. This is the next best thing.
			NSTextField *textField = [[NSTextField alloc] initWithFrame:(NSRect){ { 20.0f, 100.0f }, { 384.0f, 42.0f } }];
			[textField setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];

			[textField setEditable:NO];
			[textField setSelectable:YES]; //Why would this ever be NO?

			[textField setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
			[textField setAlignment:NSCenterTextAlignment];

			[textField setDrawsBackground:NO];
			[textField setBezeled:NO];

			[textField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Note: You must name your file \"Growl Registration Ticket.%@\" for Growl to notice it on launch.  You can do this automatically with a shell script phase in Xcode.", /*comment*/ nil), NATIVE_DOCUMENT_EXTENSION]];
			[savePanel setAccessoryView:textField];
			[textField release];
		}
	}
	return success;
}

#pragma mark Actions

- (IBAction)insertNewNotification:sender {
	[arrayController commitEditing];

	unsigned idx = [arrayController selectionIndex];
	if (idx == NSNotFound)
		idx = 0U;
	else
		++idx;

	id obj = [[[arrayController objectClass] alloc] init];
	if ([obj respondsToSelector:@selector(setDocument:)])
		[obj setDocument:self];
	[arrayController insertObject:obj atArrangedObjectIndex:idx];
	[obj release];

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

- (NSMutableArray *)notifications {
	return notifications;
}
- (BOOL)validateNotifications:(inout NSArray **)newValue error:(NSError **)outError {
	NSCountedSet *set = [NSCountedSet set];

	NSEnumerator *newValueEnum = [*newValue objectEnumerator];
	GRDENotification *notification;
	while ((notification = [newValueEnum nextObject])) {
		NSString *name = [notification name];
		[set addObject:name];
		if ([set countForObject:name] > 1U) {
			//XXX Set *outError
			return NO;
		}
	}

	return YES;
}
- (void)setNotifications:(NSArray *)array {
	NSUndoManager *mgr = [self undoManager];
	[mgr registerUndoWithTarget:self
					   selector:@selector(setNotifications:)
						 object:[[notifications copy] autorelease]];
	[mgr setActionName:NSLocalizedString(@"Replace All Notifications", /*comment*/ nil)];

	[notifications setArray:array];
}

- (unsigned)countOfNotifications {
	return [notifications count];
}
- (GRDENotification *)objectInNotificationsAtIndex:(unsigned)idx {
	return [notifications objectAtIndex:idx];
}
- (void)getNotifications:(out GRDENotification **)outDicts range:(NSRange)range {
	[notifications getObjects:outDicts range:range];
}

- (void)replaceObjectInNotificationsAtIndex:(unsigned)idx withObject:(GRDENotification *)notification {
	if ([notificationNames containsObject:[notification name]]) {
		NSLog(@"Can't replace notification %u with %@", idx, notification);
		NSBeep(); //Assume that we got here by user interaction.

		NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:idx];
		[self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexSet forKey:@"notifications"];
		[self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexSet forKey:@"notifications"];
	} else {
		GRDENotification *oldNotification = [notifications objectAtIndex:idx];
		[oldNotification removeObserver:self forKeyPath:@"name"];
		NSString *oldName = [oldNotification name];
		NSString *newName = [notification name];
		if (![oldName isEqualToString:newName]) {
			[notificationNames removeObject:oldName];
			[notificationNames addObject:newName];
		}

		NSUndoManager *mgr = [self undoManager];
		[[mgr prepareWithInvocationTarget:self] replaceObjectInNotificationsAtIndex:idx withObject:oldNotification];
		[mgr setActionName:NSLocalizedString(@"Replace Notification", /*comment*/ nil)];
		[notifications replaceObjectAtIndex:idx withObject:notification];

		[notification addObserver:self
			   forKeyPath:@"name"
				  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
				  context:NULL];
	}
}
- (void)insertObject:(GRDENotification *)notification inNotificationsAtIndex:(unsigned)idx {
	if ([notificationNames containsObject:[notification name]]) {
		//We already have one of these. Pass.

		NSBeep(); //Assume that we got here by user interaction.

		NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:idx];
		//Insert.
		[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexSet forKey:@"notifications"];
		[notifications insertObject:notification atIndex:idx];
		[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexSet forKey:@"notifications"];
		//And now pull it back out.
		[self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"notifications"];
		[notifications removeObjectAtIndex:idx];
		[self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"notifications"];
	} else {
		NSUndoManager *mgr = [self undoManager];
		[[mgr prepareWithInvocationTarget:self] removeObjectFromNotificationsAtIndex:idx];
		[mgr setActionName:NSLocalizedString(@"Add Notification", /*comment*/ nil)];
		[notifications insertObject:notification atIndex:idx];

		[notification addObserver:self
			   forKeyPath:@"name"
				  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
				  context:NULL];
		NSString *newName = [notification name];
		if ([newName length])
			[notificationNames addObject:newName];
	}
}
- (void)removeObjectFromNotificationsAtIndex:(unsigned)idx {
	GRDENotification *oldNotification = [notifications objectAtIndex:idx];
	[oldNotification removeObserver:self forKeyPath:@"name"];
	[notificationNames removeObject:[oldNotification name]];

	NSUndoManager *mgr = [self undoManager];
	[[mgr prepareWithInvocationTarget:self] insertObject:oldNotification inNotificationsAtIndex:idx];
	[mgr setActionName:NSLocalizedString(@"Delete Notification", /*comment*/ nil)];
	[notifications removeObjectAtIndex:idx];
}

- (NSSet *)notificationNames {
	return [[notificationNames copy] autorelease];
}

#pragma mark Interpreting user data

- (BOOL)convertDictionaryRepresentationToNotifications:(out NSError **)outError {
	//Get the name and bundle ID, but only keep them if they are non-empty.
	[self willChangeValueForKey:@"applicationName"];
	applicationName  = [[dictionaryRepresentation objectForKey:GROWL_APP_NAME] copy];
	if (applicationName && ![applicationName length])
		[applicationName release];
	[self  didChangeValueForKey:@"applicationName"];
	[self willChangeValueForKey:@"bundleIdentifier"];
	bundleIdentifier = [[dictionaryRepresentation objectForKey:GROWL_APP_ID] copy];
	if (bundleIdentifier && ![bundleIdentifier length])
		[bundleIdentifier release];
	[self  didChangeValueForKey:@"bundleIdentifier"];

	[self willChangeValueForKey:@"notifications"];
	[notifications removeAllObjects];

	if (!wasReadFromGrowlTicket) {
		//Reading a .plist or .growlRegDict.
		NSArray *allNotificationNames = [dictionaryRepresentation objectForKey:GROWL_NOTIFICATIONS_ALL];
		NSSet *enabledNotificationNames = [NSSet setWithArray:[dictionaryRepresentation objectForKey:GROWL_NOTIFICATIONS_DEFAULT]];
		NSDictionary *humanReadableNotificationNames = [dictionaryRepresentation objectForKey:GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES];
		NSDictionary *notificationDescriptions = [dictionaryRepresentation objectForKey:GROWL_NOTIFICATIONS_DESCRIPTIONS];

		NSEnumerator *namesEnum = [allNotificationNames objectEnumerator];
		NSString *name;
		while ((name = [namesEnum nextObject])) {
			GRDENotification *notification = [[GRDENotification alloc] init];
			[notification setName:name];
			[notification setEnabled:[enabledNotificationNames containsObject:name]];
			[notification setHumanReadableName:[humanReadableNotificationNames objectForKey:name]];
			[notification setHumanReadableDescription:[notificationDescriptions objectForKey:name]];
			//Setting the document must come last, so that the notification's undo registrations go to nil.
			//We don't want to register an undo group for filling in the file's data.
			[notification setDocument:self];
			
			[notifications addObject:notification];
			[notification release];
		}
	} else {
		//Reading a .growlTicket.
		NSArray *dictionaries = [dictionaryRepresentation objectForKey:GROWL_NOTIFICATIONS_ALL];
		NSEnumerator *dictEnum = [dictionaries objectEnumerator];
		NSDictionary *dict;
		while ((dict = [dictEnum nextObject])) {
			GRDENotification *notification = [[GRDENotification alloc] init];

			[notification setName:[dict objectForKey:@"Name"]];
			[notification setEnabled:[[dict objectForKey:@"Enabled"] boolValue]];
			[notification setHumanReadableName:[dict objectForKey:@"HumanReadableName"]];
			[notification setHumanReadableDescription:[dict objectForKey:@"NotificationDescription"]];

			[notifications addObject:notification];
			[notification release];
		}
	}
	[self didChangeValueForKey:@"notifications"];

	//No error, so we must have successfully interpreted the dictionary representation.
	return YES;
}

#pragma mark NSDocument subclass conformance

- (NSString *)windowNibName {
	return @"GRDEDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController {
	[super windowControllerDidLoadNib:windowController];

	[tableView registerForDraggedTypes:[NSArray arrayWithObjects:DRAG_TYPE, DRAG_INDICES_TYPE, nil]];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
	NSArray *dicts = [arrayController arrangedObjects];
	unsigned numDicts = [dicts count];

	NSMutableArray *allNotificationNames = [NSMutableArray arrayWithCapacity:numDicts];
	NSMutableArray *enabledNotificationNames = [NSMutableArray arrayWithCapacity:numDicts];
	NSMutableDictionary *humanReadableNotificationNames = [NSMutableDictionary dictionaryWithCapacity:numDicts];
	NSMutableDictionary *notificationDescriptions = [NSMutableDictionary dictionaryWithCapacity:numDicts];

	NSEnumerator *dictsEnum = [dicts objectEnumerator];
	GRDENotification *notification;
	while ((notification = [dictsEnum nextObject])) {
#warning XXX need consistency checks
		NSString *name = [notification name];
		[allNotificationNames addObject:name];
		if ([notification isEnabled])
			[enabledNotificationNames addObject:name];

		NSString *hrName = [notification humanReadableName];
		if (hrName)
			[humanReadableNotificationNames setObject:hrName forKey:name];
		NSString *desc = [notification humanReadableDescription];
		if (desc)
			[notificationDescriptions setObject:desc forKey:name];
	}

	if (!dictionaryRepresentation)
		dictionaryRepresentation = [[NSMutableDictionary alloc] initWithCapacity:7U];

	[dictionaryRepresentation setObject:[NSNumber numberWithUnsignedInt:1U] forKey:GROWL_TICKET_VERSION];

	if (applicationName && [applicationName length])
		[dictionaryRepresentation setObject:applicationName  forKey:GROWL_APP_NAME];
	if (bundleIdentifier && [bundleIdentifier length])
		[dictionaryRepresentation setObject:bundleIdentifier forKey:GROWL_APP_ID];
	[dictionaryRepresentation setObject:allNotificationNames
								 forKey:GROWL_NOTIFICATIONS_ALL];
	//If all the notifications are enabled by default, don't bother listing them off. Omitting GROWL_NOTIFICATIONS_DEFAULT means that all notifications are enabled by default.
	if (![enabledNotificationNames isEqualToArray:allNotificationNames]) {
		[dictionaryRepresentation setObject:enabledNotificationNames
									 forKey:GROWL_NOTIFICATIONS_DEFAULT];
	}
	//If the dictionary of human-readable notification names is non-empty, put it in. Conversely, if it is empty, just leave it out.
	if (humanReadableNotificationNames && [humanReadableNotificationNames count]) {
		[dictionaryRepresentation setObject:humanReadableNotificationNames
									 forKey:GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES];
	}
	//If the dictionary of human-readable notification descriptions is non-empty, put it in. Conversely, if it is empty, just leave it out.
	if (notificationDescriptions && [notificationDescriptions count]) {
		[dictionaryRepresentation setObject:notificationDescriptions
									 forKey:GROWL_NOTIFICATIONS_DESCRIPTIONS];
	}

	NSString *errorString = nil;
	NSData *data = [NSPropertyListSerialization dataFromPropertyList:dictionaryRepresentation
															  format:plistFormat
													errorDescription:&errorString];
	if (errorString) {
		if (outError)
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
	if (errorString) {
		if (outError)
			*outError = [NSError errorWithDomain:@"NSPropertyListSerialization" code:1 userInfo:[NSDictionary dictionaryWithObject:errorString forKey:NSLocalizedFailureReasonErrorKey]];
	}
	if (dict) {
		if (!dictionaryRepresentation)
			dictionaryRepresentation = [dict mutableCopy];
		else
			[dictionaryRepresentation setDictionary:dict];

		if ([typeName isEqualToString:NATIVE_DOCUMENT_TYPE])
			wasReadFromGrowlTicket = NO;
		else {
			NSSet *ourKeys = [NSSet setWithObjects:
				GROWL_APP_NAME,
				GROWL_APP_ID,
				GROWL_NOTIFICATIONS_ALL,
				GROWL_NOTIFICATIONS_DEFAULT,
				GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES,
				GROWL_NOTIFICATIONS_DESCRIPTIONS,
				nil];
			[dictionaryRepresentation intersectWithSetOfKeys:ourKeys];

			[self setFileType:NATIVE_DOCUMENT_TYPE];
			[self updateChangeCount:NSChangeDone];

			NSString *path = [self fileName];
			if (path)
				[self setFileName:[[path stringByDeletingPathExtension] stringByAppendingPathExtension:NATIVE_DOCUMENT_EXTENSION]];

			wasReadFromGrowlTicket = [typeName isEqualToString:GROWL_TICKET_TYPE];
		}

		return [self convertDictionaryRepresentationToNotifications:outError];
	}

	return NO;
}

#pragma mark NSTableView drag validation (AXCArrayControllerWithDragAndDrop)

- (unsigned)removeRows:(NSArray *)indicesArray computingDeltaBeforeRow:(int)row {
	unsigned delta = 0U;

	NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
	NSEnumerator *indicesEnum = [indicesArray objectEnumerator];
	NSNumber *indexNum;
	while ((indexNum = [indicesEnum nextObject]))
		[indexSet addIndex:[indexNum unsignedIntValue]];

	[self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"notifications"];

	//We have to do this to compute the delta.
	indicesEnum = [indicesArray objectEnumerator];
	while ((indexNum = [indicesEnum nextObject])) {
		unsigned i = [indexNum unsignedIntValue];
		if (i < row)
			++delta;

		[notifications removeObjectAtIndex:i];
	}

	[self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"notifications"];
	return delta;
}

- (NSDragOperation) tableView:(NSTableView *)aTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation {
	NSPasteboard *pboard = [info draggingPasteboard];
	
	NSArray *draggedNotifications = [pboard propertyListForType:DRAG_TYPE];
	if (!draggedNotifications) return NSDragOperationNone;

	BOOL isMove = ([tableView window] == [[info draggingSource] window]);

	if (!isMove) {
		//Copying from one document to another.
		NSEnumerator *notificationsEnum = [draggedNotifications objectEnumerator];
		NSDictionary *dict;
		while ((dict = [notificationsEnum nextObject])) {
			if ([notificationNames containsObject:[GRDENotification notificationNameFromDictionaryRepresentation:dict]]) {
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
- (BOOL) tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation {
	[arrayController commitEditing];

	NSPasteboard *pboard = [info draggingPasteboard];
	NSArray *draggedNotifications = [pboard propertyListForType:DRAG_TYPE];

	BOOL isMove = ([tableView window] == [[info draggingSource] window]);
	if (isMove) {
		NSArray *indicesArray = [pboard propertyListForType:DRAG_INDICES_TYPE];

		//If the user is dragging within the same document, this is a move, and we should remove the old ones and adjust the destination index accordingly.
		//Otherwise, it's a copy, so we leave our contents and the destination index alone.
		row -= [self removeRows:indicesArray computingDeltaBeforeRow:row];

		NSDictionary *undoDict = [NSDictionary dictionaryWithObjectsAndKeys:
			draggedNotifications, DRAG_TYPE,
			indicesArray, DRAG_INDICES_TYPE,
			nil];
		[[self undoManager] registerUndoWithTarget:self selector:@selector(undoMoveDrop:) object:undoDict];
	} else {
		if (row < 0)
			row = [notifications count];
		NSUndoManager *undoManager = [self undoManager];
		[[undoManager prepareWithInvocationTarget:self] undoCopyDropAtIndices:[NSIndexSet indexSetWithIndexesInRange:(NSRange){ row, [draggedNotifications count] }]];
		[undoManager setActionName:NSLocalizedString(@"Add Notifications", /*comment*/ nil)];
	}

	unsigned numNotifications = [draggedNotifications count];
	NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:(NSRange){ row, numNotifications }];
	[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexSet forKey:@"notifications"];

	for (unsigned srcIdx = 0U; srcIdx < numNotifications; ++srcIdx) {
		GRDENotification *notification = [[GRDENotification alloc] initWithDictionaryRepresentation:[draggedNotifications objectAtIndex:srcIdx]];

		[notifications insertObject:notification atIndex:row++];
		[notificationNames addObject:[notification name]];

		[notification release];
	}

	[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexSet forKey:@"notifications"];
	return YES;
}
- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndices toPasteboard:(NSPasteboard*)pboard {
	unsigned firstIdx = [rowIndices firstIndex], numIndices = [rowIndices count];
	NSMutableArray *notificationsToCopy = [NSMutableArray arrayWithCapacity:numIndices];
	NSMutableArray *indicesArray = [NSMutableArray arrayWithCapacity:numIndices];
	
	for (unsigned i = firstIdx; i != NSNotFound; i = [rowIndices indexGreaterThanIndex:i]) {
		NSNumber *num = [[NSNumber alloc] initWithUnsignedInt:i];
		[indicesArray addObject:num];
		[num release];

		[notificationsToCopy addObject:[[notifications objectAtIndex:i] dictionaryRepresentation]];
	}

	[pboard declareTypes:[NSArray arrayWithObjects:DRAG_TYPE, DRAG_INDICES_TYPE, nil] owner:self];
	[pboard setPropertyList:notificationsToCopy forType:DRAG_TYPE];
	[pboard setPropertyList:indicesArray forType:DRAG_INDICES_TYPE];
	return YES;
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(NSObject *)obj change:(NSDictionary *)change context:(void *)context {
	NSNull *null = [NSNull null];
	NSString *old = [change objectForKey:NSKeyValueChangeOldKey];
	if (old == (NSString *)null) old = @"";
	NSString *new = [change objectForKey:NSKeyValueChangeNewKey];
	if (new == (NSString *)null) new = @"";

	if (![old length]) {
		//Adding a value.
		//If we already have a notification by this name, GRDENotification's implementation of KVV will refuse the value, and we'll return NO from -selectionShouldChangeInTableView: to make sure that edit focus remains on this row.
		if ([new length] && ![notificationNames containsObject:new]) {
			[notificationNames addObject:new];
			selectionChangeAllowed = YES;
		} else {
			selectionChangeAllowed = NO;
		}
	} else if (![new length]) {
		//Removing a value.
		[notificationNames removeObject:old];
	} else if (![old isEqualToString:new]) {
		//Changing a value.

		//If we already have a notification by this name, GRDENotification's implementation of KVV will refuse the value, and we'll return NO from -selectionShouldChangeInTableView: to make sure that edit focus remains on this row.
		if (![notificationNames containsObject:new]) {
			[notificationNames addObject:new];
			selectionChangeAllowed = YES;
		} else {
			selectionChangeAllowed = NO;
		}
	}
}

@end

@implementation GRDEDocument (UndoMethods)

- (void) undoMoveDrop:(NSDictionary *)dict {
	//Anybody who can come up with a better way to do this, please do.
	NSArray *draggedNotifications = [dict objectForKey:DRAG_TYPE];
	NSArray *indicesArray         = [dict objectForKey:DRAG_INDICES_TYPE];
	NSMutableArray *indicesArrayForRedo = [NSMutableArray arrayWithCapacity:[indicesArray count]];

	NSEnumerator *notificationsEnum = [draggedNotifications objectEnumerator];
	GRDENotification *notification;
	NSNumber *num;
	while ((notification = [notificationsEnum nextObject])) {
		num = [[NSNumber alloc] initWithUnsignedInt:[notifications indexOfObject:notification]];
		[indicesArrayForRedo addObject:num];
		[num release];
	}

	NSMutableDictionary *redoDict = [dict mutableCopy];
	[redoDict setObject:indicesArrayForRedo forKey:DRAG_INDICES_TYPE];
	NSUndoManager *undoManager = [self undoManager];
	[undoManager registerUndoWithTarget:self selector:@selector(undoMoveDrop:) object:redoDict];
	[undoManager setActionName:NSLocalizedString(@"Relocate Notifications", /*comment*/ nil)];

	notificationsEnum = [indicesArrayForRedo objectEnumerator];
	while ((num = [notificationsEnum nextObject])) {
		unsigned idx = [num unsignedIntValue];
		NSIndexSet *indexSet = [[NSIndexSet alloc] initWithIndex:idx];
		[self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"notifications"];
		[notifications removeObjectAtIndex:idx];
		[self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"notifications"];
		[indexSet release];
	}

	for (unsigned i = 0U, count = [draggedNotifications count]; i < count; ++i) {
		unsigned idx = [[indicesArray objectAtIndex:i] unsignedIntValue];
		NSIndexSet *indexSet = [[NSIndexSet alloc] initWithIndex:idx];
		[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexSet forKey:@"notifications"];
		[notifications insertObject:[draggedNotifications objectAtIndex:i] atIndex:idx];
		[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexSet forKey:@"notifications"];
		[indexSet release];
	}
}
- (void) undoCopyDropAtIndices:(NSIndexSet *)indexSet {
	NSArray *objects = [notifications objectsAtIndexes:indexSet];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] redoCopyDropObjects:objects atIndices:indexSet];
	[undoManager setActionName:NSLocalizedString(@"Add Notifications", /*comment*/ nil)];

	[self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"notifications"];
	[notifications removeObjectsAtIndexes:indexSet];
	[self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"notifications"];
}
- (void) redoCopyDropObjects:(NSArray *)objects atIndices:(NSIndexSet *)indexSet {
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] undoCopyDropAtIndices:indexSet];
	[undoManager setActionName:NSLocalizedString(@"Add Notifications", /*comment*/ nil)];

	[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexSet forKey:@"notifications"];
	[notifications insertObjects:objects atIndexes:indexSet];
	[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexSet forKey:@"notifications"];
}

#pragma mark NSTableView delegate conformance

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView {
	//Make sure this is the right table view. Other table views asking us about their selection means a bug is afoot.
	NSParameterAssert(aTableView == tableView);

	BOOL returnValue = selectionChangeAllowed;
	selectionChangeAllowed = YES;
	return returnValue;
}

@end
