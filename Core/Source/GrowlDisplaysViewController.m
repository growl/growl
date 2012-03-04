//
//  GrowlDisplaysViewController.m
//  Growl
//
//  Created by Daniel Siemer on 11/10/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlDisplaysViewController.h"

#import "GrowlPluginPreferencePane.h"

#import "GrowlPlugin.h"
#import "GrowlPluginController.h"
#import "GrowlTicketDatabase.h"
#import "GrowlTicketDatabasePlugin.h"
#import "GrowlTicketDatabaseAction.h"
#import "GrowlTicketDatabaseDisplay.h"

@implementation GrowlDisplaysViewController

@synthesize pluginController;
@synthesize ticketDatabase;
@synthesize displayPluginsTable;
@synthesize displayPrefView;
@synthesize displayDefaultPrefView;
@synthesize displayAuthor;
@synthesize displayVersion;
@synthesize previewButton;
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

#pragma mark "Display" tab pane

-(void)dealloc {
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
	}
   return self;
}

- (void) awakeFromNib {
   self.loadedPrefPanes = [NSMutableArray array];
      
   [displayPluginsArrayController addObserver:self forKeyPath:@"selection" options:0 context:nil];

   // Select the default style if possible. 
   {
		NSString *defaultDisplayPluginName = [[self preferencesController] defaultDisplayPluginName];
      __block GrowlDisplaysViewController *blockSafe = self;
      dispatch_async(dispatch_get_main_queue(), ^{
         [blockSafe selectPlugin:defaultDisplayPluginName];
      });		
	}
}

+ (NSString*)nibName {
   return @"DisplayPrefs";
}

- (void)viewWillUnload {
	[[GrowlTicketDatabase sharedInstance] saveDatabase:YES];
	[super viewWillUnload];
}

- (void)selectPlugin:(NSString*)pluginName 
{
   __block NSUInteger index = NSNotFound;
   [[displayPluginsArrayController arrangedObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if ([[obj valueForKey:@"displayName"] caseInsensitiveCompare:pluginName] == NSOrderedSame) {
         index = idx;
         *stop = YES;
      }
   }];
   
   if(index != NSNotFound)
      [displayPluginsArrayController setSelectionIndex:index];
}

- (void) observeValueForKeyPath:(NSString *)keyPath 
                       ofObject:(id)object
                         change:(NSDictionary *)change 
                        context:(void *)context 
{
	if ([keyPath isEqualToString:@"selection"] && object == displayPluginsArrayController) {
		NSUInteger index = [displayPluginsArrayController selectionIndex];
		if(index != NSNotFound){
			GrowlTicketDatabaseAction *pluginConfig = [[displayPluginsArrayController arrangedObjects] objectAtIndex:index];
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
	if(([sender isKindOfClass:[NSPopUpButton class]]) && ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask))
		return;
	
	id pluginToUse = nil;
	if ([sender isKindOfClass:[NSPopUpButton class]]) {
		NSPopUpButton *popUp = (NSPopUpButton *)sender;
		id representedObject = [[popUp selectedItem] representedObject];
		if ([representedObject isKindOfClass:[GrowlTicketDatabasePlugin class]])
			pluginToUse = representedObject;
   }else if ([sender isKindOfClass:[NSButton class]]){
		NSUInteger index = [displayPluginsArrayController selectionIndex];
		if(index != NSNotFound)
			pluginToUse = [[displayPluginsArrayController arrangedObjects] objectAtIndex:index];
	}
	if(pluginToUse)
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

@end
