/*
 Copyright (c) The Growl Project, 2004-2011
 All rights reserved.


 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:


 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 3. Neither the name of Growl nor the names of its contributors
 may be used to endorse or promote products derived from this software
 without specific prior written permission.


 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/
#import <Foundation/Foundation.h>
#import "GrowlDefines.h"
#import "GrowlDefinesInternal.h"
#import "GrowlPathway.h"
#import "GrowlVersion.h"
#import "GrowlImageAdditions.h"

#include <unistd.h>
#include <getopt.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>

#define NOTIFICATION_NAME @"Command-Line Growl Notification"

#define STRINGIFY(x) STRINGIFY2(x)
#define STRINGIFY2(x) #x

static const char usage[] =
"Usage: growlnotify [-hsvuwc] [-i ext] [-I filepath] [--image filepath]\n"
"                   [-a appname] [-p priority] [-H host] [-P password]\n"
"                   [-n name] [-A method] [--html] [-m message] [-t] [title]\n"
"Options:\n"
"    -h,--help       Display this help\n"
"    -v,--version    Display version number\n"
"    -n,--name       Set the name of the application that sends the notification\n"
"                    [Default: growlnotify]\n"
"    -s,--sticky     Make the notification sticky\n"
"    -a,--appIcon    Specify an application name to take the icon from\n"
"    -i,--icon       Specify a file type or extension to look up for the\n"
"                    notification icon\n"
"    -I,--iconpath   Specify a file whose icon will be the notification icon\n"
"       --image      Specify an image file to be used for the notification icon\n"
"    -m,--message    Sets the message to be used instead of using stdin\n"
"                    Passing - as the argument means read from stdin\n"
"    -p,--priority   Specify an int or named key (default is 0)\n"
"    -d,--identifier Specify a notification identifier (used for coalescing)\n"
"    -H,--host       Specify a hostname or IP address to which to send a remote notification.\n"
"    -P,--password   Password used for remote notifications.\n"
"    -w,--wait       Wait until the notification has been dismissed.\n"
"\n"
"Display a notification using the title given on the command-line and the\n"
"message given in the standard input.\n"
"\n"
"Priority can be one of the following named keys: Very Low, Moderate, Normal,\n"
"High, Emergency. It can also be an int between -2 and 2.\n"
"\n"
"To be compatible with gNotify the following switch is accepted:\n"
"    -t,--title      Does nothing. Any text following will be treated as the\n"
"                    title because that's the default argument behaviour\n";

static const char *version = "growlnotify " GROWL_VERSION_STRING "\n"
"Copyright (c) The Growl Project, 2004-2011";

static NSData* copyIconDataForTypeInfo(CFStringRef typeInfo)
{
	IconRef icon;
	NSData *data = nil;
	OSStatus err = GetIconRefFromTypeInfo(/*inCreator*/   0,
										  /*inType*/      0,
										  /*inExtension*/ typeInfo,
										  /*inMIMEType*/  NULL,
										  /*inUsageFlags*/kIconServicesNormalUsageFlag,
										  /*outIconRef*/  &icon);
	if (err == noErr) {
		IconFamilyHandle fam = NULL;
		err = IconRefToIconFamily(icon, kSelectorAllAvailableData, &fam);
		if (err == noErr) {
			HLock((Handle)fam);
			data = [NSData dataWithBytes:(const UInt8 *)*(Handle)fam length:GetHandleSize((Handle)fam)];
			HUnlock((Handle)fam);
			DisposeHandle((Handle)fam);
		}
		ReleaseIconRef(icon);
	}

	return data;
}

int main(int argc, const char **argv) {
	// options
	extern char *optarg;
	extern int   optind;
	int          ch;
	BOOL         isSticky = NO;
	BOOL         wait = NO;
	char        *appName = NULL;
	char        *appIcon = NULL;
	char        *iconExt = NULL;
	char        *iconPath = NULL;
	char        *imagePath = NULL;
	char        *message = NULL;
	char        *host = NULL;
	int          priority = 0;
	int          flag;
	char        *port = NULL;
	int          code = EXIT_SUCCESS;
	char        *password = NULL;
	char        *identifier = NULL;

	struct option longopts[] = {
		{ "help",		no_argument,		NULL,	'h' },
		{ "name",		required_argument,	NULL,	'n' },
		{ "icon",		required_argument,	NULL,	'i' },
		{ "iconpath",	required_argument,	NULL,	'I' },
		{ "appIcon",	required_argument,	NULL,	'a' },
		{ "image",		required_argument,	&flag,	 1  },
		{ "title",		no_argument,		NULL,	't' },
		{ "message",	required_argument,	NULL,	'm' },
		{ "priority",	required_argument,	NULL,	'p' },
		{ "host",		required_argument,	NULL,	'H' },
		{ "password",	required_argument,	NULL,	'P' },
		{ "port",		required_argument,	&flag,	 2  },
		{ "version",	no_argument,		NULL,	'v' },
		{ "identifier", required_argument,  NULL,   'd' },
		{ "wait",		no_argument,		NULL,   'w' },
		{ "sticky",     no_argument,        NULL,   's' },
		{ "html",       no_argument,        &flag,   4  },
		{ NULL,			0,					NULL,	 0  }
	};

	while ((ch = getopt_long(argc, (char * const *)argv, "hvn:sa:A:i:I:p:tm:H:uP:d:wc", longopts, NULL)) != -1) {
		switch (ch) {
		case '?':
			puts(usage);
			exit(EXIT_FAILURE);
			break;
		case 'h':
			puts(usage);
			exit(EXIT_SUCCESS);
			break;
		case 'v':
			puts(version);
			exit(EXIT_SUCCESS);
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
		case 'P':
			password = optarg;
			break;
		case 'd':
			identifier = optarg;
			break;
		case 'w':
			wait = YES;
			break;
		case 0:
			switch (flag) {
				case 1:
					imagePath = optarg;
					break;
				case 2:
					port = strdup(optarg);
					break;
				case 4:
					break;
			}
			break;
		}
	}
	argc -= optind;
	argv += optind;

	// Deal with title

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
   
	NSMutableString *title = [NSMutableString string];
	while (argc--) {
		if (strlen(*argv)) {
			if ([title length])
				[title appendString:@" "];
         [title appendString:[NSString stringWithUTF8String:(argv++)[0]]];
		}
	}

	// Deal with image
	// --image takes precedence over -I takes precedence over -i takes precedence over -a
	NSData *icon = nil;
	if (imagePath) {
		// read the image file into a CFDataRef
		icon = [NSData dataWithContentsOfFile:[NSString stringWithUTF8String:imagePath]];
	} else if (iconPath) {
		// get icon data for path
		NSString *path = [[NSString stringWithUTF8String:iconPath] stringByStandardizingPath];
		if (![path isAbsolutePath])
			path = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:path];
		icon = [[[NSWorkspace sharedWorkspace] iconForFile:path] PNGRepresentation];
	} else if (iconExt) {
		// get icon data for file extension or type
		CFStringRef fileType = CFStringCreateWithCString(kCFAllocatorDefault, iconExt, kCFStringEncodingUTF8);
		icon = copyIconDataForTypeInfo  (fileType);
		CFRelease(fileType);
	} else if (appIcon) {
		// get icon data for application name
		NSString *appPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:[NSString stringWithUTF8String:appIcon]];
		if (appPath) {
         icon = [[[NSWorkspace sharedWorkspace] iconForFile:appPath] PNGRepresentation];
		}
	}
	if (!icon) {
		NSString *appPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.apple.Terminal"];
		if (appPath) {
         icon = [[[NSWorkspace sharedWorkspace] iconForFile:appPath] PNGRepresentation];
		}
	}

	// Check message
	NSString *desc;
	if (message && !(message[0] == '-' && message[1] == 0)) {
		// -m was used
		desc = [NSString stringWithUTF8String:message];
	} else {
		// Deal with stdin
		if (isatty(STDIN_FILENO) && isatty(STDOUT_FILENO))
			fputs("Enter a notification description, followed by newline, followed by Ctrl-D (End of File). To cancel, press Ctrl-C.\n", stdout);

		char buffer[4096];
		NSMutableString *temp = [NSMutableString string];
		while (!feof(stdin)) {
			size_t len = fread(buffer, 1, sizeof(buffer)-1, stdin);
			if (!len)
				break;
			buffer[len] = '\0';
			[temp appendString:[NSString stringWithUTF8String:buffer]];
		}
		desc = [temp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	}

	// Application name
	NSString *applicationName;
	if (appName)
		applicationName = [NSString stringWithUTF8String:appName];
	else
		applicationName = @"growlnotify";

	NSString *identifierString;
	if (identifier)
		identifierString = [NSString stringWithUTF8String:identifier];
	else
		identifierString = nil;

	// Register with Growl
	NSString *name = NOTIFICATION_NAME;
	NSArray *defaultAndAllNotifications = [NSArray arrayWithObject:name];
	NSArray *registerKeys = [[NSArray alloc] initWithObjects:GROWL_APP_NAME, 
                                                            GROWL_NOTIFICATIONS_ALL,
                                                            GROWL_NOTIFICATIONS_DEFAULT,
                                                            GROWL_APP_ICON_DATA, nil];
	NSArray *registerValues = [[NSArray alloc] initWithObjects:applicationName,
                                                              defaultAndAllNotifications,
                                                              defaultAndAllNotifications,
                                                              icon, nil];
   
   NSDictionary *registerInfo = [[NSDictionary alloc] initWithObjects:registerValues forKeys:registerKeys];

	// Notify
	CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
	CFStringRef clickContext = CFUUIDCreateString(kCFAllocatorDefault, uuid);
   NSNumber *priorityNumber = [NSNumber numberWithInt:priority];
   NSNumber *stickyValue = [NSNumber numberWithBool:isSticky];
   NSMutableDictionary *notificationInfo = [NSMutableDictionary dictionary];
   [notificationInfo setValue:name forKey:GROWL_NOTIFICATION_NAME];
   [notificationInfo setValue:applicationName forKey:GROWL_APP_NAME];
   [notificationInfo setValue:title forKey:GROWL_NOTIFICATION_TITLE];
   [notificationInfo setValue:desc forKey:GROWL_NOTIFICATION_DESCRIPTION];
   [notificationInfo setValue:priorityNumber forKey:GROWL_NOTIFICATION_PRIORITY];
   [notificationInfo setValue:stickyValue forKey:GROWL_NOTIFICATION_STICKY];
   [notificationInfo setValue:icon forKey:GROWL_NOTIFICATION_ICON_DATA];
   [notificationInfo setValue:(NSString*)clickContext forKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
	if (identifierString) {
      [notificationInfo setValue:identifierString forKey:GROWL_NOTIFICATION_IDENTIFIER];
	}
	CFRelease(clickContext);
   
   /* TODO: GNTP Registration, and notification */
   
   NSLog(@"Registration info: %@", registerInfo);
   NSLog(@"Notification info: %@", notificationInfo);

	[pool release];

	return code;
}
