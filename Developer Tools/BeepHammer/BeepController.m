#import "BeepController.h"
#import "BeepAdditions.h"

#define GROWL_NOTIFICATION_DEFAULT @"NotificationDefault"
#define GROWL_PREFS_PATH [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/com.Growl.GrowlHelperApp.plist"]

#define CLICK_RECEIVED_NOTIFICATION_NAME @"BeepHammer Click Received"
#define CLICK_TIMED_OUT_NOTIFICATION_NAME @"BeepHammer Click Timed Out"

@interface BeepController (PRIVATE)
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;

- (void)notificationsDidChange;
@end

@implementation BeepController

- (id) init {
    if ((self = [super init])) {
        notifications = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) dealloc {
	[notificationPanel       release];
	[notificationDefault     release];
	[notificationSticky      release];
	[notificationPriority    release];
	[notificationDescription release];
	[notificationImage       release];
	[notificationTitle       release];
	[addEditButton           release];

	[addButtonTitle  release];
	[editButtonTitle release];
	[mainEditButtonTitle release];

	[mainWindow         release];
	[notificationsTable release];
	[addNotification    release];
	[removeNotification release];
	[sendButton         release];

    [notifications release];

	[super dealloc];
}

- (void) awakeFromNib {
	[notificationsTable setDoubleAction:@selector(showEditSheet:)];
	[self tableViewSelectionDidChange:nil];

	addButtonTitle  = [[addEditButton title] retain]; //this is the default title in the nib
	editButtonTitle = [NSLocalizedString(@"Save", /*comment*/ NULL) retain];
	mainEditButtonTitle = [NSLocalizedString(@"Edit", /*comment*/ NULL) retain];
	
	[mainEditButton setTitle:mainEditButtonTitle];

	[GrowlApplicationBridge setGrowlDelegate:self];
	
#pragma mark This is a cheap hack to work with the preference
	NSDictionary *prefsDict = [NSDictionary dictionaryWithContentsOfFile:GROWL_PREFS_PATH];
	[growlLoggingButton setState:[[prefsDict valueForKey:@"GrowlLoggingEnabled"] intValue]];
}

- (IBAction)toggleGrowlLogging:(id)sender
{
#pragma mark This is a cheap hack to work with the preference
	NSMutableDictionary *prefsDict = [NSMutableDictionary dictionaryWithContentsOfFile:GROWL_PREFS_PATH];
	[prefsDict setObject:[NSNumber numberWithInt:[sender state]] forKey:@"GrowlLoggingEnabled"];
	[prefsDict writeToFile:GROWL_PREFS_PATH atomically:NO];
}

- (IBAction)editNotification:(id)sender
{
	[self  showEditSheet:self];
}

#pragma mark Main window actions

- (IBAction)showAddSheet:(id)sender {
#pragma unused(sender)
	//reset controls to default values
	[notificationDefault     setState:NSOnState];
	[notificationSticky      setState:NSOffState];
	[notificationPriority    selectItemAtIndex:2]; //middle item: 'Normal' priority
	[notificationImage       setImage:nil];
	[notificationDescription setStringValue:@""];
	[notificationTitle       setStringValue:@""];
	[notificationIdentifier  setStringValue:@""];

	[notificationPanel makeFirstResponder:[notificationPanel initialFirstResponder]];
	[addEditButton setTitle:addButtonTitle];
	[NSApp beginSheet:notificationPanel
	   modalForWindow:mainWindow
		modalDelegate:self
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo:nil];
}

- (IBAction)showEditSheet:(id)sender {
#pragma unused(sender)
	int index = [notificationsTable selectedRow];
	if (index < 0)
		NSBeep();
	else {
		NSDictionary *dict = [notifications objectAtIndex:index];
		[notificationDefault     setState:      [dict stateForKey:GROWL_NOTIFICATION_DEFAULT]];
		[notificationSticky      setState:      [dict stateForKey:GROWL_NOTIFICATION_STICKY]];
		int priority = [[dict objectForKey:GROWL_NOTIFICATION_PRIORITY] intValue];
		[notificationPriority    selectItemAtIndex:[notificationPriority indexOfItemWithTag:priority]];
		[notificationImage       setImage:      [dict objectForKey:GROWL_NOTIFICATION_ICON]];
		[notificationDescription setStringValue:[dict objectForKey:GROWL_NOTIFICATION_DESCRIPTION]];
		[notificationTitle       setStringValue:[dict objectForKey:GROWL_NOTIFICATION_TITLE]];
		[notificationIdentifier  setStringValue:([dict objectForKey:GROWL_NOTIFICATION_IDENTIFIER] ?
												 [dict objectForKey:GROWL_NOTIFICATION_IDENTIFIER] :
												 @"")];
		[notificationClickContext setStringValue:([dict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT] ?: @"")];

		[notificationPanel makeFirstResponder:[notificationPanel initialFirstResponder]];
		[addEditButton setTitle:editButtonTitle];

		[NSApp beginSheet:notificationPanel
		   modalForWindow:mainWindow
			modalDelegate:self
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:[[NSNumber alloc] initWithInt:index]];
	}
}

- (IBAction)removeNotification:(id)sender {
#pragma unused(sender)
	int selectedRow = [notificationsTable selectedRow];
	if (selectedRow < 0) {
		//no selection
		NSBeep();
		return;
	} else {
		[notifications removeObjectAtIndex:selectedRow];
		[notificationsTable reloadData];
	}

	[self notificationsDidChange];
}

- (IBAction)removeAllNotifications:(id)sender
{
	[notifications removeAllObjects];
	[notificationsTable reloadData];
	[self notificationsDidChange];
}

- (IBAction)sendNotification:(id)sender {
#pragma unused(sender)
	int selectedRow = [notificationsTable selectedRow];

	if (selectedRow != -1){
		int batchCount = ([batchCountField intValue] > 0 ? [batchCountField intValue] : 1); // always 1
		
		if([groupingType selectedRow] == 0)
		{
			// loop through and send the appropriate number of notifications
			while(batchCount > 0)
			{
				//send a notification for the selected table cell
				NSDictionary *note = [notifications objectAtIndex:selectedRow];
				
				NSLog(@"note - %@", note);
				[GrowlApplicationBridge notifyWithTitle:[note objectForKey:GROWL_NOTIFICATION_TITLE]
											description:[note objectForKey:GROWL_NOTIFICATION_DESCRIPTION]
									   notificationName:[note objectForKey:GROWL_NOTIFICATION_NAME]
											   iconData:[note objectForKey:GROWL_NOTIFICATION_ICON]
											   priority:[[note objectForKey:GROWL_NOTIFICATION_PRIORITY] intValue]
											   isSticky:[[note objectForKey:GROWL_NOTIFICATION_STICKY] boolValue]
										   clickContext:(([note objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT] && [[note objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT] length])
														 ? [note objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT]
														 : nil)
											 identifier:([[note objectForKey:GROWL_NOTIFICATION_IDENTIFIER] length] ?
														 [note objectForKey:GROWL_NOTIFICATION_IDENTIFIER] :
														 nil)];	
				
				batchCount--;
			}
		}
		else if([groupingType selectedRow] == 1)
		{
			// loop through and send the appropriate number of notifications
			while(batchCount > 0)
			{
				for(int currentRow = 0; currentRow < [notifications count]; currentRow++)
				{
					//send a notification for the row
					NSDictionary *note = [notifications objectAtIndex:currentRow];
					
					[GrowlApplicationBridge notifyWithTitle:[note objectForKey:GROWL_NOTIFICATION_TITLE]
												description:[note objectForKey:GROWL_NOTIFICATION_DESCRIPTION]
										   notificationName:[note objectForKey:GROWL_NOTIFICATION_NAME]
												   iconData:[note objectForKey:GROWL_NOTIFICATION_ICON]
												   priority:[[note objectForKey:GROWL_NOTIFICATION_PRIORITY] intValue]
												   isSticky:[[note objectForKey:GROWL_NOTIFICATION_STICKY] boolValue]
											   clickContext:nil
												 identifier:([[note objectForKey:GROWL_NOTIFICATION_IDENTIFIER] length] ?
															 [note objectForKey:GROWL_NOTIFICATION_IDENTIFIER] :
															 nil)];
				}
				
				batchCount--;
			}
		}
	}
}

#pragma mark Add/Edit sheet actions

- (IBAction)clearImage:(id)sender {
	[notificationImage setImage:nil];
}

- (IBAction)OKNotification:(id)sender {
	[NSApp endSheet:[sender window] returnCode:NSOKButton];
}

- (IBAction)cancelNotification:(id)sender {
	[NSApp endSheet:[sender window] returnCode:NSCancelButton];
}

- (void) sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if (returnCode == NSOKButton) {
		NSNumber *defaultValue = [NSNumber numberWithBool:[notificationDefault  state] == NSOnState];
		NSNumber *stickyValue  = [NSNumber numberWithBool:[notificationSticky   state] == NSOnState];
		NSNumber *priority     = [NSNumber numberWithInt:[[notificationPriority selectedItem] tag]];
		NSImage  *image        = [notificationImage image];
		NSString *title        = [notificationTitle       stringValue];
		NSString *desc         = [notificationDescription stringValue];
		NSString *identifier   = [notificationIdentifier  stringValue];
		NSString *clickContext = [notificationClickContext stringValue];

		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
			title,         GROWL_NOTIFICATION_NAME,
			title,         GROWL_NOTIFICATION_TITLE,
			desc,          GROWL_NOTIFICATION_DESCRIPTION,
			identifier,    GROWL_NOTIFICATION_IDENTIFIER,
			clickContext,  GROWL_NOTIFICATION_CLICK_CONTEXT,
			priority,      GROWL_NOTIFICATION_PRIORITY,
			defaultValue,  GROWL_NOTIFICATION_DEFAULT,
			stickyValue,   GROWL_NOTIFICATION_STICKY,
			image,         GROWL_NOTIFICATION_ICON, /* May be nil, ending the dict */
			nil];

		NSNumber *indexNum = contextInfo;
		if (indexNum) {
			[notifications replaceObjectAtIndex:[indexNum unsignedIntValue]
									 withObject:dict];
			[indexNum release];
		} else {
			[notifications addObject:dict];
		}

		[notificationsTable reloadData];
	}

	[sheet orderOut:self];

	[self notificationsDidChange];
}

//After notifications change, tell the app bridge to re-register us with Growl so it knows about the new notifications
- (void)notificationsDidChange
{
	[GrowlApplicationBridge reregisterGrowlNotifications];
}

#pragma mark Table Data Source Methods

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
#pragma unused(tableView)
    return [notifications count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)col row:(int)row {
#pragma unused(tableView, col, row)
    return [[notifications objectAtIndex:row] objectForKey:GROWL_NOTIFICATION_NAME];
}

#pragma mark Table Delegate Methods

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)col row:(int)row {
#pragma unused(tableView, col, row)
    return NO;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
#pragma unused(notification)
	BOOL rowIsSelected = ([notificationsTable selectedRow] != -1);

	[sendButton setEnabled:rowIsSelected];
	[batchCountField setEnabled:rowIsSelected];
	[groupingType setEnabled:rowIsSelected];
	[removeNotification setEnabled:rowIsSelected];
	[mainEditButton setEnabled:rowIsSelected];
}

#pragma mark NSApplication Delegate Methods

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)app {
	return YES;
}

#pragma mark Growl Delegate methods

- (NSString *)applicationNameForGrowl {
	return @"BeepHammer";
}

//Return the registration dictionary
- (NSDictionary *)registrationDictionaryForGrowl {

	NSMutableArray *defNotesArray = [NSMutableArray array];
	NSMutableArray *allNotesArray = [NSMutableArray array];
	NSNumber *isDefaultNum;
	unsigned numNotifications = [notifications count];

	//Build an array of all notifications we want to use
	for (unsigned i = 0U; i < numNotifications; ++i) {
		NSDictionary *def = [notifications objectAtIndex:i];
		[allNotesArray addObject:[def objectForKey:GROWL_NOTIFICATION_NAME]];

		isDefaultNum = [def objectForKey:GROWL_NOTIFICATION_DEFAULT];
		if (isDefaultNum && [isDefaultNum boolValue])
			[defNotesArray addObject:[NSNumber numberWithUnsignedInt:i]];
	}

	[allNotesArray addObject:CLICK_RECEIVED_NOTIFICATION_NAME];
	[allNotesArray addObject:CLICK_TIMED_OUT_NOTIFICATION_NAME];

	//Set these notifications both for ALL (all possibilites) and DEFAULT (the ones enabled by default)
	NSDictionary *regDict = [NSDictionary dictionaryWithObjectsAndKeys:
		allNotesArray, GROWL_NOTIFICATIONS_ALL,
		defNotesArray, GROWL_NOTIFICATIONS_DEFAULT,
		nil];

	NSLog(@"Registering with %@",regDict);
	return regDict;
}

- (void)growlIsReady {
	// NSLog(@"Growl engaged, Captain!");
}

- (void) growlNotificationWasClicked:(id)clickContext {
	[GrowlApplicationBridge notifyWithTitle:NSLocalizedString(CLICK_RECEIVED_NOTIFICATION_NAME, /*comment*/ @"Notification titles")
								description:clickContext
						   notificationName:CLICK_RECEIVED_NOTIFICATION_NAME
								   iconData:nil
								   priority:0
								   isSticky:NO
							   clickContext:nil];
}
- (void) growlNotificationTimedOut:(id)clickContext {
	[GrowlApplicationBridge notifyWithTitle:NSLocalizedString(CLICK_TIMED_OUT_NOTIFICATION_NAME, /*comment*/ @"Notification titles")
								description:clickContext
						   notificationName:CLICK_TIMED_OUT_NOTIFICATION_NAME
								   iconData:nil
								   priority:0
								   isSticky:NO
							   clickContext:nil];
}

@end

