#import <foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "GrowlDefines.h"

static NSString *notificationName = @"Command-Line Growl Notification";

int main (int argc, const char **argv) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	if(--argc) {
		NSMutableString *title = [NSMutableString stringWithUTF8String:*++argv];
		while(--argc)
			[title appendFormat:@" %s", *++argv];

		NSData *descData = [[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile];
		NSString *desc = [[[[NSString alloc] initWithData:descData encoding:NSUTF8StringEncoding] autorelease] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

		NSDistributedNotificationCenter *distCenter = [NSDistributedNotificationCenter defaultCenter];

		NSDictionary *userInfo;

		//register with Growl.
		NSArray *defaultAndAllNotifications = [NSArray arrayWithObject:notificationName];
		userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
			@"growlnotify", GROWL_APP_NAME,
			defaultAndAllNotifications, GROWL_NOTIFICATIONS_ALL,
			defaultAndAllNotifications, GROWL_NOTIFICATIONS_DEFAULT,
			nil];
		[distCenter postNotificationName:GROWL_APP_REGISTRATION
								  object:nil
								userInfo:userInfo];

		NSData* icon = [[[NSWorkspace sharedWorkspace] iconForFile:[[NSWorkspace sharedWorkspace] fullPathForApplication:@"Terminal"]] TIFFRepresentation];
		userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
			notificationName, GROWL_NOTIFICATION_NAME,
			@"growlnotify", GROWL_APP_NAME,
			title, GROWL_NOTIFICATION_TITLE,
			icon, GROWL_NOTIFICATION_ICON,
			desc, GROWL_NOTIFICATION_DESCRIPTION,
			nil];
		NSLog(@"Sending notification with title @\"%@\"", title);
		[distCenter postNotificationName:GROWL_NOTIFICATION
								  object:nil
								userInfo:userInfo];
	}
	
    [pool release];
    return 0;
}
