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

@interface GrowlMailUUIDPatcher ()

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
	for (GrowlMailWarningNote *note in self.warningNotes) {
		newHeightOfTable += [note messageHeightWithWidth:[[warningNotesTable tableColumnWithIdentifier:@"message"] width]];
	}
	if (newHeightOfTable < 1.0f)
		newHeightOfTable = 1.0f;

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
	CGFloat height = [[self.warningNotes objectAtIndex:row] messageHeightWithWidth:[[theTableView tableColumnWithIdentifier:@"message"] width]];
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
