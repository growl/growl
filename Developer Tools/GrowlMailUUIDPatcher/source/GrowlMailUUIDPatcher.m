//
//  GrowlMailUUIDPatcher.m
//  GrowlMailUUIDPatcher
//
//  Copyright 2010 The Growl Project. All rights reserved.
//

#import "GrowlMailUUIDPatcher.h"

#import "GrowlMailFoundBundle.h"
#import "GrowlMailWarningNote.h"

#include "GrowlVersionUtilities.h"

@interface GrowlMailUUIDPatcher () <NSTableViewDelegate>

//Returns the selected bundle or nil if none is selected.
- (GrowlMailFoundBundle *) selectedBundle;

- (void) recomputeSelectedBundleNotes;

@end

//This is due to be replaced by an appcast, as soon as we work out how we want to do that.
static NSString *const hardCodedGrowlMailCurrentVersionNumber = @"1.2.2";

@implementation GrowlMailUUIDPatcher

+ (NSSet *) keyPathsForValuesAffectingMultipleGrowlMailsInstalled {
	return [NSSet setWithObject:@"growlMailFoundBundles"];
}

+ (NSSet *) keyPathsForValuesAffectingCanAndShouldPatchSelectedBundle {
	return [NSSet setWithObject:@"selectedBundleIndexes"];
}

- (id) init {
	if ((self = [super init])) {
		growlMailFoundBundles = [[NSMutableArray alloc] init];

		NSArray *libraryFolders = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
		for (NSString *libraryPath in libraryFolders) {
			NSString *mailFolderPath = [libraryPath stringByAppendingPathComponent:@"Mail"];
			NSString *bundlesFolderPath = [mailFolderPath stringByAppendingPathComponent:@"Bundles"];
			NSString *growlMailBundlePath = [bundlesFolderPath stringByAppendingPathComponent:@"GrowlMail.mailbundle"];

			NSURL *growlMailBundleURL = [NSURL fileURLWithPath:growlMailBundlePath];
			if ([growlMailBundleURL checkResourceIsReachableAndReturnError:NULL]) {
				[growlMailFoundBundles addObject:[GrowlMailFoundBundle foundBundleWithURL:growlMailBundleURL]];
			}
		}

		if ([growlMailFoundBundles count] > 0UL) {
			selectedBundleIndexes = [[NSIndexSet indexSetWithIndex:0UL] copy];
		} else {
			selectedBundleIndexes = [[NSIndexSet indexSet] copy];
		}

		NSBundle *mailAppBundle = [NSBundle bundleWithPath:@"/Applications/Mail.app"];
		NSBundle *messageFrameworkBundle = [NSBundle bundleWithPath:@"/System/Library/Frameworks/Message.framework"];
		mailUUID = [[mailAppBundle objectForInfoDictionaryKey:@"PluginCompatibilityUUID"] copy];
		messageFrameworkUUID = [[messageFrameworkBundle objectForInfoDictionaryKey:@"PluginCompatibilityUUID"] copy];

		currentVersionOfGrowlMail = [hardCodedGrowlMailCurrentVersionNumber copy];

		[NSBundle loadNibNamed:@"GrowlMailBundles" owner:self];
		
		[self recomputeSelectedBundleNotes];
		[warningNotesTable selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
	}
	return self;
}

- (void) dealloc {
	[confirmationSheet close];
	[confirmationSheet release];
	[window close];
	[window release];

	[growlMailFoundBundles release];

	[mailUUID release];
	[messageFrameworkUUID release];

	[super dealloc];
}

- (BOOL) multipleGrowlMailsInstalled {
	return [growlMailFoundBundles count] > 1UL;
}

@synthesize growlMailFoundBundles;
- (void) setGrowlMailFoundBundles:(NSArray *)newBundles {
	[growlMailFoundBundles setArray:newBundles];
}

@synthesize selectedBundleIndexes;
- (void) setSelectedBundleIndexes:(NSIndexSet *)newIndexes {
	[selectedBundleIndexes autorelease];
	selectedBundleIndexes = [newIndexes copy];

	[self recomputeSelectedBundleNotes];
}

- (BOOL) canAndShouldPatchSelectedBundle {
	return [self.warningNotes valueForKeyPath:@"@sum.fatal"] == 0UL;
}

@synthesize warningNotes;

- (void) recomputeSelectedBundleNotes {
	GrowlMailFoundBundle *selectedBundle = self.selectedBundle;
	NSMutableArray *newNotes = [NSMutableArray array];

	if ([self.growlMailFoundBundles count] > 1UL) {
		[newNotes addObject:[GrowlMailWarningNote warningNoteForMultipleGrowlMailsWithCurrentVersion:currentVersionOfGrowlMail]];
	}
	if (selectedBundle) {
		if (compareVersionStrings(selectedBundle.bundleVersion, currentVersionOfGrowlMail) == kCFCompareLessThan) {
			[newNotes addObject:[GrowlMailWarningNote warningNoteForGrowlMailOlderThanCurrentVersion:currentVersionOfGrowlMail]];
		}
		if (selectedBundle.domain != NSUserDomainMask) {
			[newNotes addObject:[GrowlMailWarningNote warningNoteForGrowlMailInTheWrongPlace]];
		}
	}

	self.warningNotes = newNotes;

	//Recompute window size.
	NSView *scrollView = [warningNotesTable superview];
	NSRect tableFrameInWindowSpace = [scrollView convertRect:[scrollView bounds] toView:nil];
	NSRect windowFrame = [window frame];
	CGFloat heightOfWindow = windowFrame.size.height;
	CGFloat heightBelow = NSMinY(tableFrameInWindowSpace);
	CGFloat heightAbove = heightOfWindow - NSMaxY(tableFrameInWindowSpace);

	CGFloat newHeightOfTable = 0.0f;
	for (NSUInteger i = 0UL, numNotes = [warningNotes count]; i < numNotes; ++i) {
		newHeightOfTable += [self tableView:warningNotesTable heightOfRow:i];
	}
	if (newHeightOfTable < 1.0f)
		newHeightOfTable = 1.0f;
	else {
		//Icky fudge factor to avoid the descent of the last line of the last row being cut off in some cases.
		newHeightOfTable += 4.0f;
	}

	CGFloat newHeightOfWindow = heightAbove + newHeightOfTable + heightBelow;
	CGFloat windowTop = windowFrame.origin.y + windowFrame.size.height;
	windowFrame.size.height = newHeightOfWindow;
	windowFrame.origin.y = windowTop - newHeightOfWindow;
	[window setFrame:windowFrame display:YES animate:YES];
}

- (GrowlMailFoundBundle *) selectedBundle {
	return ([self.selectedBundleIndexes count] == 1UL)
		? [self.growlMailFoundBundles objectAtIndex:[self.selectedBundleIndexes firstIndex]]
		: nil;
}

@synthesize window;
@synthesize warningNotesTable;
@synthesize confirmationSheet;

//Ensure that the warning notes table never has a selection.
- (NSIndexSet *) selectionIndexesOfWarningNotes {
	return [NSIndexSet indexSet];
}
- (void) setSelectionIndexesOfWarningNotes:(NSIndexSet *)newIndexes {
	//Do nothing, successfully.
	//The only reason this is here is because NSArrayController hates being bound to this property if there's no setter.
}

- (IBAction) patchSelectedBundle:(id)sender {
	[NSApp beginSheetModalForWindow:window completionHandler:^(NSInteger returnCode) {
		if (returnCode == NSOKButton) {
			NSURL *bundleURL = self.selectedBundle.URL;
			NSURL *infoDictURL = [[bundleURL URLByAppendingPathComponent:@"Contents"] URLByAppendingPathComponent:@"Info.plist"];

			NSInputStream *inStream = [NSInputStream inputStreamWithURL:infoDictURL];
			NSError *error = nil;
			NSPropertyListFormat format = 0;
			[inStream open];
			NSMutableDictionary *dict = [NSPropertyListSerialization propertyListWithStream:inStream
																					options:NSPropertyListMutableContainers
																					 format:&format
																					  error:&error];
			[inStream close];
			if (!dict) {
				[window presentError:error];
			} else {
				NSMutableArray *UUIDs = [dict objectForKey:@"SupportedPluginCompatibilityUUIDs"];
				if (![UUIDs containsObject:mailUUID])
					[UUIDs addObject:mailUUID];
				if (![UUIDs containsObject:messageFrameworkUUID])
					[UUIDs addObject:messageFrameworkUUID];

				NSData *data = [NSPropertyListSerialization dataWithPropertyList:dict
																		  format:format
																		 options:0
																		   error:&error];
				if (!data) {
					[window presentError:error];
				} else {
					BOOL wrote = [data writeToURL:infoDictURL
										  options:NSDataWritingAtomic
											error:&error];
					if (!wrote) {
						[window presentError:error];
					}
				}
			}
		}
	}]; //beginSheet:completionHandler:
}

#pragma mark NSTableViewDelegate protocol conformance

- (CGFloat) tableView:(NSTableView *)theTableView heightOfRow:(NSInteger)row {
	CGFloat height = [warningNotesTable rowHeight];
	/*This code is adapted from an Apple code sample:
	 *	http://developer.apple.com/mac/library/samplecode/CocoaTipsAndTricks/Listings/TableViewVariableRowHeights_TableViewVariableRowHeightsAppDelegate_m.html
	 *It is more reliable than measuring the text directly. Thanks to Jesper for telling me about it. -PRH
	 */ {
		// It is important to use a constant value when calculating the height. Querying the tableColumn width will not work, since it dynamically changes as the user resizes -- however, we don't get a notification that the user "did resize" it until after the mouse is let go. We use the latter as a hook for telling the table that the heights changed. We must return the same height from this method every time, until we tell the table the heights have changed. Not doing so will quicly cause drawing problems.
		NSString *tableColumnIdentifier = @"message";
		NSTableColumn *tableColumnToWrap = [warningNotesTable tableColumnWithIdentifier:tableColumnIdentifier];
		NSInteger columnToWrap = [warningNotesTable.tableColumns indexOfObject:tableColumnToWrap];

		// Grab the fully prepared cell with our content filled in. Note that in IB the cell's Layout is set to Wraps.
		NSCell *cell = [warningNotesTable preparedCellAtColumn:columnToWrap row:row];

		// See how tall it naturally would want to be if given a restricted with, but unbound height
		NSRect constrainedBounds = NSMakeRect(0, 0, [[warningNotesTable tableColumnWithIdentifier:tableColumnIdentifier] width], CGFLOAT_MAX);
		NSSize naturalSize = [cell cellSizeForBounds:constrainedBounds];

		// Make sure we have a minimum height -- use the table's set height as the minimum.
		if (naturalSize.height > height) {
			height = naturalSize.height;
		}
	}
	
	CGFloat iconColumnWidth = [[theTableView tableColumnWithIdentifier:@"fatality"] width];
	if (height < iconColumnWidth)
		height = iconColumnWidth;
	return height;
}

- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes {
	//Never allow any selection.
	return [NSIndexSet indexSet];
}

@end
