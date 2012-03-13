//
//  GrowlApplicationsViewController.m
//  Growl
//
//  Created by Daniel Siemer on 11/9/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlApplicationsViewController.h"
#import "GrowlPositionPicker.h"
#import "GroupedArrayController.h"
#import "GroupController.h"
#import "GrowlTicketDatabase.h"
#import "GrowlTicketDatabaseApplication.h"
#import "GrowlTicketDatabaseAction.h"
#import "GrowlPreferencePane.h"
#import "GrowlNotificationSettingsCellView.h"
#import "GrowlOnSwitch.h"
#import "NSStringAdditions.h"

static BOOL awoken = NO;

@interface GrowlHostNameTransformer : NSValueTransformer

@end

@implementation GrowlHostNameTransformer

+ (void)load
{
   if (self == [GrowlHostNameTransformer class]) {
      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
      [self setValueTransformer:[[[self alloc] init] autorelease]
                        forName:@"GrowlHostNameTransformer"];
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
   if([value isLocalHost])
		return NSLocalizedString(@"Local", @"Title for section containing apps from the local machine");
	else
		return value;
}

@end

@implementation GrowlApplicationsViewController

@synthesize growlApplications;
@synthesize notificationsTable;
@synthesize applicationsNameAndIconColumn;
@synthesize ticketDatabase;
@synthesize ticketsArrayController;
@synthesize displayPluginsArrayController;
@synthesize actionConfigsArrayController;
@synthesize notificationsArrayController;
@synthesize appSettingsTabView;
@synthesize appOnSwitch;
@synthesize appPositionPicker;
@synthesize soundMenuButton;
@synthesize displayMenuButton;
@synthesize notificationDisplayMenuButton;
@synthesize actionMenuButton;
@synthesize notificationActionMenuButton;
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
	self.ticketsArrayController = [[[GroupedArrayController alloc] initWithEntityName:@"GrowlApplicationTicket" 
																					  basePredicateString:@"" 
																									 groupKey:@"parent.name"
																					 managedObjectContext:[[GrowlTicketDatabase sharedInstance] managedObjectContext]] autorelease];
	
	NSSortDescriptor *ascendingName = [NSSortDescriptor sortDescriptorWithKey:@"name" 
																						 ascending:YES 
																						  selector:@selector(caseInsensitiveCompare:)];
	[[ticketsArrayController countController] setSortDescriptors:[NSArray arrayWithObject:ascendingName]];
	[ticketsArrayController setDelegate:self];
	[ticketsArrayController setDoNotShowSingleGroupHeader:YES];
	NSComparator compareBlock = ^(id obj1, id obj2){
		NSString *id1 = [obj1 groupID];
		NSString *id2 = [obj2 groupID];
		NSComparisonResult result = NSOrderedSame;
		if([id1 caseInsensitiveCompare:id2] == NSOrderedSame){
			result = NSOrderedSame;
		}else if([id1 isLocalHost]){
			result = NSOrderedAscending;
		}else if([id2 isLocalHost]){
			result = NSOrderedDescending;
		}else{
			result = [id1 caseInsensitiveCompare:id2];
		}
		return result;
	};
	[ticketsArrayController	setGroupCompareBlock:compareBlock];
	[ticketsArrayController setTableView:growlApplications];
	
	NSSortDescriptor *ascendingHumanReadable = [NSSortDescriptor sortDescriptorWithKey:@"humanReadableName" ascending:YES];
	[notificationsArrayController setSortDescriptors:[NSArray arrayWithObject:ascendingHumanReadable]];
	
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
	
	__block GrowlApplicationsViewController *blockSelf = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		NSUInteger index = [[blockSelf ticketsArrayController] indexOfFirstNonGroupItem];
		if(index != NSNotFound){
			[[blockSelf growlApplications] selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO]; 
		}
	});

   [notificationsTable setTarget:self];
   [notificationsTable setDoubleAction:@selector(userDoubleClickedNote:)];
}

+ (NSString*)nibName {
   return @"ApplicationPrefs";
}

- (void) viewWillUnload {
	if([[[GrowlTicketDatabase sharedInstance] managedObjectContext] hasChanges])
		[[GrowlTicketDatabase sharedInstance] saveDatabase:YES];
	[super viewWillUnload];
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
   if([keyPath isEqualToString:@"state"] && object == appOnSwitch){
      NSInteger index = [growlApplications selectedRow];
      if(index >= 0 && index < (NSInteger)[[ticketsArrayController arrangedObjects] count]){
         GrowlTicketDatabaseApplication *ticket = [[ticketsArrayController arrangedObjects] objectAtIndex:index];
         if([ticket isKindOfClass:[GrowlTicketDatabaseApplication class]])
         {
            ticket.enabled = [NSNumber numberWithBool:[appOnSwitch state]];
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
		NSUInteger index = [ticketsArrayController indexOfFirstNonGroupItem];
		if(index != NSNotFound)
			[growlApplications selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO]; 
	}
}

- (IBAction)userDoubleClickedNote:(id)sender {
   NSUInteger clicked = [notificationsTable clickedRow];
   [notificationsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:clicked] byExtendingSelection:NO];
   [[notificationsArrayController arrangedObjects] objectAtIndex:clicked];
   NSButton *checkbox = [(GrowlNotificationSettingsCellView*)[notificationsTable viewAtColumn:0 row:clicked makeIfNecessary:YES] enableCheckBox];
   [checkbox setState:([checkbox state] == NSOnState) ? NSOffState : NSOnState];
   [[[checkbox superview] superview] setNeedsDisplay:YES];
}

- (void)updateDefaultDisplay:(BOOL)app {
	NSUInteger noteIndex = [notificationsArrayController selectionIndex];
	GrowlTicketDatabaseTicket *ticket = app ? [ticketsArrayController selection] : [[notificationsArrayController arrangedObjects] objectAtIndex:noteIndex];
	
	NSPopUpButton *popupButton = app ? displayMenuButton : notificationDisplayMenuButton;
	NSInteger index = [popupButton indexOfSelectedItem];
	GrowlTicketDatabaseDisplay *newDefault = nil;
	BOOL useDisplay = YES;
	if(index >= 3 && index - 3 < (NSInteger)[[displayPluginsArrayController arrangedObjects] count]){
		id pluginToUse = [[displayPluginsArrayController arrangedObjects] objectAtIndex:index - 3];
		if(pluginToUse && [pluginToUse isKindOfClass:[GrowlTicketDatabasePlugin class]])
			newDefault = pluginToUse;
	}else if(index == 1){
		useDisplay = NO;
	}
	[ticket setDisplay:newDefault];
	[ticket setUseDisplay:[NSNumber numberWithBool:useDisplay]];
}

- (void)updateDefaultActions:(BOOL)app {
	NSUInteger noteIndex = [notificationsArrayController selectionIndex];
	GrowlTicketDatabaseTicket *ticket = app ? [ticketsArrayController selection] : [[notificationsArrayController arrangedObjects] objectAtIndex:noteIndex];
	
	NSPopUpButton *popupButton = app ? actionMenuButton : notificationActionMenuButton;

	NSInteger index = [popupButton indexOfSelectedItem];
	
	NSInteger prevState = [[popupButton itemAtIndex:index] state];
	NSInteger newState = prevState == NSOnState ? NSOffState : NSOnState;
	switch (index) {
		case 2:
			if(newState == NSOnState){
				//Use no actions whatsoever
				[[popupButton itemArray] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
					[(NSMenuItem*)obj setState:NSOffState];
				}];
				[ticket setUseParentActions:[NSNumber numberWithBool:NO]];
				[ticket setActions:nil];
			}else{
				[ticket setUseParentActions:[NSNumber numberWithBool:YES]];
			}
			break;
		case -1:
		case 0:
		case 3:
			break;
		case 1:
			[ticket setUseParentActions:[NSNumber numberWithBool:(newState == NSOnState)]];
			break;
		default:
			if(index - 4 < (NSInteger)[[actionConfigsArrayController arrangedObjects] count]){
				if(newState == NSOnState){
					[ticket addActionsObject:[[actionConfigsArrayController arrangedObjects] objectAtIndex:index - 4]];
				}else{
					[ticket removeActionsObject:[[actionConfigsArrayController arrangedObjects] objectAtIndex:index - 4]];
				}
			}	
			break;
	}
	[[popupButton itemAtIndex:index] setState:newState];
	if([[ticket actions] count] == 0 && ![[ticket useParentActions] boolValue]){
		[[popupButton itemAtIndex:2] setState:NSOnState];
	}else{
		[[popupButton itemAtIndex:2] setState:NSOffState];
	}
}

- (IBAction) showPreview:(id)sender {
	if(sender == displayMenuButton)
		[self updateDefaultDisplay:YES];
	if(sender == notificationDisplayMenuButton)
		[self updateDefaultDisplay:NO];
	
	if(sender == actionMenuButton)
		[self updateDefaultActions:YES];
	if(sender == notificationActionMenuButton)
		[self updateDefaultActions:NO];
	
	if(([sender isKindOfClass:[NSPopUpButton class]]) && ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask))
		return;
	
	id pluginToUse = nil;
   
	if ([sender isKindOfClass:[NSPopUpButton class]]) {
		if(sender == displayMenuButton || sender == notificationDisplayMenuButton){
			NSUInteger noteIndex = [notificationsArrayController selectionIndex];
			GrowlTicketDatabaseTicket *ticket = (sender == displayMenuButton) ? [ticketsArrayController selection] : [[notificationsArrayController arrangedObjects] objectAtIndex:noteIndex];
			pluginToUse = [ticket resolvedDisplayConfig];
		}else{
			NSUInteger noteIndex = [notificationsArrayController selectionIndex];
			GrowlTicketDatabaseTicket *ticket = (sender == actionMenuButton) ? [ticketsArrayController selection] : [[notificationsArrayController arrangedObjects] objectAtIndex:noteIndex];
			pluginToUse = [ticket resolvedActionConfigSet];
		}
   }
	if(pluginToUse)
		[[NSNotificationCenter defaultCenter] postNotificationName:GrowlPreview
																			 object:pluginToUse];
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
      if([obj isKindOfClass:[GrowlTicketDatabaseApplication class]] && [[obj name] caseInsensitiveCompare:appName] == NSOrderedSame){
         if(needLocal && [[[obj parent] name] isLocalHost]){
            index = idx;
            *stop = YES;
         }else if(!needLocal && [[obj parent] name] && [[[obj parent] name] caseInsensitiveCompare:hostName] == NSOrderedSame){
            index = idx;
            *stop = YES;
         }
      }
   }];
   
   if(index != NSNotFound){
      [growlApplications selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
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

- (NSIndexSet *) selectedNotificationIndexes {
	return selectedNotificationIndexes;
}
- (void) setSelectedNotificationIndexes:(NSIndexSet *)newSelectedNotificationIndexes {
	if(selectedNotificationIndexes != newSelectedNotificationIndexes) {
		[selectedNotificationIndexes release];
		selectedNotificationIndexes = [newSelectedNotificationIndexes copy];
		
		NSUInteger selectedNote = [notificationsArrayController selectionIndex];
		if(selectedNote == NSNotFound)
			return;
		
		[self selectDefaultDisplay:NO];
	}
}

#pragma mark TableView data source methods

- (BOOL)tableView:(NSTableView*)tableView isGroupRow:(NSInteger)row
{
   if(tableView == growlApplications && row >= 0 && row < (NSInteger)[[ticketsArrayController arrangedObjects] count]){
      return [[[ticketsArrayController arrangedObjects] objectAtIndex:row] isKindOfClass:[GroupController class]];
   }else
      return NO;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
   if(aTableView == growlApplications && rowIndex >= 0 && rowIndex < (NSInteger)[[ticketsArrayController arrangedObjects] count]){
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
   if(aTableView == growlApplications && rowIndex >= 0 && rowIndex < (NSInteger)[[ticketsArrayController arrangedObjects] count]){
      return [[ticketsArrayController arrangedObjects] objectAtIndex:rowIndex];
   }
   return nil;
}

-(NSView*)tableView:(NSTableView*)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
   if(tableColumn == applicationsNameAndIconColumn && row >= 0 && row < (NSInteger)[[ticketsArrayController arrangedObjects] count]){
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
   [self setCanRemoveTicket:[[ticketsArrayController selection] isKindOfClass:[GrowlTicketDatabaseApplication class]]];
}

-(void)selectDefaultActions:(BOOL)app {
	__block NSPopUpButton *popupButton = app ? actionMenuButton : notificationActionMenuButton;
	
	[[popupButton itemArray] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		[(NSMenuItem*)obj setState:NSOffState];
	}];
	
	NSUInteger noteIndex = [notificationsArrayController selectionIndex];
	GrowlTicketDatabaseTicket *ticket = app ? [ticketsArrayController selection] : [[notificationsArrayController arrangedObjects] objectAtIndex:noteIndex];
	NSSet *actions = [ticket actions];
	
	__block GrowlApplicationsViewController *blockSelf = self;
	__block NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
	[actions enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
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
	if([indexSet count] == 0 && ![[ticket useParentActions] boolValue]){
		[[popupButton itemAtIndex:2] setState:NSOnState];
	}else{
		[indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
			[[popupButton itemAtIndex:idx + 4] setState:NSOnState];
		}];
		if([[ticket useParentActions] boolValue])
			[[popupButton itemAtIndex:1] setState:NSOnState];
	}
}

-(void)selectDefaultDisplay:(BOOL)app {
	NSUInteger noteIndex = [notificationsArrayController selectionIndex];
	GrowlTicketDatabaseTicket *ticket = app ? [ticketsArrayController selection] : [[notificationsArrayController arrangedObjects] objectAtIndex:noteIndex];
	GrowlTicketDatabaseDisplay *display = [ticket display];
		
	NSUInteger index = NSNotFound;
	NSPopUpButton *popupButton = app ? displayMenuButton : notificationDisplayMenuButton;
	index = [[displayPluginsArrayController arrangedObjects] indexOfObject:display];
	if(index != NSNotFound){
		[popupButton selectItemAtIndex:index + 3];
	}else{
		if(!ticket || [[ticket useDisplay] boolValue])
		//Handle the no display case as well in here, but for now just say no default
			[popupButton selectItemAtIndex:0];
		else
			[popupButton selectItemAtIndex:1];
	}
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification {
	NSInteger index = [growlApplications selectedRow];
	if(index >= 0 && index < (NSInteger)[[ticketsArrayController arrangedObjects] count]){
		id ticket = [[ticketsArrayController arrangedObjects] objectAtIndex:index];
		[self setCanRemoveTicket:[ticket isKindOfClass:[GrowlTicketDatabaseApplication class]]];
		if([ticket isKindOfClass:[GrowlTicketDatabaseApplication class]])
		{
			self.enableApplicationLabel = [NSString stringWithFormat:NSLocalizedString(@"Enable %@", @"Label for application on/off switch"), [ticket name]];
			[displayMenuButton setEnabled:YES];
			[notificationDisplayMenuButton setEnabled:YES];
			[self selectDefaultDisplay:YES];
			
			//Give it a chance to update its contents before trying to tell it to arrange.
			__block GrowlApplicationsViewController *blockSelf = self;
			dispatch_async(dispatch_get_main_queue(), ^{
				[[blockSelf notificationsArrayController] rearrangeObjects];
				[blockSelf selectDefaultDisplay:NO];
				[blockSelf selectDefaultActions:YES];
				[blockSelf selectDefaultActions:NO];
			});
			if([[[GrowlTicketDatabase sharedInstance] managedObjectContext] hasChanges])
				[[GrowlTicketDatabase sharedInstance] saveDatabase:YES];
		}
	}else{
		if([[ticketsArrayController arrangedObjects] count]){
			NSUInteger first = [ticketsArrayController indexOfFirstNonGroupItem];
			if(first != NSNotFound)
				[growlApplications selectRowIndexes:[NSIndexSet indexSetWithIndex:first] byExtendingSelection:NO];
		}
		[appOnSwitch setState:NO];
		[displayMenuButton setEnabled:NO];
		[notificationDisplayMenuButton setEnabled:NO];
	}
}

@end
