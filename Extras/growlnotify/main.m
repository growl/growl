/*
 Copyright (c) The Growl Project, 2004-2005
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

#include <unistd.h>
#include <getopt.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>

#define NOTIFICATION_NAME CFSTR("Command-Line Growl Notification")

#define STRINGIFY(x) STRINGIFY2(x)
#define STRINGIFY2(x) #x

static const char usage[] =
"Usage: growlnotify [-hsvuwc] [-i ext] [-I filepath] [--image filepath]\n"
"                   [-a appname] [-p priority] [-H host] [-P password]\n"
"                   [--port port] [-n name] [-A method] [--progress value]\n"
"                   [--html] [-m message] [-t] [title]\n"
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
"    -H,--host       Specify a hostname to which to send a remote notification.\n"
"    -P,--password   Password used for remote notifications.\n"
"    -w,--wait       Wait until the notification has been dismissed.\n"
"       --progress   Set a progress value for this notification.\n"
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
"Copyright (c) The Growl Project, 2004-2008";

static void notificationDismissed(CFNotificationCenterRef center,
								  void *observer,
								  CFStringRef name,
								  const void *object,
								  CFDictionaryRef userInfo) {
#pragma unused(center,observer,name,object,userInfo)
	CFRunLoopStop(CFRunLoopGetCurrent());
}

static CFDataRef copyIconDataForTypeInfo(CFStringRef typeInfo)
{
	IconRef icon;
	CFDataRef data = NULL;
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
			data = CFDataCreate(kCFAllocatorDefault, (const UInt8 *)*(Handle)fam, GetHandleSize((Handle)fam));
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
	double       progress;
	BOOL         haveProgress = NO;
	BOOL         crypt = NO;
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
		{ "auth",		required_argument,	NULL,   'A' },
		{ "crypt",      no_argument,        NULL,   'c' },
		{ "sticky",     no_argument,        NULL,   's' },
		{ "progress",   required_argument,  &flag,   3  },
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
		case 'A':
			if (!strcasecmp(optarg, "md5"))
				authMethod = GROWL_AUTH_MD5;
			else if (!strcasecmp(optarg, "sha256"))
				authMethod = GROWL_AUTH_SHA256;
			else if (!strcasecmp(optarg, "none"))
				authMethod = GROWL_AUTH_NONE;
			else
				fprintf(stderr, "Unknown digest algorithm: %s, using default (md5).\n", optarg);
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
		case 'c':
			crypt = YES;
			break;
		case 0:
			switch (flag) {
				case 1:
					imagePath = optarg;
					break;
				case 2:
					port = strdup(optarg);
					break;
				case 3:
					haveProgress = YES;
					progress = strtod(optarg, NULL);
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
	CFMutableStringRef title = CFStringCreateMutable(kCFAllocatorDefault, 0);
	while (argc--) {
		if (strlen(*argv)) {
			if (CFStringGetLength(title))
				CFStringAppend(title, CFSTR(" "));
			CFStringAppendCString(title, (argv++)[0], kCFStringEncodingUTF8);
		}
	}

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	// Deal with image
	// --image takes precedence over -I takes precedence over -i takes precedence over -a
	CFDataRef icon = NULL;
	if (imagePath) {
		// read the image file into a CFDataRef
		icon = (CFDataRef)readFile(imagePath);
	} else if (iconPath) {
		// get icon data for path
		NSString *path = [[NSString stringWithUTF8String:iconPath] stringByStandardizingPath];
		if (![path isAbsolutePath])
			path = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:path];
		icon = (CFDataRef)copyIconDataForPath(path);
	} else if (iconExt) {
		// get icon data for file extension or type
		CFStringRef fileType = CFStringCreateWithCString(kCFAllocatorDefault, iconExt, kCFStringEncodingUTF8);
		icon = copyIconDataForTypeInfo(fileType);
		CFRelease(fileType);
	} else if (appIcon) {
		// get icon data for application name
		CFStringRef app = CFStringCreateWithCString(kCFAllocatorDefault, appIcon, kCFStringEncodingUTF8);
		NSString *appPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:(NSString *)app];
		if (appPath) {
			NSURL *appURL = [NSURL fileURLWithPath:appPath];
			if (appURL) {
				icon = (CFDataRef)copyIconDataForURL(appURL);
			}
		}
		CFRelease(app);
	}
	if (!icon) {
		NSString *appPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.apple.Terminal"];
		if (appPath) {
			NSURL *appURL = [NSURL fileURLWithPath:appPath];
			if (appURL) {
				icon = (CFDataRef)copyIconDataForURL((NSURL *)appURL);
			}
		}
	}

	// Check message
	CFStringRef desc;
	if (message && !(message[0] == '-' && message[1] == 0)) {
		// -m was used
		desc = CFStringCreateWithCString(kCFAllocatorDefault, message, kCFStringEncodingUTF8);
	} else {
		// Deal with stdin
		if (isatty(STDIN_FILENO) && isatty(STDOUT_FILENO))
			fputs("Enter a notification description, followed by newline, followed by Ctrl-D (End of File). To cancel, press Ctrl-C.\n", stdout);

		char buffer[4096];
		CFMutableStringRef temp = CFStringCreateMutable(kCFAllocatorDefault, 0);
		while (!feof(stdin)) {
			size_t len = fread(buffer, 1, sizeof(buffer)-1, stdin);
			if (!len)
				break;
			buffer[len] = '\0';
			CFStringAppendCString(temp, buffer, kCFStringEncodingUTF8);
		}
		CFStringTrimWhitespace(temp);
		desc = temp;
	}

	// Application name
	CFStringRef applicationName;
	if (appName)
		applicationName = CFStringCreateWithCString(kCFAllocatorDefault, appName, kCFStringEncodingUTF8);
	else
		applicationName = CFSTR("growlnotify");

	CFStringRef identifierString;
	if (identifier)
		identifierString = CFStringCreateWithCString(kCFAllocatorDefault, identifier, kCFStringEncodingUTF8);
	else
		identifierString = NULL;

	// Register with Growl
	CFStringRef name = NOTIFICATION_NAME;
	CFArrayRef defaultAndAllNotifications = CFArrayCreate(kCFAllocatorDefault, (const void **)&name, 1, &kCFTypeArrayCallBacks);
	CFTypeRef registerKeys[4] = {
		GROWL_APP_NAME,
		GROWL_NOTIFICATIONS_ALL,
		GROWL_NOTIFICATIONS_DEFAULT,
		GROWL_APP_ICON
	};
	CFTypeRef registerValues[4] = {
		applicationName,
		defaultAndAllNotifications,
		defaultAndAllNotifications,
		icon
	};
	CFDictionaryRef registerInfo = CFDictionaryCreate(kCFAllocatorDefault, registerKeys, registerValues, 4, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	CFRelease(defaultAndAllNotifications);
	CFRelease(icon);

	// Notify
	CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
	CFStringRef clickContext = CFUUIDCreateString(kCFAllocatorDefault, uuid);
	CFNumberRef priorityNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &priority);
	CFBooleanRef stickyValue = isSticky ? kCFBooleanTrue : kCFBooleanFalse;
	CFMutableDictionaryRef notificationInfo = CFDictionaryCreateMutable(kCFAllocatorDefault ,9, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	CFDictionarySetValue(notificationInfo, GROWL_NOTIFICATION_NAME, name);
	CFDictionarySetValue(notificationInfo, GROWL_APP_NAME, applicationName);
	CFDictionarySetValue(notificationInfo, GROWL_NOTIFICATION_TITLE, title);
	CFDictionarySetValue(notificationInfo, GROWL_NOTIFICATION_DESCRIPTION, desc);
	CFDictionarySetValue(notificationInfo, GROWL_NOTIFICATION_PRIORITY, priorityNumber);
	CFDictionarySetValue(notificationInfo, GROWL_NOTIFICATION_STICKY, stickyValue);
	CFDictionarySetValue(notificationInfo, GROWL_NOTIFICATION_ICON, icon);
	CFDictionarySetValue(notificationInfo, GROWL_NOTIFICATION_CLICK_CONTEXT, clickContext);
	if (identifierString) {
		CFDictionarySetValue(notificationInfo, GROWL_NOTIFICATION_IDENTIFIER, identifierString);
		CFRelease(identifierString);
	}
	CFRelease(priorityNumber);
	CFRelease(applicationName);
	CFRelease(title);
	CFRelease(desc);
	CFRelease(clickContext);
	if (haveProgress) {
		CFNumberRef progressNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &progress);
		CFDictionarySetValue(notificationInfo, GROWL_NOTIFICATION_PROGRESS, progressNumber);
		CFRelease(progressNumber);
	}

	if (host) {
		if (cdsaInit()) {
			NSLog(@"ERROR: Could not initialize CDSA.");
		} else {
			{
				NSSocketPort *port = [[NSSocketPort alloc] initRemoteWithTCPPort:GROWL_TCP_PORT host:[NSString stringWithCString:host]];
				NSConnection *connection = [[NSConnection alloc] initWithReceivePort:nil sendPort:port];
				CFStringRef passwordString;
				if (password)
					passwordString = CFStringCreateWithCString(kCFAllocatorDefault, password, kCFStringEncodingUTF8);
				else
					passwordString = NULL;

				MD5Authenticator *authenticator = [[MD5Authenticator alloc] initWithPassword:(NSString *)passwordString];
				if (passwordString)
					CFRelease(passwordString);
				[connection setDelegate:authenticator];
				@try {
					NSDistantObject *theProxy = [connection rootProxy];
					[theProxy setProtocolForProxy:@protocol(GrowlNotificationProtocol)];
					id<GrowlNotificationProtocol> growlProxy = (id)theProxy;

					[growlProxy registerApplicationWithDictionary:(NSDictionary *)registerInfo];
					[growlProxy postNotificationWithDictionary:(NSDictionary *)notificationInfo];
				} @catch(NSException *e) {
					if ([[e name] isEqualToString:NSFailedAuthenticationException])
						NSLog(@"Authentication failed");
					else
						NSLog(@"Exception: %@", [e name]);
				} @finally {
					[port release];
					[connection release];
					[authenticator release];
				}
			}
		}
	} else {
		CFNotificationCenterRef distCenter = CFNotificationCenterGetDistributedCenter();
		if (wait) {
			CFMutableStringRef notificationName = CFStringCreateMutable(kCFAllocatorDefault, 0);
			CFStringAppend(notificationName, applicationName);
			CFStringAppend(notificationName, (CFStringRef)GROWL_NOTIFICATION_CLICKED);
			CFNotificationCenterAddObserver(distCenter,
											"growlnotify",
											notificationDismissed,
											notificationName,
											/*object*/ NULL,
											CFNotificationSuspensionBehaviorCoalesce);
			CFStringReplaceAll(notificationName, applicationName);
			CFStringAppend(notificationName, (CFStringRef)GROWL_NOTIFICATION_TIMED_OUT);
			CFNotificationCenterAddObserver(distCenter,
											"growlnotify",
											notificationDismissed,
											notificationName,
											/*object*/ NULL,
											CFNotificationSuspensionBehaviorCoalesce);
			CFRelease(notificationName);
		}

		NSConnection *connection = [NSConnection connectionWithRegisteredName:@"GrowlApplicationBridgePathway" host:nil];
		if (connection) {
			//Post to Growl via GrowlApplicationBridgePathway
			@try {
				NSDistantObject *theProxy = [connection rootProxy];
				[theProxy setProtocolForProxy:@protocol(GrowlNotificationProtocol)];
				id<GrowlNotificationProtocol> growlProxy = (id)theProxy;
				[growlProxy registerApplicationWithDictionary:(NSDictionary *)registerInfo];
				[growlProxy postNotificationWithDictionary:(NSDictionary *)notificationInfo];
			} @catch(NSException *e) {
				NSLog(@"exception while sending notification: %@", e);
			}
		} else {
			//Post to Growl via NSDistributedNotificationCenter
			NSLog(@"could not find local GrowlApplicationBridgePathway, falling back to NSDNC");
			CFNotificationCenterPostNotificationWithOptions(distCenter, (CFStringRef)GROWL_APP_REGISTRATION, NULL, registerInfo, kCFNotificationPostToAllSessions);
			CFNotificationCenterPostNotificationWithOptions(distCenter, (CFStringRef)GROWL_NOTIFICATION, NULL, notificationInfo, kCFNotificationPostToAllSessions);
		}

		if (wait) {
			/* Run the run loop until it is manually cancelled in notificationDismissed() */
			CFRunLoopRun();
		} else {
			/* Run the run loop until we don't have any sources to proces
			 * to ensure the distributed notification is posted */
			while (CFRunLoopRunInMode(/* mode */ kCFRunLoopDefaultMode,
									  /* seconds; 0 means single iteration */ 0,
									  /* returnAfterSourceHandled */ TRUE) == kCFRunLoopRunHandledSource);
		}
	}

	if (port)
		free(port);

	CFRelease(registerInfo);
	CFRelease(notificationInfo);
	[pool release];

	return code;
}
