#import "BeepController.h"

#define GROWL_NOTIFICATION_DEFAULT @"NotificationDefault"

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
	NSNumber *defaultValue = [NSNumber numberWithBool:[_newNotificationDefault state] == NSOnState];
	NSDictionary *aNuDict = [NSDictionary dictionaryWithObjectsAndKeys:			[_newNotificationTitle stringValue], GROWL_NOTIFICATION_TITLE,
																				[_newNotificationDescription stringValue], GROWL_NOTIFICATION_DESCRIPTION,
																				[_newNotificationImage image], GROWL_NOTIFICATION_ICON,
																				defaultValue, GROWL_NOTIFICATION_DEFAULT,
																				nil];
	[_notifications addObject:aNuDict];
	NSLog( @"%@ added to %@", aNuDict, _notifications);
	[_notificationsTable reloadData];
	
	[self endPanel:self];
}

- (IBAction)registerBeep:(id)sender {
	if ( [_registered state] == NSOnState ) {
		NSLog( @"Button on" );
		NSDictionary *regDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"Beep", GROWL_APP_NAME, nil];
		
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_APP_REGISTRATION 
																	   object:nil 
																	 userInfo:regDict];
	} else {
		NSLog( @"Button off" );	
	}
}

- (IBAction)sendNotification:(id)sender {
	//send a notification for the selected table cell
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

@end
