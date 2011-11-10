//
//  GrowlDisplaysViewController.m
//  Growl
//
//  Created by Daniel Siemer on 11/10/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlDisplaysViewController.h"

#import "GrowlPlugin.h"
#import "GrowlPluginController.h"

@implementation GrowlDisplaysViewController

@synthesize pluginController;
@synthesize displayPluginsTable;
@synthesize displayPrefView;
@synthesize displayDefaultPrefView;
@synthesize displayAuthor;
@synthesize displayVersion;
@synthesize previewButton;
@synthesize displayPluginsArrayController;

@synthesize disabledDisplaysSheet;
@synthesize disabledDisplaysList;

@synthesize displayPlugins;
@synthesize pluginPrefPane;
@synthesize loadedPrefPanes;

@synthesize currentPlugin;
@synthesize currentPluginController;

#pragma mark "Display" tab pane

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil forPrefPane:(GrowlPreferencePane *)aPrefPane {
   if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil forPrefPane:aPrefPane])){
      self.pluginController = [GrowlPluginController sharedController];
   }
   return self;
}

- (void) awakeFromNib {
   self.loadedPrefPanes = [NSMutableArray array];
   
   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
   [nc addObserver:self selector:@selector(reloadPrefs:)     name:GrowlPreferencesChanged object:nil];
   [self reloadPrefs:nil];
   
   [displayPluginsArrayController addObserver:self forKeyPath:@"selection" options:0 context:nil];

   // Select the default style if possible. 
   {
		id arrangedObjects = [displayPluginsArrayController arrangedObjects];
		NSUInteger count = [arrangedObjects count];
		NSString *defaultDisplayPluginName = [[self preferencesController] defaultDisplayPluginName];
		NSUInteger defaultStyleRow = NSNotFound;
		for (NSUInteger i = 0; i < count; i++) {
			if ([[[arrangedObjects objectAtIndex:i] valueForKey:@"CFBundleName"] isEqualToString:defaultDisplayPluginName]) {
				defaultStyleRow = i;
				break;
			}
		}
      
		if (defaultStyleRow != NSNotFound) {
			/* Wait until the next run loop; otherwise everything isn't finished loading and we throw an exception.
          * This is setting the view for the Displays tab, which isn't initially visible, so the user won't see
          * the flicker. I'm don't know why this is necessary. -evands
          */
			[self performSelector:@selector(selectRow:)
                    withObject:[NSIndexSet indexSetWithIndex:defaultStyleRow]
                    afterDelay:0];
		}
		
	}
}


- (void)selectRow:(NSIndexSet *)indexSet
{
	[displayPluginsTable selectRowIndexes:indexSet byExtendingSelection:NO];
}

- (void) reloadDisplayPluginView {
	NSArray *selectedPlugins = [displayPluginsArrayController selectedObjects];
	NSUInteger numPlugins = [displayPlugins count];
	if (numPlugins > 0U && selectedPlugins && [selectedPlugins count] > 0U)
		self.currentPlugin = [[selectedPlugins objectAtIndex:0U] retain];
	else
		self.currentPlugin = nil;
   
	if(self.currentPlugin)
   {
      NSString *currentPluginName = [self.currentPlugin objectForKey:(NSString *)kCFBundleNameKey];
      self.currentPluginController = (GrowlPlugin *)[pluginController pluginInstanceWithName:currentPluginName];
      [self loadViewForDisplay:currentPluginName];
      [displayAuthor setStringValue:[currentPlugin objectForKey:@"GrowlPluginAuthor"]];
      [displayVersion setStringValue:[currentPlugin objectForKey:(NSString *)kCFBundleNameKey]];
   }
}

- (void) observeValueForKeyPath:(NSString *)keyPath 
                       ofObject:(id)object
                         change:(NSDictionary *)change 
                        context:(void *)context 
{
	if ([keyPath isEqualToString:@"selection"]) {
      if (object == displayPluginsArrayController)
			[self reloadDisplayPluginView];
	}
}

- (void) reloadPrefs:(NSNotification *)notification {
	// ignore notifications which are sent by ourselves
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
   
	self.displayPlugins = [[pluginController displayPlugins] valueForKey:GrowlPluginInfoKeyName];
   
	if ([displayPlugins count] > 0U)
		[self reloadDisplayPluginView];
	else
		[self loadViewForDisplay:nil];
	
	[pool release];
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
	
	NSDictionary *pluginToUse = currentPlugin;
	NSString *pluginName = nil;
	BOOL doTheApp = NO;
   
	if ([sender isKindOfClass:[NSPopUpButton class]]) {
		NSPopUpButton *popUp = (NSPopUpButton *)sender;
		id representedObject = [[popUp selectedItem] representedObject];
		if ([representedObject isKindOfClass:[NSDictionary class]])
			pluginToUse = representedObject;
		else if ([representedObject isKindOfClass:[NSString class]])
			pluginName = representedObject;
		else {
         doTheApp = YES;
			//NSLog(@"%s: WARNING: Pop-up button menu item had represented object of class %@: %@", __func__, [representedObject class], representedObject);
      }
   }
   
	if (!pluginName && doTheApp) {
      //fall back to the application's plugin name
      
      /*NSArray *apps = [ticketsArrayController selectedObjects];
       if(apps && [apps count]) {
       NSDictionary *parentApp = [apps objectAtIndex:0U];
       pluginName = [parentApp valueForKey:@"displayPluginName"];
       }*/
	}		
   if(!pluginName)
      pluginName = [pluginToUse objectForKey:GrowlPluginInfoKeyName];
	[[NSNotificationCenter defaultCenter] postNotificationName:GrowlPreview
                                                       object:pluginName];
}

- (void) loadViewForDisplay:(NSString *)displayName {
	NSView *newView = nil;
	NSPreferencePane *prefPane = nil, *oldPrefPane = nil;
   
	if (pluginPrefPane)
		oldPrefPane = pluginPrefPane;
   
	if (displayName) {
		// Old plugins won't support the new protocol. Check first
		if ([currentPluginController respondsToSelector:@selector(preferencePane)])
			prefPane = [currentPluginController preferencePane];
      
		if (prefPane == pluginPrefPane) {
			// Don't bother swapping anything
			return;
		} else {
			[pluginPrefPane release];
			pluginPrefPane = [prefPane retain];
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
		[pluginPrefPane release];
		pluginPrefPane = nil;
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
      
		if (oldPrefPane)
			[oldPrefPane didUnselect];
	}
}

@end
