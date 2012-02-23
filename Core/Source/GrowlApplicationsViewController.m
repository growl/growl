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
#import "GrowlTicketDatabase.h"
#import "GrowlTicketDatabaseApplication.h"
#import "GrowlPreferencePane.h"
#import "GrowlNotificationSettingsCellView.h"
#import "GrowlOnSwitch.h"
#import "NSStringAdditions.h"

static BOOL awoken = NO;

@implementation GrowlApplicationsViewController

@synthesize growlApplications;
@synthesize notificationsTable;
@synthesize applicationsNameAndIconColumn;
@synthesize ticketDatabase;
@synthesize ticketsArrayController;
@synthesize notificationsArrayController;
@synthesize appSettingsTabView;
@synthesize appOnSwitch;
@synthesize appPositionPicker;
@synthesize soundMenuButton;
@synthesize displayMenuButton;
@synthesize notificationDisplayMenuButton;
@synthesize selectedNotificationIndexes;

@synthesize applicationScrollView;
@synthesize demoSound;
@synthesize canRemoveTicket;

@synthesize getApplicationsTitle;
@synthesize enableApplicationLabel;
@synthesize enableLoggingLabel;
@synthesize applicationDefaultStyleLabel;
@synthesize applicationSettingsTabLabel;
@synthesize notificationSettingsTabLabel;
@synthesize defaultStartPositionLabel;
@synthesize customStartPositionLabel;
@synthesize noteDisplayStyleLabel;
@synthesize stayOnScreenLabel;
@synthesize priorityLabel;
@synthesize playSoundLabel;
@synthesize stayOnScreenNever;
@synthesize stayOnScreenAlways;
@synthesize stayOnScreenAppDecides;
@synthesize priorityLow;
@synthesize priorityModerate;
@synthesize priorityNormal;
@synthesize priorityHigh;
@synthesize priorityEmergency;

-(void)dealloc {
   [ticketsArrayController removeObserver:self forKeyPath:@"selection"];
   [appOnSwitch removeObserver:self forKeyPath:@"state"];
   [demoSound release];
   
   [enableApplicationLabel release];
   [enableLoggingLabel release];
   [applicationDefaultStyleLabel release];
   [applicationSettingsTabLabel release];
   [notificationSettingsTabLabel release];
   [defaultStartPositionLabel release];
   [customStartPositionLabel release];
   [noteDisplayStyleLabel release];
   [stayOnScreenLabel release];
   [priorityLabel release];
   [playSoundLabel release];
   [stayOnScreenNever release];
   [stayOnScreenAlways release];
   [stayOnScreenAppDecides release];
   [priorityLow release];
   [priorityModerate release];
   [priorityNormal release];
   [priorityHigh release];
   [priorityEmergency release];
   [super dealloc];
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil forPrefPane:(GrowlPreferencePane *)aPrefPane
{
   if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil forPrefPane:aPrefPane])){
      self.ticketDatabase = [GrowlTicketDatabase sharedInstance];
      
      self.getApplicationsTitle = NSLocalizedString(@"Get Applications", @"Label for button which will open to growl.info with information on applications and how to configure them");
      self.enableApplicationLabel = NSLocalizedString(@"Enable application", @"Label for application on/off switch");
      self.enableLoggingLabel = NSLocalizedString(@"Enable Logging", @"Label for checkbox which enables logging for a note or application");
      self.applicationDefaultStyleLabel = NSLocalizedString(@"Application's Display Style", @"Label for application level display style choice");
      self.applicationSettingsTabLabel = NSLocalizedString(@"Application", @"Label for the tab which contains application settings");
      self.notificationSettingsTabLabel = NSLocalizedString(@"Notifications", @"Label for the tab which contains notification settings");
      self.defaultStartPositionLabel = NSLocalizedString(@"Use default starting position", @"label for using the global default starting position");
      self.customStartPositionLabel = NSLocalizedString(@"Use custom starting position", @"label for using a custom application wide starting position");
      self.noteDisplayStyleLabel = NSLocalizedString(@"Display Style:", @"Label for the display style of the selected notification");
      self.stayOnScreenLabel = NSLocalizedString(@"Stay On Screen:", @"Label for choosing whether the selected note stays on screen");
      self.priorityLabel = NSLocalizedString(@"Priority:", @"Label for choosing priority of the selected notification");
      self.playSoundLabel = NSLocalizedString(@"Play Sound:", @"Label for choosing which sound plays for the selected notification");
      self.stayOnScreenNever = NSLocalizedString(@"Never", @"Notification will never stay on screen");
      self.stayOnScreenAlways = NSLocalizedString(@"Always", @"Notification always stay on screen");
      self.stayOnScreenAppDecides = NSLocalizedString(@"Application Decides", @"Application decides whether a note should stay on screen");
      self.priorityLow = NSLocalizedString(@"Very Low", @"Very low notification priority");
      self.priorityModerate = NSLocalizedString(@"Moderate", @"Moderate notification priority");
      self.priorityNormal = NSLocalizedString(@"Normal", @"Normal notification priority");
      self.priorityHigh = NSLocalizedString(@"High", @"High notification priority");
      self.priorityEmergency = NSLocalizedString(@"Emergency", @"Emergency notification priority");
   }
   return self;
}

-(void)awakeFromNib {
   if(awoken)
      return;
   
   awoken = YES;
   [ticketsArrayController addObserver:self forKeyPath:@"selection" options:0 context:nil];
   [appOnSwitch addObserver:self forKeyPath:@"state" options:0 context:nil];
   [appSettingsTabView selectTabViewItemAtIndex:0];

   self.canRemoveTicket = NO;
   
	[growlApplications setTarget:self];
   
	// bind the app level position picker programmatically since its a custom view, register for notification so we can handle updating manually
	[appPositionPicker bind:@"selectedPosition" 
                  toObject:ticketsArrayController 
               withKeyPath:@"selection.selectedPosition" 
                   options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:NSRaisesForNotApplicableKeysBindingOption]];
	
   [appOnSwitch bind:@"state"
            toObject:ticketsArrayController 
         withKeyPath:@"selection.enabled"
             options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:NSRaisesForNotApplicableKeysBindingOption]];
   
   [[NSNotificationCenter defaultCenter] addObserver:self 
                                            selector:@selector(updatePosition:) 
                                                name:GrowlPositionPickerChangedSelectionNotification 
                                              object:appPositionPicker];
      
   [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(translateSeparatorsInMenu:)
                                                name:NSPopUpButtonWillPopUpNotification
                                              object:soundMenuButton];
   [ticketsArrayController selectFirstApplication];
   
   [notificationsTable setTarget:self];
   [notificationsTable setAction:@selector(userSingleClickedNote:)];
   [notificationsTable setDoubleAction:@selector(userDoubleClickedNote:)];
}

+ (NSString*)nibName {
   return @"ApplicationPrefs";
}

- (void) updatePosition:(NSNotification *)notification {
	if([notification object] == appPositionPicker) {
		// a cheap hack around selection not providing a workable object
		NSArray *selection = [ticketsArrayController selectedObjects];
		if ([selection count] > 0 && [[selection objectAtIndex:0] respondsToSelector:@selector(setSelectedPosition:)])
			[(GrowlTicketDatabaseApplication*)[selection objectAtIndex:0] setSelectedPosition:[NSNumber numberWithInteger:[appPositionPicker selectedPosition]]];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
   if([keyPath isEqualToString:@"selection"] && object == ticketsArrayController) {
      NSUInteger index = [ticketsArrayController selectionIndex];
      if(index != NSNotFound){
         id ticket = [[ticketsArrayController arrangedObjects] objectAtIndex:index];
         if([ticket isKindOfClass:[GrowlTicketDatabaseApplication class]])
         {
            self.enableApplicationLabel = [NSString stringWithFormat:NSLocalizedString(@"Enable %@", @"Label for application on/off switch"), [ticket name]];
            [self setCanRemoveTicket:[ticketsArrayController canRemove]];
            [displayMenuButton setEnabled:YES];
            [notificationDisplayMenuButton setEnabled:YES];
            /*[[self prefPane] populateDisplaysPopUpButton:displayMenuButton 
                                   nameOfSelectedDisplay:[ticket valueForKey:@"displayPluginName"] 
                                  includeDefaultMenuItem:YES];
            [[self prefPane] populateDisplaysPopUpButton:notificationDisplayMenuButton 
                                   nameOfSelectedDisplay:[ticket valueForKey:@"displayPluginName"] 
                                  includeDefaultMenuItem:YES];*/
         }
      }else{
         [appOnSwitch setState:NO];
         [displayMenuButton setEnabled:NO];
         [notificationDisplayMenuButton setEnabled:NO];
      }
   }
   if([keyPath isEqualToString:@"state"] && object == appOnSwitch){
      NSUInteger index = [ticketsArrayController selectionIndex];
      if(index != NSNotFound){
         id ticket = [[ticketsArrayController arrangedObjects] objectAtIndex:index];
         if([ticket isKindOfClass:[GrowlApplicationTicket class]])
         {
            [ticket setTicketEnabled:[appOnSwitch state]];
         }
      }
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

- (IBAction)getApplications:(id)sender {
   [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.growl.info/applications.php"]];
}

- (void) deleteTicket:(id)sender {
   if(![[[ticketsArrayController selectedObjects] objectAtIndex:0U] isKindOfClass:[GrowlTicketDatabaseApplication class]])
      return;
   
	NSString *appName = [[[ticketsArrayController selectedObjects] objectAtIndex:0U] name];
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
		GrowlTicketDatabaseApplication *ticket = [[ticketsArrayController selectedObjects] objectAtIndex:0U];
      [ticketDatabase removeTicketForApplicationName:ticket.name hostName:ticket.parent.name];
      [growlApplications noteNumberOfRowsChanged];
      [ticketsArrayController selectFirstApplication];
	}
}


- (IBAction)userSingleClickedNote:(id)sender {
   /*if([notificationsTable clickedRow] == [notificationsTable selectedRow]){
      NSLog(@"Match!");
      NSButton *checkbox = [(GrowlNotificationSettingsCellView*)[notificationsTable viewAtColumn:0 row:[notificationsTable clickedRow] makeIfNecessary:YES] enableCheckBox];
      [checkbox setState:([checkbox state] == NSOnState) ? NSOffState : NSOnState];
      [[[checkbox superview] superview] setNeedsDisplay:YES];
   }*/
}
- (IBAction)userDoubleClickedNote:(id)sender {
   NSUInteger clicked = [notificationsTable clickedRow];
   [notificationsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:clicked] byExtendingSelection:NO];
   [[notificationsArrayController arrangedObjects] objectAtIndex:clicked];
   NSButton *checkbox = [(GrowlNotificationSettingsCellView*)[notificationsTable viewAtColumn:0 row:clicked makeIfNecessary:YES] enableCheckBox];
   [checkbox setState:([checkbox state] == NSOnState) ? NSOffState : NSOnState];
   [[[checkbox superview] superview] setNeedsDisplay:YES];
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

- (void)selectApplication:(NSString*)appName hostName:(NSString*)hostName notificationName:(NSString*)noteNameOrNil
{
   if(!appName)
      return;

   __block NSUInteger index = NSNotFound;
   BOOL needLocal = (!hostName || [hostName isLocalHost]);
   [[ticketsArrayController arrangedObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([obj isKindOfClass:[GrowlApplicationTicket class]] && [[obj name] caseInsensitiveCompare:appName] == NSOrderedSame){
         if(needLocal && [obj isLocalHost]){
            index = idx;
            *stop = YES;
         }else if(!needLocal && [obj hostName] && [[obj hostName] caseInsensitiveCompare:hostName] == NSOrderedSame){
            index = idx;
            *stop = YES;
         }
      }
   }];
   
   if(index != NSNotFound){
      [ticketsArrayController setSelectionIndex:index];
      [growlApplications scrollRowToVisible:index];
      if(noteNameOrNil){
         __block NSUInteger noteIndex = NSNotFound;
         [[notificationsArrayController arrangedObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if([[obj name] caseInsensitiveCompare:noteNameOrNil] == NSOrderedSame){
               noteIndex = idx;
               *stop = YES;
            }
         }];
         
         if(noteIndex != NSNotFound){
            [appSettingsTabView selectTabViewItemAtIndex:1];
            [notificationsArrayController setSelectionIndex:noteIndex];
            [notificationsTable scrollRowToVisible:noteIndex];
         }else{
            NSLog(@"Count not find notification %@ for application named %@ on host %@", noteNameOrNil, appName, hostName);
         }
      }else{
         [appSettingsTabView selectTabViewItemAtIndex:0];
      }
   }else{
      NSLog(@"Could not find application named %@ on host %@", appName, hostName);
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
   if(tableView == growlApplications){
      return [[[ticketsArrayController arrangedObjects] objectAtIndex:row] isKindOfClass:[NSString class]];
   }else
      return NO;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
   if(aTableView == growlApplications){
      return ![self tableView:aTableView isGroupRow:rowIndex];
   }
   return YES;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
   if(tableView == growlApplications){
      return [[ticketsArrayController arrangedObjects] count];
   }
   return 0;
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
   if([self tableView:tableView isGroupRow:row])
      return 20.0;
   return 36.0;
}

- (void) tableViewDidClickInBody:(NSTableView*)tableView{
   [self setCanRemoveTicket:[ticketsArrayController canRemove]];
}

@end
