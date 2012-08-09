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
#import "GrowlPreferencesController.h"
#import "GrowlTicketDatabase.h"
#import "GrowlTicketDatabasePlugin.h"
#import "GrowlTicketDatabaseAction.h"
#import "GrowlTicketDatabaseCompoundAction.h"
#import "GrowlTicketDatabaseDisplay.h"
#import "GrowlCompoundActionPreferencePane.h"

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
@synthesize displayName;
@synthesize previewButton;
@synthesize defaultDisplayPopUp;
@synthesize defaultActionPopUp;
@synthesize pluginConfigGroupController;
@synthesize displayConfigsArrayController;
@synthesize actionConfigsArrayController;
@synthesize displayPluginsArrayController;

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
	
	NSSortDescriptor *ascendingName = [NSSortDescriptor sortDescriptorWithKey:@"displayName" 
																						 ascending:YES 
																						  selector:@selector(caseInsensitiveCompare:)];
	[[pluginConfigGroupController countController] setSortDescriptors:[NSArray arrayWithObject:ascendingName]];
	[pluginConfigGroupController setDelegate:self];
	[pluginConfigGroupController setGrouped:YES];
	[pluginConfigGroupController setTableView:displayPluginsTable];
	
	NSString *defaultDisplayPluginName = [[self preferencesController] defaultDisplayPluginName];
	NSArray *defaultActions = [[self preferencesController] defaultActionPluginIDArray];
	[displayConfigsArrayController setSortDescriptors:[NSArray arrayWithObject:ascendingName]];
	[actionConfigsArrayController setSortDescriptors:[NSArray arrayWithObject:ascendingName]];
	[displayPluginsArrayController setSortDescriptors:[NSArray arrayWithObject:ascendingName]];
	
	[displayPluginsTable setTarget:self];
	[displayPluginsTable setDoubleAction:@selector(editPluginName:)];
	
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
		NSUInteger index = [[blockSelf.actionConfigsArrayController arrangedObjects] indexOfObjectPassingTest:^BOOL(id testObj, NSUInteger testIDX, BOOL *testStop) {
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
		[indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
			[[defaultActionPopUp itemAtIndex:idx + 3] setState:NSOnState];
		}];
	}else{
		[[defaultActionPopUp itemAtIndex:1] setState:NSOnState];
	}
}

- (void)selectDefaultPlugin:(NSString*)pluginID {
	NSUInteger index = [[displayConfigsArrayController arrangedObjects] indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
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
	if(index >= 2 && index - 2 < (NSInteger)[[displayConfigsArrayController arrangedObjects] count]){
		id pluginToUse = [[displayConfigsArrayController arrangedObjects] objectAtIndex:index - 2];
		if(pluginToUse && [pluginToUse isKindOfClass:[GrowlTicketDatabaseDisplay class]])
			newDefaultID = [pluginToUse configID];
	}
	[[self preferencesController] setDefaultDisplayPluginName:newDefaultID];
}

-(NSArray*)selectedDefaultActions {
	NSArray *menuItems = [defaultActionPopUp itemArray];
	NSArray *selectedActions = nil;
	__block NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
	[menuItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if([obj state] == NSOnState && 
			idx >= 3 &&
			idx - 3 < [[actionConfigsArrayController arrangedObjects] count])
		{
			id pluginToUse = [[actionConfigsArrayController arrangedObjects] objectAtIndex:idx - 3];
			if(pluginToUse && [pluginToUse isKindOfClass:[GrowlTicketDatabaseAction class]])
				[indexSet addIndex:idx - 3];
		}
	}];
	if([indexSet count] > 0)
		selectedActions = [[actionConfigsArrayController arrangedObjects] objectsAtIndexes:indexSet];
	return selectedActions;
}

-(void)updateDefaultActionPreference{
	NSUInteger selectionIndex = [defaultActionPopUp indexOfSelectedItem];
	
	if(selectionIndex == 1){
		//We are changing back to no default
		//remove the rest, the bottom if statement will take care of it
		[[defaultActionPopUp itemArray] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			[obj setState:NSOffState];
		}];
	}else{
		NSInteger newState = ([[defaultActionPopUp itemAtIndex:selectionIndex] state] == NSOnState) ? NSOffState : NSOnState;
		[[defaultActionPopUp itemAtIndex:selectionIndex] setState:newState];
	}
	
	NSArray *selectedItems = [self selectedDefaultActions];
	if(selectedItems && [selectedItems count] > 0){
		[[self preferencesController] setDefaultActionPluginIDArray:[selectedItems valueForKey:@"configID"]];
		[[defaultActionPopUp itemAtIndex:1] setState:NSOffState];
	}else{
		[[self preferencesController] setDefaultActionPluginIDArray:[NSArray array]];
		[[defaultActionPopUp itemAtIndex:1] setState:NSOnState];
	}
}

- (IBAction)editPluginName:(id)sender {
	NSInteger clickedRow = [displayPluginsTable clickedRow];
	if(clickedRow >= 0 && ![self tableView:displayPluginsTable isGroupRow:clickedRow]){
		NSTableCellView *view = [displayPluginsTable viewAtColumn:0 row:clickedRow makeIfNecessary:YES];
		[[view textField] setEditable:YES];
		[[view textField] becomeFirstResponder];
	}
}

- (void)controlTextDidEndEditing:(NSNotification *)obj {
	NSTextField *textField = [obj object];
	if ([[textField superview] isKindOfClass:[NSTableCellView class]]) {
		[textField setEditable:NO];
	}
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

- (IBAction)addCompoundConfiguration:(id)sender {
	[[GrowlTicketDatabase sharedInstance] createNewCompoundAction];
}

- (IBAction)addConfiguration:(id)sender {
	NSInteger index = [sender indexOfSelectedItem];
	if(index >= 3 && index - 3 < (NSInteger)[[displayPluginsArrayController arrangedObjects] count]){
		index -= 3;
		NSString *pluginName = [[[displayPluginsArrayController arrangedObjects] objectAtIndex:index] valueForKey:(NSString*)kCFBundleNameKey];
		NSDictionary *pluginDict = [pluginController displayPluginDictionaryWithName:pluginName
																									 author:nil
																									version:nil
																										type:nil];
		[[GrowlTicketDatabase sharedInstance] makeDefaultConfig:YES forPluginDict:pluginDict];
	}
}

-(void) deleteCallbackDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)displayPlugin {
	if(returnCode == NSAlertDefaultReturn && displayPlugin != nil && [(id)displayPlugin isKindOfClass:[GrowlTicketDatabasePlugin class]]){
		if(pluginPrefPane && [pluginPrefPane respondsToSelector:@selector(setPluginConfiguration:)])
			[pluginPrefPane setValue:nil forKey:@"pluginConfiguration"];		
		
		[[GrowlTicketDatabase sharedInstance] deletePluginConfiguration:(GrowlTicketDatabasePlugin*)displayPlugin];
	}
	//Not the prettiest, but it makes sure we avoid empty selection
	NSUInteger firstNonGroupItem = [self.pluginConfigGroupController indexOfFirstNonGroupItem];
	if(firstNonGroupItem != NSNotFound){
      double delayInSeconds = .2;
      dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
      dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
         [self.displayPluginsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:firstNonGroupItem] byExtendingSelection:NO];
      });
	}
}

- (IBAction)deleteConfiguration:(id)sender {
	id possible = [pluginConfigGroupController selection];
	if(possible && [possible isKindOfClass:[GrowlTicketDatabasePlugin class]]){
		GrowlTicketDatabasePlugin *plugin = (GrowlTicketDatabasePlugin*)possible;
		BOOL showAlert = NO;
		if([plugin isKindOfClass:[GrowlTicketDatabaseDisplay class]]){
			if([[(GrowlTicketDatabaseDisplay*)plugin tickets] count] > 0 || 
				[[self.preferencesController defaultDisplayPluginName] caseInsensitiveCompare:[plugin configID]] == NSOrderedSame)
				showAlert = YES;
		}else if([plugin isKindOfClass:[GrowlTicketDatabaseCompoundAction class]]){
			if([[(GrowlTicketDatabaseCompoundAction*)plugin tickets] count] > 0 || 
				[[self.preferencesController defaultActionPluginIDArray] containsObject:[plugin configID]])
				showAlert = YES;
		}else if([plugin isKindOfClass:[GrowlTicketDatabaseAction class]]){
			if([[(GrowlTicketDatabaseAction*)plugin tickets] count] > 0 ||
				[[(GrowlTicketDatabaseAction*)plugin compounds] count] > 0 ||
				[[self.preferencesController defaultActionPluginIDArray] containsObject:[plugin configID]])
				showAlert = YES;
		}
		if(showAlert){
			NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to remove %@?", nil), [plugin displayName]]
														defaultButton:NSLocalizedString(@"Remove", "Button title for removing something")
													 alternateButton:NSLocalizedStringFromTableInBundle(@"Cancel", nil, [NSBundle mainBundle], "Button title for canceling")
														  otherButton:nil
										informativeTextWithFormat:NSLocalizedString(@"This plugin configuration is in use, removing it will cause it to be removed from the applications and notifications where it is in use", "")];
			[alert setIcon:[[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:@"growl-icon"]] autorelease]];
			[alert beginSheetModalForWindow:[[NSApplication sharedApplication] keyWindow] 
									modalDelegate:self 
								  didEndSelector:@selector(deleteCallbackDidEnd:returnCode:contextInfo:) 
									  contextInfo:plugin];
		}else{
			[self deleteCallbackDidEnd:nil returnCode:NSAlertDefaultReturn contextInfo:plugin];
		}
	}
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
		if(sender == defaultDisplayPopUp){
			NSInteger index = [sender indexOfSelectedItem];
			NSArray *objects = (sender == defaultDisplayPopUp) ? [displayConfigsArrayController arrangedObjects] : 
			[actionConfigsArrayController arrangedObjects];
			if(index >= 2 && index - 2 < (NSInteger)[objects count])
				pluginToUse = [objects objectAtIndex:index - 2];
		}else if(sender == defaultActionPopUp){
			pluginToUse = [self selectedDefaultActions];
		}
   }else if ([sender isKindOfClass:[NSButton class]]){
		pluginToUse = [pluginConfigGroupController selection];
	}
	if(pluginToUse && [pluginToUse isKindOfClass:[GrowlTicketDatabasePlugin class]])
		[[NSNotificationCenter defaultCenter] postNotificationName:GrowlPreview
																			 object:pluginToUse];
	if(pluginToUse && [pluginToUse isKindOfClass:[NSArray class]]){
		[pluginToUse enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			[[NSNotificationCenter defaultCenter] postNotificationName:GrowlPreview
																				 object:obj];
		}];
	}
}

- (void) loadViewForDisplay:(GrowlTicketDatabasePlugin *)display {
	NSView *newView = nil;
	GrowlPluginPreferencePane *prefPane = nil, *oldPrefPane = nil;
   
	if (pluginPrefPane)
		oldPrefPane = pluginPrefPane;
   
	if(display) {
		if([display isKindOfClass:[GrowlTicketDatabaseCompoundAction class]]){
			static GrowlPluginPreferencePane *compoundPane = nil;
			static dispatch_once_t onceToken;
			dispatch_once(&onceToken, ^{
				compoundPane = (GrowlPluginPreferencePane*)[[GrowlCompoundActionPreferencePane alloc] initWithBundle:[NSBundle mainBundle]];
			});
			prefPane = compoundPane;
			
		}else{
			prefPane = [currentPluginController preferencePane];
		}
		
		if (prefPane == pluginPrefPane) {
			// Don't bother swapping anything
			if([prefPane respondsToSelector:@selector(setPluginConfiguration:)])
				[prefPane setValue:display forKey:@"pluginConfiguration"];
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
      
		if([prefPane respondsToSelector:@selector(setPluginConfiguration:)])
			[prefPane setValue:display forKey:@"pluginConfiguration"];
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
		
		NSString *newDisplayName = nil;
		if([currentPluginController name])
			newDisplayName = [currentPluginController name];
		else{
			if([pluginConfig isKindOfClass:[GrowlTicketDatabaseCompoundAction class]]){
				newDisplayName = NSLocalizedString(@"Compound Action", @"");
			}else{
				newDisplayName = @"";
			}
		}
		[displayName setStringValue:newDisplayName];
	}else{
      [self loadViewForDisplay:nil];
      [displayAuthor setStringValue:@""];
      [displayVersion setStringValue:@""];
      [displayName setStringValue:@""];
   }
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification {
	__block GrowlDisplaysViewController *blockSelf = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		[blockSelf updatePluginPreferenceSelection];
	});
}

-(void)groupedControllerEndUpdates:(GroupedArrayController *)groupedController {
	NSString *defaultDisplayPluginName = [[self preferencesController] defaultDisplayPluginName];
	NSArray *defaultActions = [[self preferencesController] defaultActionPluginIDArray];
	__block GrowlDisplaysViewController *blockSafe = self;
	dispatch_async(dispatch_get_main_queue(), ^(void){
		[blockSafe selectDefaultPlugin:defaultDisplayPluginName];
		[blockSafe selectDefaultActions:defaultActions];
	});
}

@end
