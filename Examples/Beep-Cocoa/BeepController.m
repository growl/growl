#import "BeepController.h"
#import <GrowlAppBridge/GrowlApplicationBridge.h>
#import "GrowlDefines.h"

#define GROWL_NOTIFICATION_DEFAULT @"NotificationDefault"

@interface BeepController (PRIVATE)
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
@end

@implementation BeepController

- (id) init {
    if ( self = [super init] ) {
        _notifications = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) dealloc {
    [_notifications release];
    _notifications = nil;
}

- (void)awakeFromNib {
	[self tableViewSelectionDidChange:nil];
}

#pragma mark -

- (IBAction)showAddSheet:(id)sender { 
    [NSApp beginSheet:_newNotificationPanel 
       modalForWindow:_beepWindow 
        modalDelegate:nil 
       didEndSelector:nil 
          contextInfo:nil];
    
    [NSApp runModalForWindow:_newNotificationPanel];
    [NSApp endSheet:_newNotificationPanel];
    [_newNotificationPanel orderOut:self];
}

- (IBAction)addNotification:(id)sender {
	//get Sheet fields and add to the known notifications
	NSLog(@"checkbox %u; on %u; off %u; mixed %u", [_newNotificationDefault state], NSOnState, NSOffState, NSMixedState);
	NSNumber *defaultValue = [NSNumber numberWithBool:[_newNotificationDefault state] == NSOnState];
	NSNumber *stickyValue = [NSNumber numberWithBool:[_newNotificationSticky state] == NSOnState];
	NSData *image = nil;
	if ( [_newNotificationImage image] ) {
		image = [[_newNotificationImage image] TIFFRepresentation];
	}
	
	NSDictionary *aNuDict = [NSDictionary dictionaryWithObjectsAndKeys:
		[_newNotificationTitle stringValue], GROWL_NOTIFICATION_TITLE,
		[_newNotificationDescription stringValue], GROWL_NOTIFICATION_DESCRIPTION,
		@"Beep-Cocoa", GROWL_APP_NAME,
		defaultValue, GROWL_NOTIFICATION_DEFAULT,
		stickyValue, GROWL_NOTIFICATION_STICKY,
		image, GROWL_NOTIFICATION_ICON,
		nil];

	[_notifications addObject:aNuDict];
	//NSLog( @"%@ added to %@", aNuDict, _notifications);
	[_notificationsTable reloadData];
	
	[self endPanel:self];
}

- (IBAction)removeNotification:(id)sender
{
	if([_notificationsTable selectedRow] < 0) {
		NSBeep();
		return;
	} else {
		[_notifications removeObjectAtIndex:[_notificationsTable selectedRow]];
		[_notificationsTable reloadData];
	}
}

//Called when the "Register" checkbox is selecteed
- (IBAction)registerBeep:(id)sender {
    if ( [_registered state] == NSOnState ) {
        NSLog( @"Button on" );
		
		//Launch growl if possible
		if ([GrowlAppBridge launchGrowlIfInstalledNotifyingTarget:self
														 selector:@selector(growlDidLaunch:) 
														  context:nil]){
			//Disable the add/remove buttons
			[_addNotification setEnabled:NO];
			[_removeNotification setEnabled:NO];
		}else{
			NSLog(@"Bloody 'ell. Growl's not installed or couldn't be launched");
		}
    } else {
        NSLog( @"Button off" );	
		
		//Reenable the add/remove buttons
		[_addNotification setEnabled:YES];
		[_removeNotification setEnabled:YES];
    }
}


- (void)growlDidLaunch:(void *)context {
	
	NSLog(@"Growl engaged, Captain!");
	
	NSMutableArray *defNotesArray = [NSMutableArray array];
	NSMutableArray *allNotesArray = [NSMutableArray array];
	NSEnumerator *defNotes = [_notifications objectEnumerator];
	NSDictionary *def;
	NSNumber *isDefaultNum;
	unsigned i;
	unsigned max = [_notifications count];
	
	while ( def = [defNotes nextObject] ) {
		isDefaultNum = [def objectForKey:GROWL_NOTIFICATION_DEFAULT];
		if ( isDefaultNum && [isDefaultNum boolValue] ) {
			[defNotesArray addObject:[def objectForKey:GROWL_NOTIFICATION_TITLE]];
		}
	}
	
	for ( i = 0; i < max; ++i ) {
		[allNotesArray addObject:[[_notifications objectAtIndex:i] objectForKey:GROWL_NOTIFICATION_TITLE]];
	}
	
	NSDictionary *regDict = [NSDictionary dictionaryWithObjectsAndKeys:
		@"Beep-Cocoa", GROWL_APP_NAME, 
		allNotesArray, GROWL_NOTIFICATIONS_ALL, 
		defNotesArray, GROWL_NOTIFICATIONS_DEFAULT,
		nil];
	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_APP_REGISTRATION 
																   object:nil 
																 userInfo:regDict];
	
}

- (IBAction)sendNotification:(id)sender {
	int selectedRow = [_notificationsTable selectedRow];
	
	if (selectedRow != -1){
		//send a notification for the selected table cell
		id note = [_notifications objectAtIndex:[_notificationsTable selectedRow]];
		
		//NSLog( @"note - %@", note );
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:[note objectForKey:GROWL_NOTIFICATION_TITLE] 
																	   object:nil 
																	 userInfo:note
														   deliverImmediately:YES];
		//NSLog( @"sent it" );
	}
}

- (IBAction) endPanel:(id)sender {
    [NSApp stopModal];
}

#pragma mark Table Data Source

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [_notifications count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    return [[_notifications objectAtIndex:rowIndex] objectForKey:GROWL_NOTIFICATION_TITLE];
}

#pragma mark Table Delegate Methods

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(int)row {
    return NO;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	BOOL rowIsSelected = ([_notificationsTable selectedRow] != -1);
	
	[_sendButton setEnabled:rowIsSelected];
}

#pragma mark NSApplication Delegate Methods

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)app {
	return YES;
}

@end

