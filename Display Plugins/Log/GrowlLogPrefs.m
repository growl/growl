//
//  GrowlLogPrefs.m
//  Growl
//
//  Created by Olivier Bonnet on 13/12/04.
//  Copyright 2004 Olivier Bonnet. All rights reserved.
//

#import "GrowlLogPrefs.h"
#import "GrowlLogDefines.h"
#import "GrowlDefinesInternal.h"

@implementation GrowlLogPrefs

- (NSString *) mainNibName {
	return @"GrowlLogPrefs";
}

- (void) dealloc {
	[customHistArray release];
	[super dealloc];
}

- (void) awakeFromNib {
	int         typePref = 0;
	NSString   *s;
	customHistArray = [[NSMutableArray alloc] init];

	s = nil;
	READ_GROWL_PREF_VALUE(customHistKey1, LogPrefDomain, NSString * , &s);
//	NSLog(@"hist1 = %@", s);
	if (s) {
		[customHistArray addObject:s];
		//NSLog(@"hist1 = %@", s);
	}

	s = nil;
	READ_GROWL_PREF_VALUE(customHistKey2, LogPrefDomain, NSString *, &s);
	if (s) {
		[customHistArray addObject:s];
		//NSLog(@"hist2 = %@", s);
	}

	s = nil;
	READ_GROWL_PREF_VALUE(customHistKey3, LogPrefDomain, NSString *, &s);
	if (s) {
		[customHistArray addObject:s];
		//NSLog(@"hist3 = %@", s);
	}

	[self updatePopupMenu];

	unsigned numHistItems = [customHistArray count];
	if (numHistItems) {
		//there is at least one regular file to log to - find out whether to log to one of them
		READ_GROWL_PREF_INT(logTypeKey, LogPrefDomain, &typePref);
	} else {
		//disable the 'Log to file' radio button if there are no files to log to
		[[fileType cellAtRow:1 column:0] setEnabled:NO];
	}
	[fileType selectCellAtRow:typePref column:0];
}

- (IBAction) typeChanged:(id)sender {
	int		typePref;

	if (sender == fileType) {
		typePref = [fileType selectedRow];
		WRITE_GROWL_PREF_INT(logTypeKey, typePref, LogPrefDomain);
		[customMenuButton setEnabled:(typePref != 0)];
		UPDATE_GROWL_PREFS();
	}
}

- (IBAction) openConsoleApp:(id)sender {
	[[NSWorkspace sharedWorkspace] launchApplication:@"Console"];
}


- (IBAction) customFileChosen:(id)sender {
	if (sender == customMenuButton) {
		int selected = [customMenuButton indexOfSelectedItem];
		//NSLog(@"custom %d", selected);
		if (selected == [customMenuButton numberOfItems] - 1) {
			NSSavePanel *sp = [NSSavePanel savePanel];
			[sp setRequiredFileType:@"log"];
			[sp setCanSelectHiddenExtension:YES];

			int runResult = [sp runModalForDirectory:nil file:@""];
			NSString *saveFilename = [sp filename];
			if (runResult == NSOKButton) {
				unsigned saveFilenameIndex = NSNotFound;
				unsigned                 i = [customHistArray count];
				if (i) {
					while (--i) {
						if ([[customHistArray objectAtIndex:i] isEqual:saveFilename]) {
							saveFilenameIndex = i;
							break;
						}
					}
				}
				if (saveFilenameIndex == NSNotFound) {
					if ([customHistArray count] == 3U)
						[customHistArray removeLastObject];
				} else {
					[customHistArray removeObjectAtIndex:saveFilenameIndex];
				}
				[customHistArray insertObject:[NSString stringWithString:saveFilename] atIndex:0U];
			}
		} else {
			NSString *temp = [[customHistArray objectAtIndex:selected] retain];
			[customHistArray removeObjectAtIndex:selected];
			[customHistArray insertObject:temp atIndex:0U];
			[temp release];
		}

		unsigned numHistItems = [customHistArray count];
		//NSLog(@"CustomHistArray = %@", customHistArray);
		if (numHistItems) {
			NSString *s = [customHistArray objectAtIndex:0U];
			WRITE_GROWL_PREF_VALUE(customHistKey1, s, LogPrefDomain);
			//NSLog(@"Writing %@ as hist1", s);

			if ((numHistItems > 1) && (s = [customHistArray objectAtIndex:1U])) {
				WRITE_GROWL_PREF_VALUE(customHistKey2, s, LogPrefDomain);
				//NSLog(@"Writing %@ as hist2", s);
			}

			if ((numHistItems > 2) && (s = [customHistArray objectAtIndex:2U])) {
				WRITE_GROWL_PREF_VALUE(customHistKey3, s, LogPrefDomain);
				//NSLog(@"Writing %@ as hist3", s);
			}

			/*in case there weren't any files listed before (which means we
			 *	disabled the 'Log to file' button), enable the 'Log to file' button.
			 */
			[[fileType cellAtRow:1 column:0] setEnabled:YES];
			[fileType selectCellAtRow:1 column:0];
		}

		UPDATE_GROWL_PREFS();

		[self updatePopupMenu];
	}
}

- (void) updatePopupMenu {
	[customMenuButton removeAllItems];

	unsigned numHistItems = [customHistArray count];
	for (unsigned i = 0U; i < numHistItems; i++) {
		NSArray *pathComponentry = [[[customHistArray objectAtIndex:i] stringByAbbreviatingWithTildeInPath] pathComponents];
		unsigned numPathComponents = [pathComponentry count];
		if (numPathComponents > 2U) {
			unichar ellipsis = 0x2026;
			NSMutableString *arg = [[NSMutableString alloc] initWithCharacters:&ellipsis length:1U];
			[arg appendString:@"/"];
			[arg appendString:[pathComponentry objectAtIndex:(numPathComponents - 2U)]];
			[arg appendString:@"/"];
			[arg appendString:[pathComponentry objectAtIndex:(numPathComponents - 1U)]];
			[customMenuButton insertItemWithTitle:arg atIndex:i];
			[arg release];
		} else {
			[customMenuButton insertItemWithTitle:[[customHistArray objectAtIndex:i] stringByAbbreviatingWithTildeInPath] atIndex:i];
		}
	}
	[[customMenuButton menu] addItem:[NSMenuItem separatorItem]];
	[customMenuButton addItemWithTitle:NSLocalizedStringFromTableInBundle(@"Browse menu item title", /*tableName*/ nil, [self bundle], /*comment*/ nil)];
	//select first item, if any
	[customMenuButton selectItemAtIndex:numHistItems ? 0 : -1];
}

- (void) didSelect {
	SYNCHRONIZE_GROWL_PREFS();
}

@end
