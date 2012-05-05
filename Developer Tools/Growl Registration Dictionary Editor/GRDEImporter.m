//
//  GRDEImporter.m
//  Growl Registration Dictionary Editor
//
//  Created by Peter Hosey on 2007-10-01.
//  Copyright 2007 Peter Hosey. All rights reserved.
//

#import "GRDEImporter.h"

#import "NSString+FinderLikeSorting.h"

@interface GRDEImporter (PrivateSetterAccessors)
//These are not public properties, but we do have setter accessors for them in order to take advantage of free KVO notifications. We declare them here to suppress unknown-method warnings in the rest of the file.
- (void) setTicketPaths:(NSArray *)newTicketPaths;
- (void) setSelectedTicketIndices:(NSIndexSet *)newSelectedTicketIndices;
@end

@implementation GRDEImporter

+ (void) initialize {
	if (self == [GRDEImporter class]) {
		[self setKeys:[NSArray arrayWithObject:@"ticketPaths"] triggerChangeNotificationsForDependentKey:@"ticketApplicationNames"];
	}
}

#pragma mark Private methods

//Scan the Growl tickets folders. This method is not lazy nor does it cache.
- (NSArray *) currentListOfTicketPaths {
	NSFileManager *mgr = [NSFileManager defaultManager];
	NSArray *libraryFolders = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, /*expandTilde*/ YES);

	NSMutableArray *paths = [NSMutableArray array];

	NSEnumerator *librariesEnum = [libraryFolders objectEnumerator];
	NSString *libraryPath;
	while ((libraryPath = [librariesEnum nextObject])) {
		NSString *ticketsFolderPath = [[[libraryPath stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Growl"] stringByAppendingPathComponent:@"Tickets"];
		NSArray *filenames = [mgr directoryContentsAtPath:ticketsFolderPath];
		//If the array is nil, the most likely reason is that $LIBRARY/Application Support/Growl/Tickets does not exist. That's fine.
		if (!filenames) continue;

		NSEnumerator *filenamesEnum = [filenames objectEnumerator];
		NSString *name;
		while ((name = [filenamesEnum nextObject])) {
			//Don't add filenames that aren't actually tickets. Mostly, this is so we ignore .DS_Store.
			if ([[name pathExtension] isEqualToString:@"growlTicket"])
				[paths addObject:[ticketsFolderPath stringByAppendingPathComponent:name]];
		}
	}

	//Sort the paths by filename, the way the Finder does it.
	NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:@"lastPathComponent" ascending:YES selector:@selector(finderCompare:)];
	NSArray *sortedPaths = [paths sortedArrayUsingDescriptors:[NSArray arrayWithObject:desc]];
	[desc release];

	return sortedPaths;

	/*Note: We *could* have autoreleased the descriptor and simply jumped to sortedArrayUsingDescriptors: (return [paths sortedArrayblahblahblah]). That's a tail call, which gets us tail-call optimization.
	 *Unfortunately, TCO means omitting a stack frame, which is a pain during debugging. If the app crashes in sortedArrayUsingDescriptors:, that method would not show up in the stack trace. Take it from me: that's VERY confusing (“The next frame on the stack is -_xyzPrivateMethod, but we don't call -_xyzPrivateMethod here!”).
	 *This method is called infrequently at most, so the 0.000000000000001 seconds (made-up number) that that would gain us aren't worth it.
	 */
}

#pragma mark Birth and death

- (id) init {
	if((self = [super init])) {
		[self setTicketPaths:[self currentListOfTicketPaths]];
		[self setSelectedTicketIndices:[NSIndexSet indexSet]];

		[NSBundle loadNibNamed:@"GRDEImport" owner:self];

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(applicationDidBecomeActive:)
													 name:NSApplicationDidBecomeActiveNotification
												   object:nil];
	}
	return self;
}

- (void) awakeFromNib {
	if (importPanel) {
		[importPanel setLevel:NSModalPanelWindowLevel];
	}
	if (ticketsTableView) {
		[ticketsTableView setTarget:self];
		[ticketsTableView setDoubleAction:@selector(importSelectedTickets:)];
	}
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[ticketPaths release];
	[importPanel close];

	[super dealloc];
}

#pragma mark Accessors

- (NSArray *) ticketPaths {
	return ticketPaths;
}
- (void) setTicketPaths:(NSArray *)newTicketPaths {
	if(ticketPaths != newTicketPaths) {
		[ticketPaths release];
		ticketPaths = [newTicketPaths copy];
	}
}

- (unsigned) countOfTicketPaths {
	return [ticketPaths count];
}
- (NSString *) objectInTicketPathsAtIndex:(unsigned)idx {
	return [ticketPaths objectAtIndex:idx];
}

- (NSArray *) ticketApplicationNames {
	return [ticketPaths valueForKeyPath:@"lastPathComponent.stringByDeletingPathExtension"];
}
- (unsigned) countOfTicketApplicationNames {
	return [ticketPaths count];
}
- (NSObject *) objectInTicketApplicationNamesAtIndex:(unsigned)idx {
	return [[[ticketPaths objectAtIndex:idx] lastPathComponent] stringByDeletingPathExtension];
}

- (NSIndexSet *) selectedTicketIndices {
	return selectedTicketIndices;
}
- (void) setSelectedTicketIndices:(NSIndexSet *)newSelectedTicketIndices {
	if(selectedTicketIndices != newSelectedTicketIndices) {
		[selectedTicketIndices release];
		selectedTicketIndices = [newSelectedTicketIndices retain];
	}
}

#pragma mark User-interface validation

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item {
	/*The only thing this object validates is the menu item to summon the import panel.
	 *That menu item should be enabled whenever Growl has at least one saved ticket for us to import.
	 */
	return ([[self currentListOfTicketPaths] count] > 0U);
}

#pragma mark Automatically updating the list of tickets

- (void)applicationDidBecomeActive:(NSNotification *)notification {
	NSArray *newTicketPaths = [self currentListOfTicketPaths];

	NSSet *existingNames = [NSSet setWithArray:ticketPaths];

	NSMutableSet *oldNames = [[existingNames mutableCopy] autorelease];
	NSMutableSet *newNames = [NSMutableSet setWithArray:newTicketPaths];
	//To find existing tickets that have been deleted, we subtract the set of all current tickets (newNames) from the set of all known tickets at last check (oldNames).
	[oldNames minusSet:newNames];
	//To find tickets that have been added, we subtract the set of all known tickets at last check (existingNames) from all new tickets (newNames).
	[newNames minusSet:existingNames];

	//If any tickets have been added or deleted, update our list and empty the selection.
	//XXX Someday, perhaps, we should update the selection without deselecting surviving tickets.
	//(Strangely enough, though, as of Mac OS X 10.4.10, it seems to do the Right Thing despite my explicit orders otherwise. Hm. —boredzo)
	if ([oldNames count] || [newNames count]) {
		[self setTicketPaths:newTicketPaths];
		[self setSelectedTicketIndices:[NSIndexSet indexSet]];
	}
}

#pragma mark Actions

- (IBAction) orderFrontImportPanel:(id)sender {
	//First, make sure our array of ticket paths is up-to-date.
	[self setTicketPaths:[self currentListOfTicketPaths]];
	//While we're at it, empty our selection.
	[self setSelectedTicketIndices:[NSIndexSet indexSet]];

	//Now, really bring forth the panel.
	[importPanel makeKeyAndOrderFront:sender];
}

- (IBAction) importSelectedTickets:(id)sender {
	NSDocumentController *docController = [NSDocumentController sharedDocumentController];

	for (unsigned idx = [selectedTicketIndices firstIndex]; idx <= [selectedTicketIndices lastIndex]; idx = [selectedTicketIndices indexGreaterThanIndex:idx]) {
		NSString *path = [ticketPaths objectAtIndex:idx];
		NSError *error = nil;

		//COMPAT 10.4: Tiger's NSDocumentController doesn't return a useful NSError when the file doesn't exist. It should return NSFileReadNoSuchFileError; instead, it returns NSFileReadUnknownError. Thus, we must check for file-not-found errors ourselves.
		BOOL isDir;
		BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
		if (!exists) {
			error = [NSError errorWithDomain:NSCocoaErrorDomain
										code:NSFileReadNoSuchFileError
									userInfo:[NSDictionary dictionaryWithObject:path forKey:NSFilePathErrorKey]];
		} else if (isDir) {
			error = [NSError errorWithDomain:NSCocoaErrorDomain
										code:NSFileReadCorruptFileError //Close enough…
									userInfo:[NSDictionary dictionaryWithObject:path forKey:NSFilePathErrorKey]];
		} else {
			NSDocument *doc = [docController openDocumentWithContentsOfURL:[NSURL fileURLWithPath:path]
																   display:YES
																	 error:&error];
			[[[[doc windowControllers] objectAtIndex:0U] window] makeKeyAndOrderFront:nil];
		}

		if (error) {
			[importPanel presentError:error
					   modalForWindow:importPanel
							 delegate:self
				   didPresentSelector:@selector(didPresentErrorWithRecovery:contextInfo:)
						  contextInfo:NULL];
			[NSApp runModalForWindow:[importPanel attachedSheet]];
		}
	}

	//We're done, so hide the panel.
	[importPanel orderOut:nil];
}
- (void)didPresentErrorWithRecovery:(BOOL)didRecover contextInfo:(void *)contextInfo {
	//For some reason, when the error sheet finishes, Cocoa activates the frontmost document window. This reactivates the importer panel.
	if ([importPanel isVisible])
		[importPanel performSelector:@selector(makeKeyAndOrderFront:)
						  withObject:nil
						  afterDelay:0.01];
	[NSApp stopModal];
}

@end
