#import <Foundation/Foundation.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSWorkspace.h>
#import "GrowlDefines.h"
#import "GrowlNotificationServer.h"

#import <unistd.h>
#import <getopt.h>

static NSString *notificationName = @"Command-Line Growl Notification";

static const char usage[] = 
"Usage: growlnotify [-hs] [-i ext] [-I filepath] [--image filepath]\n"
"                   [-p priority] [title]\n"
"Options:\n"
"    -h,--help     Display this help\n"
"    -n,--name     Set the name of the application that sends the notification\n"
"                  [Default: growlnotify]\n"
"    -s            Make the notification sticky\n"
"    -a,--appIcon  Specify an application name  to take the icon from\n"
"    -i,--icon     Specify a filetype or extension to be used for the icon\n"
"    -I,--iconpath Specify a filepath to be used for the icon\n"
"    --image       Specify an image file to be used for the icon\n"
"    -p,--priority Specify an int or named key (default is 0)\n"
"\n"
"Display a notification using the title given on the command-line and the\n"
"message given in the standard input.\n"
"\n"
"Priority can be one of the following named keys: Very Low, Moderate, Normal, High,\n"
"Emergency. It can also be an int between -2 and 2.\n"
"\n"
"To be compatible with gNotify the following switches are accepted:\n"
"    -t,--title    Does nothing. Any text following will be treated as the\n"
"                  title because that's the default argument behaviour\n"
"    -m,--message  Sets the message to the following instead of using stdin\n";

int main(int argc, const char **argv) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// options
	extern char *optarg;
	extern int optind;
	int ch;
	static BOOL isSticky = NO;
	static char *appName = NULL;
	char *appIcon = NULL;
	char *iconExt = NULL;
	char *iconPath = NULL;
	char *imagePath = NULL;
	static char *message = NULL;
	static char *host = NULL;
	int priority = 0;
	int imageset;
	struct option longopts[] = {
		{ "help",		no_argument,		0,			'h' },
		{ "name",		required_argument,	0,			'n' },
		{ "icon",		required_argument,	0,			'i' },
		{ "iconpath",	required_argument,	0,			'I' },
		{ "appIcon",	required_argument,	0,			'a' },
		{ "image",		required_argument,	&imageset,	 1  },
		{ "title",		no_argument,		0,			't' },
		{ "message",	required_argument,	0,			'm' },
		{ "priority",	required_argument,	0,			'p' },
		{ "host",		required_argument,	0,			'H' },
		{ 0,			0,					0,			 0  }
	};
	while ((ch = getopt_long(argc, (char * const *)argv, "hnsa:i:I:p:tm:H:", longopts, NULL)) != -1) {
		switch (ch) {
		case '?':
		case 'h':
			printf(usage);
			exit(1);
			break;
		case 'n':
			appName = optarg;
			break;
		case 's':
			isSticky = YES;
			break;
		case 'i':
			iconExt = optarg;
			break;
		case 'I':
			iconPath = optarg;
			break;
		case 'a':
			appIcon = optarg;
			break;
		case 'p':
			if (sscanf(optarg, "%d", &priority) == 0) {
				// It's not an integer - is it one of the priority keys?
				char *keys[] = {"Very Low", "Moderate", "Normal", "High", "Emergency"};
				for (int i = 0; i < 5; i++) {
					if (strcmp(optarg, keys[i]) == 0) {
						priority = i - 2;
						break;
					}
				}
			}
			break;
		case 't':
			// do nothing
			break;
		case 'm':
			message = optarg;
			break;
		case 'H':
			host = optarg;
			break;
		case 0:
			if (imageset) {
				imagePath = optarg;
			}
			break;
		}
	}
	argc -= optind;
	argv += optind;
	
	// Deal with title
	NSMutableArray *argArray = [NSMutableArray array];
	while (argc--) {
		NSString *temp = [NSString stringWithUTF8String:(argv++)[0]];
		[argArray addObject:temp];
	}
	[argArray removeObject:@""];
	NSString *title = [argArray componentsJoinedByString:@" "];
	
	// Deal with image
	// --image takes precedence over -I takes precedence over -i takes precedence over --a
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	static NSImage *image = nil;
	if (imagePath) {
		NSString *path = [[NSString stringWithUTF8String:imagePath] stringByStandardizingPath];
		if (![path hasPrefix:@"/"]) {
			char *cwd = getcwd(NULL, 0);
			path = [NSString stringWithFormat:@"%s/%@", cwd, path];
			free(cwd);
		}
		image = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
	} else if (iconPath) {
		NSString *path = [[NSString stringWithUTF8String:iconPath] stringByStandardizingPath];
		if (![path hasPrefix:@"/"]) {
			char *cwd = getcwd(NULL, 0);
			path = [NSString stringWithFormat:@"%s/%@", cwd, path];
			free(cwd);
		}
		image = [ws iconForFile:path];
	} else if (iconExt) {
		image = [ws iconForFileType:[NSString stringWithUTF8String:iconExt]];
	} else if (appIcon) {
		NSString *app = [NSString stringWithUTF8String:appIcon];
		image = [ws iconForFile:[ws fullPathForApplication:app]];
	}
	if (image == nil) {
		image = [ws iconForFile:[ws fullPathForApplication:@"Terminal"]];
	}
	NSData *icon;
	NS_DURING // I don't know why this is necessary but it is
		icon = [image TIFFRepresentation];
	NS_HANDLER
		printf("Error: cannot use pdf files for image\n");
		exit(2);
	NS_ENDHANDLER
	
	// Check message
	NSString *desc;
	if (message && !(message[0] == '-' && message[1] == 0)) {
		// -m was used
		desc = [NSString stringWithUTF8String:message];
	} else {
		// Deal with stdin
		NSData *descData = [[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile];
		desc = [[[NSString alloc] initWithData:descData encoding:NSUTF8StringEncoding] autorelease];
		desc = [desc stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	}
	
	// Application name
	NSString *applicationName;
	if (appName) {
		applicationName = [NSString stringWithUTF8String:appName];
	} else {
		applicationName = @"growlnotify";
	}
	
	// Register with Growl
	NSDictionary *registerInfo;
	NSArray *defaultAndAllNotifications = [NSArray arrayWithObject:notificationName];
	registerInfo = [NSDictionary dictionaryWithObjectsAndKeys:
		applicationName, GROWL_APP_NAME,
		defaultAndAllNotifications, GROWL_NOTIFICATIONS_ALL,
		defaultAndAllNotifications, GROWL_NOTIFICATIONS_DEFAULT,
		nil];

	// Notify
	NSDictionary *notificationInfo;
	notificationInfo = [NSDictionary dictionaryWithObjectsAndKeys:
		notificationName, GROWL_NOTIFICATION_NAME,
		applicationName, GROWL_APP_NAME,
		title, GROWL_NOTIFICATION_TITLE,
		icon, GROWL_NOTIFICATION_ICON,
		desc, GROWL_NOTIFICATION_DESCRIPTION,
		[NSNumber numberWithInt:priority], GROWL_NOTIFICATION_PRIORITY,
		[NSNumber numberWithBool:isSticky], GROWL_NOTIFICATION_STICKY,
		nil];
	
	if( host ) {
		NSSocketPort *port = [[NSSocketPort alloc] initRemoteWithTCPPort:GROWL_TCP_PORT host:[NSString stringWithCString:host]];
		NSConnection *connection = [[NSConnection alloc] initWithReceivePort:nil sendPort:port];
		NSDistantObject *theProxy = [connection rootProxy];
		[theProxy setProtocolForProxy:@protocol(GrowlNotificationProtocol)];
		id<GrowlNotificationProtocol> growlProxy = (id)theProxy;

		[growlProxy registerApplication:registerInfo];
		[growlProxy postNotification:notificationInfo];

		[port release];
		[connection release];
	} else {
		NSDistributedNotificationCenter *distCenter = [NSDistributedNotificationCenter defaultCenter];
		[distCenter postNotificationName:GROWL_APP_REGISTRATION object:nil userInfo:registerInfo];
		[distCenter postNotificationName:GROWL_NOTIFICATION object:nil userInfo:notificationInfo];
	}
	
	[pool release];

	return EXIT_SUCCESS;
}
