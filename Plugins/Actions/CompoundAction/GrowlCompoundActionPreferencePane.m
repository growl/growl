//
//  GrowlCompoundActionPreferencePane.m
//  Growl
//
//  Created by Daniel Siemer on 3/7/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlCompoundActionPreferencePane.h"

@interface GrowlCompoundActionPreferencePane ()

@property (nonatomic, retain) NSString *actionsColumnTitle;

@end

@implementation GrowlCompoundActionPreferencePane

@synthesize chosenArrayController;
@synthesize availableArrayController;
@synthesize addWindow;

@synthesize actionsColumnTitle;

-(id)initWithBundle:(NSBundle *)bundle {
	if((self = [super initWithBundle:bundle])){
		self.actionsColumnTitle = NSLocalizedString(@"Actions:", @"Actions column title");
	}
	return self;
}

-(void)dealloc {
	self.actionsColumnTitle = nil;
	[super dealloc];
}

-(NSString*)mainNibName {
	return @"CompoundActionPrefs";
}

-(IBAction)showAddView:(id)sender {
	[[NSApplication sharedApplication] beginSheet:addWindow
											 modalForWindow:[sender window]
											  modalDelegate:self
											 didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
												 contextInfo:nil];
}

-(IBAction)addActions:(id)sender {
	[NSApp endSheet:addWindow returnCode:0];
	[addWindow orderOut:self];
}

-(IBAction)cancelActions:(id)sender {
	[NSApp endSheet:addWindow returnCode:1];
	[addWindow orderOut:self];
}
	 
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	if(returnCode == 0){
		NSArray *selectedObjetcs = [availableArrayController selectedObjects];
		//NSLog(@"selected objects: %@", [selectedObjetcs valueForKey:@"displayName"]);
		if(selectedObjetcs && [selectedObjetcs count] > 0 &&  [[self valueForKey:@"pluginConfiguration"] respondsToSelector:@selector(addActions:)])
			[[self valueForKey:@"pluginConfiguration"] performSelector:@selector(addActions:) withObject:[NSSet setWithArray:selectedObjetcs]];
	}
}
@end
