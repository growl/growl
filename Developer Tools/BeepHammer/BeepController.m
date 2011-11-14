#import "BeepController.h"
#import "BeepAdditions.h"

#define GROWL_NOTIFICATION_DEFAULT @"NotificationDefault"
#define GROWL_PREFS_PATH [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/com.Growl.GrowlHelperApp.plist"]

#define CLICK_RECEIVED_NOTIFICATION_NAME @"BeepHammer Click Received"
#define CLICK_TIMED_OUT_NOTIFICATION_NAME @"BeepHammer Click Timed Out"


@interface BeepController (PRIVATE)
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;

- (void)notificationsDidChange;

- (void) notificationEditorDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
@end

@implementation BeepController {
	IBOutlet NSPanel		*notificationPanel;			// The Add/Edit Panel
	IBOutlet NSButton		*notificationDefault;		// Whether this notification is allowed by default
	IBOutlet NSButton		*notificationSticky;		// Whether this notification is sticky
	IBOutlet NSPopUpButton	*notificationPriority;		// Priority of the notification
	IBOutlet NSTextField	*notificationDescription;	// The long description
	IBOutlet NSImageView	*notificationImage;			// The associated image
	IBOutlet NSTextField	*notificationTitle;			// The title of this notification
	IBOutlet NSTextField	*notificationIdentifier;	// The identifier of this notification
	IBOutlet NSTextField	*notificationClickContext;	// The click context of this notification
	IBOutlet NSButton		*addEditButton;				// The OK button for the panel
	NSString *addButtonTitle, *editButtonTitle, *mainEditButtonTitle;
	
	IBOutlet NSButton		*growlLoggingButton;		// The checkbox to toggle logging, removed from main pane
	
	IBOutlet NSMatrix		*groupingType;				// The choices for batch grouping type [selection | all]
	IBOutlet NSTextField	*batchCountField;			// The number of notifications to post
    
	IBOutlet NSWindow		*mainWindow;
	IBOutlet NSTableView	*notificationsTable;		// The table of notifications
	IBOutlet NSButton		*addNotification;			// The button button that opens the add note pane
	IBOutlet NSButton		*removeNotification;		// The remove button (TBR)
	IBOutlet NSButton		*mainEditButton;			// The button on the UI to invoke a dbl-click
	IBOutlet NSButton		*sendButton;				// The button to send a notification
    
    IBOutlet NSTextField    *concurrentOperationsField;
    
    NSOperationQueue        *sendQueue;
    
	//data
	NSMutableArray			*notifications;				// The Array of notifications
}

- (id) init {
    if ((self = [super init])) {
        notifications = [[NSMutableArray alloc] init];
        sendQueue = [[NSOperationQueue alloc] init];
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
    [sendQueue release];
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
	[growlLoggingButton setState:[[prefsDict valueForKey:@"GrowlLoggingEnabled"] integerValue]];
}

- (IBAction)toggleGrowlLogging:(id)sender
{
#pragma mark This is a cheap hack to work with the preference
	NSMutableDictionary *prefsDict = [NSMutableDictionary dictionaryWithContentsOfFile:GROWL_PREFS_PATH];
	[prefsDict setObject:[NSNumber numberWithInteger:[sender state]] forKey:@"GrowlLoggingEnabled"];
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
	   didEndSelector:@selector(notificationEditorDidEnd:returnCode:contextInfo:)
		  contextInfo:nil];
}

- (IBAction)showEditSheet:(id)sender {
#pragma unused(sender)
	NSInteger index = [notificationsTable selectedRow];
	if (index < 0)
		NSBeep();
	else {
		NSDictionary *dict = [notifications objectAtIndex:index];
		[notificationDefault     setState:      [dict stateForKey:GROWL_NOTIFICATION_DEFAULT]];
		[notificationSticky      setState:      [dict stateForKey:GROWL_NOTIFICATION_STICKY]];
		NSInteger priority = [[dict objectForKey:GROWL_NOTIFICATION_PRIORITY] integerValue];
		[notificationPriority    selectItemAtIndex:[notificationPriority indexOfItemWithTag:priority]];
		[notificationImage       setImage:      [[[NSImage alloc] initWithData:[dict objectForKey:GROWL_NOTIFICATION_ICON_DATA]]autorelease]];
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
		   didEndSelector:@selector(notificationEditorDidEnd:returnCode:contextInfo:)
			  contextInfo:[[NSNumber alloc] initWithInteger:index]];
	}
}

- (IBAction)removeNotification:(id)sender {
#pragma unused(sender)
	NSInteger selectedRow = [notificationsTable selectedRow];
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
	NSInteger selectedRow = [notificationsTable selectedRow];
    
    sendQueue.maxConcurrentOperationCount = [batchCountField integerValue];
    
	if (selectedRow != -1){
		NSInteger batchCount = ([batchCountField integerValue] > 0 ? [batchCountField integerValue] : 1); // always 1
		
		if([groupingType selectedRow] == 0)
		{
			// loop through and send the appropriate number of notifications
			while(batchCount > 0)
			{
				//send a notification for the selected table cell
				__block NSDictionary *note = [[notifications objectAtIndex:selectedRow] retain];
				
                [sendQueue addOperationWithBlock:^{
                    [GrowlApplicationBridge notifyWithTitle:[note objectForKey:GROWL_NOTIFICATION_TITLE]
                                                description:[note objectForKey:GROWL_NOTIFICATION_DESCRIPTION]
                                           notificationName:[note objectForKey:GROWL_NOTIFICATION_NAME]
                                                   iconData:[note objectForKey:GROWL_NOTIFICATION_ICON_DATA]
                                                   priority:[[note objectForKey:GROWL_NOTIFICATION_PRIORITY] intValue]
                                                   isSticky:[[note objectForKey:GROWL_NOTIFICATION_STICKY] boolValue]
                                               clickContext:(([note objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT] && [[note objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT] length])
                                                             ? [note objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT]
                                                             : nil)
                                                 identifier:([[note objectForKey:GROWL_NOTIFICATION_IDENTIFIER] length] ?
                                                             [note objectForKey:GROWL_NOTIFICATION_IDENTIFIER] :
                                                             nil)];	
                    [note release];
				}];
                
				batchCount--;
			}
		}
		else if([groupingType selectedRow] == 1)
		{
			// loop through and send the appropriate number of notifications
			while(batchCount > 0)
			{
				for(NSUInteger currentRow = 0; currentRow < [notifications count]; currentRow++)
				{
					//send a notification for the row
					__block NSDictionary *note = [[notifications objectAtIndex:currentRow] retain];
					
                    [sendQueue addOperationWithBlock:^{
                        [GrowlApplicationBridge notifyWithTitle:[note objectForKey:GROWL_NOTIFICATION_TITLE]
                                                    description:[note objectForKey:GROWL_NOTIFICATION_DESCRIPTION]
                                               notificationName:[note objectForKey:GROWL_NOTIFICATION_NAME]
                                                       iconData:[note objectForKey:GROWL_NOTIFICATION_ICON_DATA]
                                                       priority:[[note objectForKey:GROWL_NOTIFICATION_PRIORITY] intValue]
                                                       isSticky:[[note objectForKey:GROWL_NOTIFICATION_STICKY] boolValue]
                                                   clickContext:nil
                                                     identifier:([[note objectForKey:GROWL_NOTIFICATION_IDENTIFIER] length] ?
                                                                 [note objectForKey:GROWL_NOTIFICATION_IDENTIFIER] :
                                                                 nil)];
                        [note release];
                    }];
                    

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

- (void) notificationEditorDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	if (returnCode == NSOKButton) {
		NSNumber *defaultValue = [NSNumber numberWithBool:[notificationDefault  state] == NSOnState];
		NSNumber *stickyValue  = [NSNumber numberWithBool:[notificationSticky   state] == NSOnState];
		NSNumber *priority     = [NSNumber numberWithInteger:[[notificationPriority selectedItem] tag]];
		NSData   *imageData    = [[notificationImage image] TIFFRepresentation];
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
			imageData,     GROWL_NOTIFICATION_ICON_DATA, /* May be nil, ending the dict */
			nil];

		NSNumber *indexNum = contextInfo;
		if (indexNum) {
			[notifications replaceObjectAtIndex:[indexNum unsignedIntegerValue]
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

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
#pragma unused(tableView)
    return [notifications count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)col row:(NSInteger)row {
#pragma unused(tableView, col, row)
    return [[notifications objectAtIndex:row] objectForKey:GROWL_NOTIFICATION_NAME];
}

#pragma mark Table Delegate Methods

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)col row:(NSInteger)row {
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
	NSUInteger numNotifications = [notifications count];

	//Build an array of all notifications we want to use
	for (NSUInteger i = 0U; i < numNotifications; ++i) {
		NSDictionary *def = [notifications objectAtIndex:i];
		[allNotesArray addObject:[def objectForKey:GROWL_NOTIFICATION_NAME]];

		isDefaultNum = [def objectForKey:GROWL_NOTIFICATION_DEFAULT];
		if (isDefaultNum && [isDefaultNum boolValue])
			[defNotesArray addObject:[NSNumber numberWithUnsignedInteger:i]];
	}

	[allNotesArray addObject:CLICK_RECEIVED_NOTIFICATION_NAME];
	[allNotesArray addObject:CLICK_TIMED_OUT_NOTIFICATION_NAME];

	//Set these notifications both for ALL (all possibilites) and DEFAULT (the ones enabled by default)
	NSDictionary *regDict = [NSDictionary dictionaryWithObjectsAndKeys:
		allNotesArray, GROWL_NOTIFICATIONS_ALL,
		defNotesArray, GROWL_NOTIFICATIONS_DEFAULT,
		nil];

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

