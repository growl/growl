#import "BeepController.h"

@implementation BeepController

- (id) init {
	if ( self = [super init] ) {
		_notifications = [[_notifications init] alloc];
	}
	return self;
}

- (IBAction)addNotification:(id)sender {

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

}

#pragma mark Table Data Source

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [_notifications count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	return [[_notifications objectAtIndex:rowIndex] objectForKey:@"NotificationName"];
}

#pragma mark Table Delegate Methods

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	return NO;
}

@end
