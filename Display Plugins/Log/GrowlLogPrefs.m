//
//  GrowlLogPrefs.m
//  Growl
//
//  Created by Olivier Bonnet on 13/12/04.
//  Copyright 2004 Olivier Bonnet. All rights reserved.
//

#import "GrowlLogPrefs.h"
#import "GrowlLogDefines.h"
#import "GrowlDefines.h"

@implementation GrowlLogPrefs
- (NSString *) mainNibName
{
	return @"GrowlLogPrefs";
}

- (void) dealloc
{
	[customHistArray release];
	[super dealloc];
}

- (void) awakeFromNib
{
	int		typePref = 0;
	NSString	*s = nil;
	customHistArray = [[NSMutableArray alloc] init];
	READ_GROWL_PREF_VALUE(customHistKey1, LogPrefDomain, NSString * , &s);
//	NSLog(@"hist1 = %@", s);
	if (s) {
		[customHistArray addObject:s];
		//NSLog(@"hist1 = %@", s);
	}
	READ_GROWL_PREF_VALUE(customHistKey2, LogPrefDomain, NSString *, &s);
	if (s) {
		[customHistArray addObject:s];
		//NSLog(@"hist2 = %@", s);
	}
	READ_GROWL_PREF_VALUE(customHistKey3, LogPrefDomain, NSString *, &s);
	if (s) {
		[customHistArray addObject:s];
		//NSLog(@"hist3 = %@", s);
	}
	
	[self updatePopupMenu];
		
	READ_GROWL_PREF_INT(logTypeKey, LogPrefDomain, &typePref);
	[fileType selectCellAtRow:typePref column:0];
	[customMenuButton setEnabled:(typePref != 0)];
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
			NSSavePanel *sp;
			int runResult;
			sp = [NSSavePanel savePanel];
			[sp setRequiredFileType:@"log"];
			NSString *saveFilename = [sp filename];
			runResult = [sp runModalForDirectory:NSHomeDirectory() file:@""];
			if (runResult == NSOKButton) {
				int index = NSNotFound;
				for(unsigned i = 0U, max = [customHistArray count]; i < max; i++) {
					if([[customHistArray objectAtIndex:i] isEqual:saveFilename])
						index = i;
				}
				if (index == NSNotFound) {
					if ([customHistArray count] == 3U)
						[customHistArray removeLastObject];
				} else {
					[customHistArray removeObjectAtIndex:index];
				}	
				[customHistArray insertObject:[NSString stringWithString:saveFilename] atIndex:0U];
			}
		} else {
			NSString *temp = [[customHistArray objectAtIndex:selected] retain];
			[customHistArray removeObjectAtIndex:selected];
			[customHistArray insertObject:temp atIndex:0U];
			[temp release];
		}
		
		NSString *s;
		unsigned numHistItems = [customHistArray count];
		//NSLog(@"CustomHistArray = %@", customHistArray);
		if (numHistItems) {		
			s = [customHistArray objectAtIndex:0U];
			WRITE_GROWL_PREF_VALUE(customHistKey1, s, LogPrefDomain);
			//NSLog(@"Writing %@ as hist1", s);

			if((numHistItems > 1) && (s = [customHistArray objectAtIndex:1U])) {
				WRITE_GROWL_PREF_VALUE(customHistKey2, s, LogPrefDomain);
				//NSLog(@"Writing %@ as hist2", s);
			}
			
			if((numHistItems > 2) && (s = [customHistArray objectAtIndex:2U])) {
				WRITE_GROWL_PREF_VALUE(customHistKey3, s, LogPrefDomain);
				//NSLog(@"Writing %@ as hist3", s);
			}
		}
		
		SYNCHRONIZE_GROWL_PREFS();
		UPDATE_GROWL_PREFS();

		[self updatePopupMenu];
	}
}

- (void) updatePopupMenu {
	[customMenuButton removeAllItems];

	unsigned numHistItems = [customHistArray count];
	for(unsigned i = 0U; i < numHistItems; i++) {
		NSArray *pathComponentry = [[[customHistArray objectAtIndex:i] stringByAbbreviatingWithTildeInPath] pathComponents];
		unsigned numPathComponents = [pathComponentry count];
		if(numPathComponents > 2) {
			NSMutableString *arg = [[NSMutableString alloc] init];
			unichar ellipsis = 0x2026;
			[arg setString:[NSMutableString stringWithCharacters:&ellipsis length:1]];
			[arg appendString:@"/"];
			[arg appendString:[pathComponentry objectAtIndex:(numPathComponents - 2)]];
			[arg appendString:@"/"];
			[arg appendString:[pathComponentry objectAtIndex:(numPathComponents - 1)]];
			[customMenuButton insertItemWithTitle:arg atIndex:i];
		} else {
			[customMenuButton insertItemWithTitle:[[customHistArray objectAtIndex:i] stringByAbbreviatingWithTildeInPath] atIndex:i];
		}
	}
	[[customMenuButton menu] addItem:[NSMenuItem separatorItem]];
	[customMenuButton addItemWithTitle:NSLocalizedStringFromTableInBundle(@"Browse menu item title", /*tableName*/ nil, [self bundle], /*comment*/ nil)];
	[customMenuButton selectItemAtIndex:numHistItems ? 0 : -1];

}

- (void) didSelect {
	SYNCHRONIZE_GROWL_PREFS();
}

@end
