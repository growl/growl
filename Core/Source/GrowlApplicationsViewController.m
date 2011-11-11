//
//  GrowlApplicationsViewController.m
//  Growl
//
//  Created by Daniel Siemer on 11/9/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlApplicationsViewController.h"
#import "GrowlPositionPicker.h"
#import "TicketsArrayController.h"
#import "GrowlTicketController.h"
#import "GrowlPreferencePane.h"
#import "ACImageAndTextCell.h"

@implementation GrowlApplicationsViewController

@synthesize growlApplications;
@synthesize applicationsNameAndIconColumn;
@synthesize applicationsTab;
@synthesize configurationTab;
@synthesize notificationPriorityMenu;
@synthesize ticketController;
@synthesize ticketsArrayController;
@synthesize notificationsArrayController;
@synthesize appPositionPicker;
@synthesize soundMenuButton;
@synthesize displayMenuButton;
@synthesize notificationDisplayMenuButton;
@synthesize selectedNotificationIndexes;

@synthesize demoSound;

@synthesize canRemoveTicket;

-(void)dealloc {
   [demoSound release];
   [super dealloc];
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil forPrefPane:(GrowlPreferencePane *)aPrefPane
{
   if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil forPrefPane:aPrefPane])){
      self.ticketController = [GrowlTicketController sharedController];
   }
   return self;
}

-(void)awakeFromNib {
   [ticketsArrayController addObserver:self forKeyPath:@"selection" options:0 context:nil];
   
   self.canRemoveTicket = NO;
   
   [growlApplications setDoubleAction:@selector(tableViewDoubleClick:)];
	[growlApplications setTarget:self];
   
	// bind the app level position picker programmatically since its a custom view, register for notification so we can handle updating manually
	[appPositionPicker bind:@"selectedPosition" toObject:ticketsArrayController withKeyPath:@"selection.selectedPosition" options:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePosition:) name:GrowlPositionPickerChangedSelectionNotification object:appPositionPicker];

	ACImageAndTextCell *imageTextCell = [[[ACImageAndTextCell alloc] init] autorelease];
	[applicationsNameAndIconColumn setDataCell:imageTextCell];
   
   [applicationsTab selectFirstTabViewItem:self];
   
   [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(translateSeparatorsInMenu:)
                                                name:NSPopUpButtonWillPopUpNotification
                                              object:soundMenuButton];
}

- (void) updatePosition:(NSNotification *)notification {
	if([notification object] == appPositionPicker) {
		// a cheap hack around selection not providing a workable object
		NSArray *selection = [ticketsArrayController selectedObjects];
		if ([selection count] > 0)
			[[selection objectAtIndex:0] setSelectedPosition:[appPositionPicker selectedPosition]];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
   if([keyPath isEqualToString:@"selection"] && object == ticketsArrayController) {
      [self setCanRemoveTicket:[ticketsArrayController canRemove]];
   }
}

- (void) reloadSounds
{
   [self willChangeValueForKey:@"sounds"];
   [self didChangeValueForKey:@"sounds"];
}

- (NSArray *) sounds {
   NSMutableArray *soundNames = [[NSMutableArray alloc] init];
	
	NSArray *paths = [NSArray arrayWithObjects:@"/System/Library/Sounds",
                     @"/Library/Sounds",
                     [NSString stringWithFormat:@"%@/Library/Sounds", NSHomeDirectory()],
                     nil];
   
	for (NSString *directory in paths) {
		BOOL isDirectory = NO;
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:&isDirectory]) {
			if (isDirectory) {
				
				NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:nil];
            if([files count])
               [soundNames addObject:@"-"];
				for (NSString *filename in files) {
					NSString *file = [filename stringByDeletingPathExtension];
               
					if (![file isEqualToString:@".DS_Store"])
						[soundNames addObject:file];
				}
			}
		}
	}
	
	return [soundNames autorelease];
}

- (void)translateSeparatorsInMenu:(NSNotification *)notification
{
	NSPopUpButton * button = [notification object];
	
	NSMenu *menu = [button menu];
	
	NSInteger itemIndex = 0;
	
	while ((itemIndex = [menu indexOfItemWithTitle:@"-"]) != -1) {
		[menu removeItemAtIndex:itemIndex];
		[menu insertItem:[NSMenuItem separatorItem] atIndex:itemIndex];
	}
}

- (void) deleteTicket:(id)sender {
	NSString *appName = [[[ticketsArrayController selectedObjects] objectAtIndex:0U] appNameHostName];
	NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Are you sure you want to remove %@?", nil, [NSBundle mainBundle], nil), appName]
									 defaultButton:NSLocalizedStringFromTableInBundle(@"Remove", nil, [NSBundle mainBundle], "Button title for removing something")
								   alternateButton:NSLocalizedStringFromTableInBundle(@"Cancel", nil, [NSBundle mainBundle], "Button title for canceling")
									   otherButton:nil
						 informativeTextWithFormat:[NSString stringWithFormat:
													NSLocalizedStringFromTableInBundle(@"This will remove all Growl settings for %@.", nil, [NSBundle mainBundle], ""), appName]];
	[alert setIcon:[[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:@"growl-icon"]] autorelease]];
	[alert beginSheetModalForWindow:[[NSApplication sharedApplication] keyWindow] modalDelegate:self didEndSelector:@selector(deleteCallbackDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

// this method is used as our callback to determine whether or not to delete the ticket
-(void) deleteCallbackDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)eventID {
	if (returnCode == NSAlertDefaultReturn) {
		GrowlApplicationTicket *ticket = [[ticketsArrayController selectedObjects] objectAtIndex:0U];
		NSString *path = [ticket path];

		if ([[NSFileManager defaultManager] removeItemAtPath:path error:nil]) {
         [[GrowlTicketController sharedController] removeTicketForApplicationName:[ticket appNameHostName]];
         [growlApplications noteNumberOfRowsChanged];
		}
	}
}

- (IBAction) showPreview:(id)sender {
	if(([sender isKindOfClass:[NSPopUpButton class]]) && ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask))
		return;
	
	NSDictionary *pluginToUse = nil;
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
      
      NSArray *apps = [ticketsArrayController selectedObjects];
      if(apps && [apps count]) {
         NSDictionary *parentApp = [apps objectAtIndex:0U];
         pluginName = [parentApp valueForKey:@"displayPluginName"];
      }
	}		
   if(!pluginName)
      pluginName = [pluginToUse objectForKey:GrowlPluginInfoKeyName];
	[[NSNotificationCenter defaultCenter] postNotificationName:GrowlPreview
                                                       object:pluginName];
}

-(IBAction)playSound:(id)sender
{
    if(self.demoSound && [self.demoSound isPlaying])
        [self.demoSound stop];

	if([sender indexOfSelectedItem] > 0) // The 0 item is "None"
    {
        self.demoSound = [NSSound soundNamed:[[sender selectedItem] title]];		
        [self.demoSound play];
    }
}

- (IBAction) showApplicationConfigurationTab:(id)sender {
	if ([ticketsArrayController selectionIndex] != NSNotFound) {
		[[self prefPane] populateDisplaysPopUpButton:displayMenuButton nameOfSelectedDisplay:[[ticketsArrayController selection] valueForKey:@"displayPluginName"] includeDefaultMenuItem:YES];
		[[self prefPane] populateDisplaysPopUpButton:notificationDisplayMenuButton nameOfSelectedDisplay:[[notificationsArrayController selection] valueForKey:@"displayPluginName"] includeDefaultMenuItem:YES];

		[applicationsTab selectLastTabViewItem:sender];
		[configurationTab selectFirstTabViewItem:sender];
	}
}

- (IBAction) changeNameOfDisplayForApplication:(id)sender {
	NSString *newDisplayPluginName = [[sender selectedItem] representedObject];
	[[ticketsArrayController selectedObjects] setValue:newDisplayPluginName forKey:@"displayPluginName"];
	[self showPreview:sender];
}
- (IBAction) changeNameOfDisplayForNotification:(id)sender {
	NSString *newDisplayPluginName = [[sender selectedItem] representedObject];
	[[notificationsArrayController selectedObjects] setValue:newDisplayPluginName forKey:@"displayPluginName"];
	[self showPreview:sender];
}

- (NSIndexSet *) selectedNotificationIndexes {
	return selectedNotificationIndexes;
}
- (void) setSelectedNotificationIndexes:(NSIndexSet *)newSelectedNotificationIndexes {
	if(selectedNotificationIndexes != newSelectedNotificationIndexes) {
		[selectedNotificationIndexes release];
		selectedNotificationIndexes = [newSelectedNotificationIndexes copy];

		NSInteger indexOfMenuItem = [[notificationDisplayMenuButton menu] indexOfItemWithRepresentedObject:[[notificationsArrayController selection] valueForKey:@"displayPluginName"]];
		if (indexOfMenuItem < 0)
			indexOfMenuItem = 0;
		[notificationDisplayMenuButton selectItemAtIndex:indexOfMenuItem];
	}
}

#pragma mark TableView data source methods

- (void) tableViewDidClickInBody:(NSTableView*)tableView{
   [self setCanRemoveTicket:[ticketsArrayController canRemove]];
}

- (id)tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
   if(tableColumn == applicationsNameAndIconColumn){
      GrowlApplicationTicket *ticket = [[ticketsArrayController arrangedObjects] objectAtIndex:row];
      NSImage *icon = [[[NSImage alloc] initWithData:[ticket iconData]] autorelease];
      [icon setScalesWhenResized:YES];
      [icon setSize:CGSizeMake(32.0, 32.0)];
      [[tableColumn dataCellForRow:row] setImage:icon];
   }
   return nil;
}

- (IBAction) tableViewDoubleClick:(id)sender {
	[self showApplicationConfigurationTab:sender];
}

@end
