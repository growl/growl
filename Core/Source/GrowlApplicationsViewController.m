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

static BOOL awoken = NO;

@implementation GrowlApplicationsViewController

@synthesize growlApplications;
@synthesize applicationsNameAndIconColumn;
@synthesize notificationPriorityMenu;
@synthesize ticketController;
@synthesize ticketsArrayController;
@synthesize notificationsArrayController;
@synthesize appPositionPicker;
@synthesize soundMenuButton;
@synthesize displayMenuButton;
@synthesize notificationDisplayMenuButton;
@synthesize selectedNotificationIndexes;

@synthesize applicationScrollView;

@synthesize demoSound;

@synthesize canRemoveTicket;
@synthesize showSearch;

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
   if(awoken)
      return;
   
   awoken = YES;
   [ticketsArrayController addObserver:self forKeyPath:@"selection" options:0 context:nil];
   
   self.canRemoveTicket = NO;
   
   [growlApplications setDoubleAction:@selector(tableViewDoubleClick:)];
	[growlApplications setTarget:self];
   
	// bind the app level position picker programmatically since its a custom view, register for notification so we can handle updating manually
	[appPositionPicker bind:@"selectedPosition" 
                  toObject:ticketsArrayController 
               withKeyPath:@"selection.selectedPosition" 
                   options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:NSRaisesForNotApplicableKeysBindingOption]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePosition:) name:GrowlPositionPickerChangedSelectionNotification object:appPositionPicker];
      
   [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(translateSeparatorsInMenu:)
                                                name:NSPopUpButtonWillPopUpNotification
                                              object:soundMenuButton];
   if([[ticketsArrayController arrangedObjects] count] > 1)
      [ticketsArrayController setSelectionIndex:1];
}

+ (NSString*)nibName {
   return @"ApplicationPrefs";
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
      if([self tableView:growlApplications isGroupRow:[ticketsArrayController selectionIndex]])
         return;
      
      [self setCanRemoveTicket:[ticketsArrayController canRemove]];
      [[self prefPane] populateDisplaysPopUpButton:displayMenuButton nameOfSelectedDisplay:[[ticketsArrayController selection] valueForKey:@"displayPluginName"] includeDefaultMenuItem:YES];
		[[self prefPane] populateDisplaysPopUpButton:notificationDisplayMenuButton nameOfSelectedDisplay:[[notificationsArrayController selection] valueForKey:@"displayPluginName"] includeDefaultMenuItem:YES];
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

- (void)selectApplication:(NSString*)appName hostName:(NSString*)hostName
{
   if(!appName)
      return;

   __block NSUInteger index = NSNotFound;
   [[ticketsArrayController arrangedObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([[obj applicationName] caseInsensitiveCompare:appName] == NSOrderedSame){
         if(!hostName && [obj isLocalHost]){
            index = idx;
            *stop = YES;
         }else if(hostName && [obj hostName] && [[obj hostName] caseInsensitiveCompare:hostName]){
            index = idx;
            *stop = YES;
         }
      }
   }];
   
   if(index != NSNotFound){
      [ticketsArrayController setSelectionIndex:index];
      [self showApplicationConfigurationTab:nil];
   }
}

- (IBAction) showApplicationConfigurationTab:(id)sender {
	if ([ticketsArrayController selectionIndex] != NSNotFound) {

	}
}

- (IBAction) changeNameOfDisplayForApplication:(id)sender {
	NSString *newDisplayPluginName = [[sender selectedItem] representedObject];
	[[ticketsArrayController selection] setValue:newDisplayPluginName forKey:@"displayPluginName"];
	[self showPreview:sender];
}
- (IBAction) changeNameOfDisplayForNotification:(id)sender {
	NSString *newDisplayPluginName = [[sender selectedItem] representedObject];
	[[notificationsArrayController selection] setValue:newDisplayPluginName forKey:@"displayPluginName"];
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

- (BOOL)tableView:(NSTableView*)tableView isGroupRow:(NSInteger)row
{
   if(tableView == growlApplications)
      return [[[ticketsArrayController arrangedObjects] objectAtIndex:row] isKindOfClass:[NSString class]];
   else
      return NO;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
   return ![self tableView:aTableView isGroupRow:rowIndex];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
   return [[ticketsArrayController arrangedObjects] count];
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
   if(aTableColumn == applicationsNameAndIconColumn || [self tableView:aTableView isGroupRow:rowIndex]){
      return [[ticketsArrayController arrangedObjects] objectAtIndex:rowIndex];
   }
   return nil;
}

-(NSView*)tableView:(NSTableView*)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
   if(tableColumn == applicationsNameAndIconColumn){
      NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"ApplicationCellView" owner:self];
      return cellView;
   }else if([self tableView:tableView isGroupRow:row]){
      NSTableCellView *groupView = [tableView makeViewWithIdentifier:@"HostCellView" owner:self];
      return groupView;
   }
   return nil;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
   if(showSearch && row == 0)
      return 24.0;
   if([self tableView:tableView isGroupRow:row])
      return 20.0;
   return 32.0;
}

- (void) tableViewDidClickInBody:(NSTableView*)tableView{
   [self setCanRemoveTicket:[ticketsArrayController canRemove]];
}

- (IBAction) tableViewDoubleClick:(id)sender {
	[self showApplicationConfigurationTab:sender];
}

@end
