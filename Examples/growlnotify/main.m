#import <Cocoa/Cocoa.h>
#import "GrowlDefines.h"

static NSString *notificationName = @"Command-Line Growl Notification";

static const char usage[] = "usage: %s title\n"
"usage: %s -- title\n"
"\tthe description for the notification is read from stdin, and the\n"
"\tnotification is posted once the entire description is collected.\n"
"\n"
"usage: %s --help\n"
"\tprint this help.\n";

int main(int argc, const char **argv) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	const char *argv0 = argv[0];

	if(argc-- < 1) {
		fprintf(stderr, "what happened?! argc (%i) < 1! something is seriously wrong on your system! (bailing out, obviously.\n", argc);
		return 2;
	} else if(!argc) {
		//there are no arguments.
		//since notifications can't have an empty title, print usage.
		printf(usage, argv0, argv0, argv0);
	} else {
		//there are arguments.
		//'title' here refers to the notification title.
		NSMutableString *title = [NSMutableString stringWithUTF8String:*++argv];

		if([title isEqualToString:@"--help"]) {
			//user has requested usage. print it.
			printf(usage, argv0, argv0, argv0);
		} else {
			if([title isEqualToString:@"--"]) {
				//this signifies the end of options. ignore it and move on.
				[title deleteCharactersInRange:NSMakeRange(0U, [title length])];
			}

			//as long as the title is empty, don't append a space.
			while((--argc) && ([title length] <= 0U))
				[title appendFormat:@"%s", *++argv];
			if(argc) {
				//now that the title is non-empty, start adding a space before each argument.
				while(--argc)
					[title appendFormat:@" %s", *++argv];
			}

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

			NSData *icon = [[[NSWorkspace sharedWorkspace] iconForFile:[[NSWorkspace sharedWorkspace] fullPathForApplication:@"Terminal"]] TIFFRepresentation];
			userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				notificationName, GROWL_NOTIFICATION_NAME,
				@"growlnotify", GROWL_APP_NAME,
				title, GROWL_NOTIFICATION_TITLE,
				icon, GROWL_NOTIFICATION_ICON,
				desc, GROWL_NOTIFICATION_DESCRIPTION,
				nil];

			[distCenter postNotificationName:GROWL_NOTIFICATION
									  object:nil
									userInfo:userInfo];
		}
	}
	
    [pool release];
    return 0;
}
