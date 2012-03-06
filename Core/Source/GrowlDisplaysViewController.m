//
//  GrowlDisplaysViewController.m
//  Growl
//
//  Created by Daniel Siemer on 11/10/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlDisplaysViewController.h"

#import <GrowlPlugins/GrowlPluginPreferencePane.h>

#import <GrowlPlugins/GrowlPlugin.h>
#import "GroupController.h"
#import "GrowlPluginController.h"
#import "GrowlTicketDatabase.h"
#import "GrowlTicketDatabasePlugin.h"
#import "GrowlTicketDatabaseAction.h"
#import "GrowlTicketDatabaseDisplay.h"

@interface GrowlPluginTypeLabelTransformer : NSValueTransformer

@end

@implementation GrowlPluginTypeLabelTransformer

+ (void)load
{
   if (self == [GrowlPluginTypeLabelTransformer class]) {
      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
      [self setValueTransformer:[[[self alloc] init] autorelease]
                        forName:@"GrowlPluginTypeLabelTransformer"];
      [pool release];
   }
}

+ (Class)transformedValueClass 
{ 
   return [NSString class];
}
+ (BOOL)allowsReverseTransformation
{
   return NO;
}
- (id)transformedValue:(id)value
{
   if([value caseInsensitiveCompare:@"GrowlAction"] == NSOrderedSame)
		return NSLocalizedString(@"Actions", @"Title for section containing actions (SMS, MailMe, Speech, etc)");
	else if([value caseInsensitiveCompare:@"GrowlDisplay"] == NSOrderedSame)
		return NSLocalizedString(@"Displays", @"Title for section containing displays (Smoke, Whiteboard, Bezel, etc)");
	else if([value caseInsensitiveCompare:@"GrowlCompoundAction"] == NSOrderedSame)
		return NSLocalizedString(@"Compound", @"Title for section containing compound actions (composed of multiple actions)");
	else
		return value;
}

@end

@interface GrowlPluginNameTransformer : NSValueTransformer

@end

@implementation GrowlPluginNameTransformer

+ (void)load
{
   if (self == [GrowlPluginNameTransformer class]) {
      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
      [self setValueTransformer:[[[self alloc] init] autorelease]
                        forName:@"GrowlPluginNameTransformer"];
      [pool release];
   }
}

+ (Class)transformedValueClass 
{ 
   return [NSString class];
}
+ (BOOL)allowsReverseTransformation
{
   return NO;
}
- (id)transformedValue:(id)value
{
	return [value displayName];
}

@end

@implementation GrowlDisplaysViewController

@synthesize pluginController;
@synthesize ticketDatabase;
@synthesize displayPluginsTable;
@synthesize displayPrefView;
@synthesize displayDefaultPrefView;
@synthesize displayAuthor;
@synthesize displayVersion;
@synthesize previewButton;
@synthesize defaultDisplayPopUp;
@synthesize defaultActionPopUp;
@synthesize pluginConfigGroupController;
@synthesize displayPluginsArrayController;
@synthesize actionPluginsArrayController;

@synthesize disabledDisplaysSheet;
@synthesize disabledDisplaysList;

@synthesize pluginPrefPane;
@synthesize loadedPrefPanes;

@synthesize currentPluginController;

@synthesize defaultStyleLabel;
@synthesize showDisabledButtonTitle;
@synthesize getMoreStylesButtonTitle;
@synthesize previewButtonTitle;
@synthesize displayStylesColumnTitle;
@synthesize noDefaultDisplayPluginLabel;

@synthesize awokeFromNib;

#pragma mark "Display" tab pane

-(void)dealloc {
	[defaultDisplayPopUp removeObserver:self forKeyPath:@"selecteditem"];
	
   [pluginPrefPane release];
   [loadedPrefPanes release];
   [currentPluginController release];
   [defaultStyleLabel release];
   [showDisabledButtonTitle release];
   [getMoreStylesButtonTitle release];
   [previewButtonTitle release];
   [displayStylesColumnTitle release];
   [super dealloc];
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil forPrefPane:(GrowlPreferencePane *)aPrefPane {
   if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil forPrefPane:aPrefPane])){
      self.pluginController = [GrowlPluginController sharedController];
		self.ticketDatabase = [GrowlTicketDatabase sharedInstance];
   
      self.defaultStyleLabel = NSLocalizedString(@"Default Style", @"Default style picker label");
      self.showDisabledButtonTitle = NSLocalizedString(@"Show Disabled", @"Button title which shows a list of disabled plugins");
      self.getMoreStylesButtonTitle = NSLocalizedString(@"Get more styles", @"Button title which opens growl.info to the styles page");
      self.previewButtonTitle = NSLocalizedString(@"Preview", @"Button title which shows a preview of the current selected style");
      self.displayStylesColumnTitle = NSLocalizedString(@"Display Styles", @"Column title for Display Styles");
		self.noDefaultDisplayPluginLabel = NSLocalizedString(@"No Default Display", @"Setting for no visual display");
		
		self.awokeFromNib = NO;
	}
   return self;
}

- (void) awakeFromNib {
	if(self.awokeFromNib)
		return;
	
   self.loadedPrefPanes = [NSMutableArray array];
      
	
	self.pluginConfigGroupController = [[[GroupedArrayController alloc] initWithEntityName:@"GrowlPlugin" 
																							 basePredicateString:@"" 
																											groupKey:@"pluginType"
																							managedObjectContext:[[GrowlTicketDatabase sharedInstance] managedObjectContext]] autorelease];
	
	NSSortDescriptor *ascendingName = [NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES];
	[[pluginConfigGroupController countController] setSortDescriptors:[NSArray arrayWithObject:ascendingName]];
	[pluginConfigGroupController setDelegate:self];
	[pluginConfigGroupController setGrouped:YES];
	[pluginConfigGroupController setTableView:displayPluginsTable];
	
	NSString *defaultDisplayPluginName = [[self preferencesController] defaultDisplayPluginName];
	NSArray *defaultActions = [[self preferencesController] defaultActionPluginIDArray];
	[displayPluginsArrayController setSortDescriptors:[NSArray arrayWithObject:ascendingName]];
	[actionPluginsArrayController setSortDescriptors:[NSArray arrayWithObject:ascendingName]];
		
	__block GrowlDisplaysViewController *blockSafe = self;
	dispatch_async(dispatch_get_main_queue(), ^(void){
		[blockSafe selectDefaultPlugin:defaultDisplayPluginName];
		[blockSafe selectPlugin:defaultDisplayPluginName];
		[blockSafe selectDefaultActions:defaultActions];
	});
	self.awokeFromNib = YES;
}

+ (NSString*)nibName {
   return @"DisplayPrefs";
}

- (void)viewWillUnload {
	[[GrowlTicketDatabase sharedInstance] saveDatabase:YES];
	[super viewWillUnload];
}

- (void)selectDefaultActions:(NSArray*)actions {
	__block GrowlDisplaysViewController *blockSelf = self;
	__block NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
	[actions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSUInteger index = [[blockSelf.actionPluginsArrayController arrangedObjects] indexOfObjectPassingTest:^BOOL(id testObj, NSUInteger testIDX, BOOL *testStop) {
			if([[testObj configID] caseInsensitiveCompare:obj] == NSOrderedSame){
				return YES;
			}
			return NO;
		}];
		if(index != NSNotFound){
			[indexSet addIndex:index];
		}
	}];
	if([indexSet count] > 0){
		[defaultActionPopUp selectItemAtIndex:[indexSet firstIndex] + 2];
	}else{
		[defaultActionPopUp selectItemAtIndex:0];
	}
}

- (void)selectDefaultPlugin:(NSString*)pluginID {
	NSUInteger index = [[displayPluginsArrayController arrangedObjects] indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
		if([[obj configID] caseInsensitiveCompare:pluginID] == NSOrderedSame){
			return YES;
		}
		return NO;
	}];
	if(index != NSNotFound){
		[defaultDisplayPopUp selectItemAtIndex:index + 2];
	}else{
		[defaultDisplayPopUp selectItemAtIndex:0];
	}
}

- (void)selectPlugin:(NSString*)pluginName 
{
   __block NSUInteger index = NSNotFound;
   [[pluginConfigGroupController arrangedObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if ([obj isKindOfClass:[GroupController class]])
			return;
      if ([[obj valueForKey:@"configID"] caseInsensitiveCompare:pluginName] == NSOrderedSame) 
		{
         index = idx;
         *stop = YES;
      }else if([[obj valueForKey:@"displayName"] caseInsensitiveCompare:pluginName] == NSOrderedSame){
			index = idx;
			*stop = YES;
		}else if([[obj valueForKey:@"pluginID"] caseInsensitiveCompare:pluginName] == NSOrderedSame){
			NSLog(@"Opening to first plugin with plugin bundle id of %@", pluginName);
			index = idx;
			*stop = YES;
		}
   }];
   
   if(index != NSNotFound)
      [displayPluginsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
}

-(void)updateDefaultDisplayPreference{
	NSInteger index = [defaultDisplayPopUp indexOfSelectedItem];
	NSString *newDefaultID = nil;
	if(index >= 2 && index - 2 < (NSInteger)[[displayPluginsArrayController arrangedObjects] count]){
		id pluginToUse = [[displayPluginsArrayController arrangedObjects] objectAtIndex:index - 2];
		if(pluginToUse && [pluginToUse isKindOfClass:[GrowlTicketDatabaseDisplay class]])
			newDefaultID = [pluginToUse configID];
	}
	[[self preferencesController] setDefaultDisplayPluginName:newDefaultID];
}

-(void)updateDefaultActionPreference{
	NSInteger index = [defaultActionPopUp indexOfSelectedItem];
	NSString *newDefaultID = nil;
	if(index >= 2 && index - 2 < (NSInteger)[[actionPluginsArrayController arrangedObjects] count]){
		id pluginToUse = [[actionPluginsArrayController arrangedObjects] objectAtIndex:index - 2];
		if(pluginToUse && [pluginToUse isKindOfClass:[GrowlTicketDatabaseAction class]])
			newDefaultID = [pluginToUse configID];
	}
	if(newDefaultID)
		[[self preferencesController] setDefaultActionPluginIDArray:[NSArray arrayWithObject:newDefaultID]];
	else
		[[self preferencesController] setDefaultActionPluginIDArray:nil];
}

- (IBAction) showDisabledDisplays:(id)sender {
	[disabledDisplaysList setString:[[pluginController disabledPlugins] componentsJoinedByString:@"\n"]];
	
	[NSApp beginSheet:disabledDisplaysSheet 
	   modalForWindow:[[self view] window]
       modalDelegate:nil
	   didEndSelector:nil
         contextInfo:nil];
}

- (IBAction) endDisabledDisplays:(id)sender {
	[NSApp endSheet:disabledDisplaysSheet];
	[disabledDisplaysSheet orderOut:disabledDisplaysSheet];
}

// Returns a boolean based on whether any disabled displays are present, used for the 'hidden' binding of the button on the tab
- (BOOL)hasDisabledDisplays {
	return [pluginController disabledPluginsPresent];
}

- (IBAction) openGrowlWebSiteToStyles:(id)sender {
   [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://growl.info/styles.php"]];
}

// Popup buttons that post preview notifications support suppressing the preview with the Option key
- (IBAction) showPreview:(id)sender {
	if(sender == defaultDisplayPopUp)
		[self updateDefaultDisplayPreference];
	if(sender == defaultActionPopUp)
		[self updateDefaultActionPreference];
	if(([sender isKindOfClass:[NSPopUpButton class]]) && ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask))
		return;
	
	id pluginToUse = nil;
	if ([sender isKindOfClass:[NSPopUpButton class]]) {
		NSInteger index = [sender indexOfSelectedItem];
		NSArray *objects = (sender == defaultDisplayPopUp) ? [displayPluginsArrayController arrangedObjects] : 
																			  [actionPluginsArrayController arrangedObjects];
		if(index >= 2 && index - 2 < (NSInteger)[objects count])
			pluginToUse = [objects objectAtIndex:index - 2];
   }else if ([sender isKindOfClass:[NSButton class]]){
		pluginToUse = [pluginConfigGroupController selection];
	}
	if(pluginToUse && [pluginToUse isKindOfClass:[GrowlTicketDatabasePlugin class]])
		[[NSNotificationCenter defaultCenter] postNotificationName:GrowlPreview
																			 object:pluginToUse];
}

- (void) loadViewForDisplay:(GrowlTicketDatabasePlugin *)display {
	NSView *newView = nil;
	GrowlPluginPreferencePane *prefPane = nil, *oldPrefPane = nil;
   
	if (pluginPrefPane)
		oldPrefPane = pluginPrefPane;
   
	if (display) {
		// Old plugins won't support the new protocol. Check first
		prefPane = [currentPluginController preferencePane];
      
		if (prefPane == pluginPrefPane) {
			// Don't bother swapping anything
			[prefPane setValue:display forKey:@"actionConfiguration"];
			[[GrowlTicketDatabase sharedInstance] saveDatabase:NO];
			return;
		} else {
			self.pluginPrefPane = prefPane;
			[oldPrefPane willUnselect];
		}
		if (pluginPrefPane) {
			if ([loadedPrefPanes containsObject:pluginPrefPane]) {
				newView = [pluginPrefPane mainView];
			} else {
				newView = [pluginPrefPane loadMainView];
				[loadedPrefPanes addObject:pluginPrefPane];
			}
			[pluginPrefPane willSelect];
		}
	} else {
      self.pluginPrefPane = nil;
	}
	if (!newView)
		newView = displayDefaultPrefView;
	if (displayPrefView != newView) {
		// Make sure the new view is framed correctly
		[newView setFrame:[displayPrefView frame]];
		[[displayPrefView superview] replaceSubview:displayPrefView with:newView];
		displayPrefView = newView;
      
		if (pluginPrefPane) {
			[pluginPrefPane didSelect];
			// Hook up key view chain
			[displayPluginsTable setNextKeyView:[pluginPrefPane firstKeyView]];
			[[pluginPrefPane lastKeyView] setNextKeyView:previewButton];
			//[[displayPluginsTable window] makeFirstResponder:[pluginPrefPane initialKeyView]];
		} else {
			[displayPluginsTable setNextKeyView:previewButton];
		}
      
		[pluginPrefPane setValue:display forKey:@"actionConfiguration"];
		[[GrowlTicketDatabase sharedInstance] saveDatabase:NO];
		if (oldPrefPane)
			[oldPrefPane didUnselect];
	}
}

#pragma mark NSTableView data source and delegate

- (BOOL)tableView:(NSTableView*)tableView isGroupRow:(NSInteger)row
{
   if(tableView == displayPluginsTable && row < (NSInteger)[[pluginConfigGroupController arrangedObjects] count]){
      return [[[pluginConfigGroupController arrangedObjects] objectAtIndex:row] isKindOfClass:[GroupController class]];
   }else
      return NO;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
   if(aTableView == displayPluginsTable){
      return ![self tableView:aTableView isGroupRow:rowIndex];
   }
   return YES;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [[pluginConfigGroupController arrangedObjects] count];
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
   if(aTableView == displayPluginsTable && rowIndex >= 0 && rowIndex < (NSInteger)[[pluginConfigGroupController arrangedObjects] count]){
      return [[pluginConfigGroupController arrangedObjects] objectAtIndex:rowIndex];
   }
   return nil;
}

-(NSView*)tableView:(NSTableView*)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if([self tableView:tableView isGroupRow:row]){
		NSTableCellView *groupView = [displayPluginsTable makeViewWithIdentifier:@"PluginGroupView" owner:self];
		return groupView;
	}else {
		NSTableCellView *pluginView = [displayPluginsTable makeViewWithIdentifier:@"PluginItemView" owner:self];
		return pluginView;
	}
	return nil;
}
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
   if([self tableView:tableView isGroupRow:row])
      return 20.0;
   return 20;
}

-(void)updatePluginPreferenceSelection {
	GrowlTicketDatabaseAction *pluginConfig = [pluginConfigGroupController selection];
	if(pluginConfig && [pluginConfig isKindOfClass:[GrowlTicketDatabasePlugin class]]){
		self.currentPluginController = [pluginConfig pluginInstanceForConfiguration];
		[self loadViewForDisplay:pluginConfig];
		if([currentPluginController author])
			[displayAuthor setStringValue:[currentPluginController author]];
		else
			[displayAuthor setStringValue:@""];
		if([currentPluginController version])
			[displayVersion setStringValue:[currentPluginController version]];
		else
			[displayVersion setStringValue:@""];
	}
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification {
	__block GrowlDisplaysViewController *blockSelf = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		[blockSelf updatePluginPreferenceSelection];
	});
}

@end
