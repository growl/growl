//
//  GRDEAppDelegate.m
//  Growl Registration Dictionary Editor
//
//  Created by Peter Hosey on 2007-09-24.
//  Copyright 2007 Peter Hosey. All rights reserved.
//

#import "GRDEAppDelegate.h"

#import "GRDEDocument.h"
#import "NSString+FinderLikeSorting.h"

@implementation GRDEAppDelegate

- (void)awakeFromNib {
	if (!menuItemToInsertWriteCodeSampleToPasteboardMenuItemsAfter) {
		//The entire point of this method is to insert menu items, so if we have nowhere to insert them, bail without doing any work.
		return;
	}

	NSBundle *mainBundle = [NSBundle mainBundle];
	NSString *codeSamplesFolder = [[mainBundle resourcePath] stringByAppendingPathComponent:GRDE_NOTIFY_CODESAMPLE_DIRECTORY];
	//Here, we rely on the fact that NSBundle considers a plain directory to be a valid bundle. This is likely to stick around because the iPhone's OS X uses plain folders as bundles, although this behavior predates the iPhone by a long way.
	NSArray *notifyCodeSampleFilePaths = [NSBundle pathsForResourcesOfType:GRDE_CODESAMPLE_FILENAME_EXTENSION
	                                                           inDirectory:codeSamplesFolder];
	notifyCodeSampleFilePaths = [[notifyCodeSampleFilePaths sortedArrayUsingFunction:sortFilenamesLikeFinder context:NULL] retain];
	
	NSMenu *menu = [menuItemToInsertWriteCodeSampleToPasteboardMenuItemsAfter menu];
	unsigned insertionIndex = [menu indexOfItem:menuItemToInsertWriteCodeSampleToPasteboardMenuItemsAfter] + 1U;
	NSString *menuItemTitleFormat = NSLocalizedString(@"Copy Notify Code for %@", /*comment*/ @"Title of the menu item to copy a program statement to post the selected notification. This is a format; first argument is the name of the programming language.");

	//We iterate the code-sample files backward, so that we don't have to increment the insertion index. Using the same index each time effectively reverses the order of the languages, which puts them back into ascending order.
	NSEnumerator *codeSampleFilesEnum = [notifyCodeSampleFilePaths reverseObjectEnumerator];
	NSString *path;
	while ((path = [codeSampleFilesEnum nextObject])) {
		NSString *programmingLanguageName = [[path lastPathComponent] stringByDeletingPathExtension];

		NSMenuItem *menuItem = [menu insertItemWithTitle:[NSString stringWithFormat:menuItemTitleFormat, programmingLanguageName]
												  action:@selector(writeNotifyStatementToPasteboard:)
										   keyEquivalent:@""
												 atIndex:insertionIndex];
		[menuItem setRepresentedObject:path];
	}
}

@end
