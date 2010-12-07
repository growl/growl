//
//  GrowlMailUUIDPatcher.h
//  GrowlMailUUIDPatcher
//
//  Copyright 2010 The Growl Project. All rights reserved.
//

@class GrowlMailFoundBundle;

@interface GrowlMailUUIDPatcher : NSObject {
	NSMutableArray *growlMailFoundBundles;
	NSWindow *window;
	NSTableView *warningNotesTable;
	NSPanel *confirmationSheet;
	NSIndexSet *selectedBundleIndexes;

	NSMutableArray /*of NSStrings*/ *warningNotes;

	NSString *mailUUID, *messageFrameworkUUID;
	NSString *currentVersionOfGrowlMail; //Current as in latest. Retrieved from website.
}

@property(nonatomic, readonly) BOOL multipleGrowlMailsInstalled;
@property(nonatomic, copy) NSArray *growlMailFoundBundles;
@property(nonatomic, copy) NSIndexSet *selectedBundleIndexes;
@property(nonatomic, readonly) BOOL canAndShouldPatchSelectedBundle;

@property(nonatomic, copy) NSArray *warningNotes;

@property(nonatomic, retain) IBOutlet NSWindow *window;
@property(nonatomic, retain) IBOutlet NSTableView *warningNotesTable;
@property(nonatomic, retain) IBOutlet NSPanel *confirmationSheet;
@property(nonatomic, readonly) NSIndexSet *selectionIndexesOfWarningNotes;

- (IBAction) patchSelectedBundle:(id)sender;

@end
