//
//  GrowlApplicationController.m
//  Growl
//
//  Created by Karl Adam on Thu Apr 22 2004.
//  Renamed from GrowlController by Mac-arena the Bored Zo on 2005-06-28.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "GrowlApplicationController.h"
#import "GrowlPreferencesController.h"
#import "GrowlApplicationTicket.h"
#import "GrowlApplicationNotification.h"
#import "GrowlTicketController.h"
#import "GrowlNotificationTicket.h"
#import "GrowlDistributedNotificationPathway.h"
#import "GrowlRemotePathway.h"
#import "GrowlUDPPathway.h"
#import "GrowlApplicationBridgePathway.h"
#import "NSStringAdditions.h"
#import "GrowlDisplayPlugin.h"
#import "GrowlPluginController.h"
#import "GrowlIdleStatusController.h"
#import "GrowlDefines.h"
#import "GrowlVersionUtilities.h"
#import "SVNRevision.h"
#import "GrowlLog.h"
#import "GrowlNotificationCenter.h"
#import "MD5Authenticator.h"
#include "CFGrowlAdditions.h"
#include "CFURLAdditions.h"
#include "CFDictionaryAdditions.h"
#include "CFMutableDictionaryAdditions.h"
#include "cdsa.h"
#include <SystemConfiguration/SystemConfiguration.h>
#include <sys/socket.h>
#include <sys/fcntl.h>
#include <netinet/in.h>
#include "CPS.h"

// check every 24 hours
#define UPDATE_CHECK_INTERVAL	24.0*3600.0

extern CFRunLoopRef CFRunLoopGetMain(void);

@interface GrowlApplicationController (private)
- (void) notificationClicked:(NSNotification *)notification;
- (void) notificationTimedOut:(NSNotification *)notification;
@end

static BOOL isFullscreenProcessInFront(void) {
	OSErr             result;
	CPSProcessSerNum  frontProcess;
	CPSProcessInfoRec info;

	result = CPSGetFrontProcess(&frontProcess);
	if (result != noErr)
		return NO;

	result = CPSGetProcessInfo(&frontProcess, &info,
							   /*path*/ NULL,
							   /*maxPathLen*/ 0,
							   /*len*/ NULL,
							   /*name*/ NULL,
							   /*maxNameLen*/ 0);
	if (result != noErr)
		return NO;

	NSLog(@"Foreground process: %d fullscreen: %s\n", info.UnixPID, (info.Attributes & kCPSFullScreenAttr) ? "YES" : "NO");
	return (info.Attributes & kCPSFullScreenAttr) != 0;
}

static struct Version version = { 0U, 8U, 0U, releaseType_svn, 0U, };
//XXX - update these constants whenever the version changes

#pragma mark -

static void checkVersion(CFRunLoopTimerRef timer, void *context) {
#pragma unused(timer)
	GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];

	if (![preferences isBackgroundUpdateCheckEnabled])
		return;

	GrowlApplicationController *appController = (GrowlApplicationController *)context;
	CFURLRef versionCheckURL = [appController versionCheckURL];

	NSDictionary *productVersionDict = [[NSDictionary alloc] initWithContentsOfURL:(NSURL *)versionCheckURL];

	NSString *currVersionNumber = [GrowlApplicationController growlVersion];
	NSString *latestVersionNumber = [productVersionDict objectForKey:@"Growl"];

	NSString *downloadURLString = [productVersionDict objectForKey:@"GrowlDownloadURL"];

	/* do nothing and be quiet if there is no active connection, if the
	 *	version dictionary could not be downloaded, or if the version dictionary
	 *	is missing either of these keys.
	 */
	if (downloadURLString && latestVersionNumber) {
		[preferences setObject:[NSDate date] forKey:LastUpdateCheckKey];
		if (compareVersionStringsTranslating1_0To0_5(latestVersionNumber, currVersionNumber) > 0) {
			CFURLRef downloadURL = CFURLCreateWithString(kCFAllocatorDefault,
														 (CFStringRef)downloadURLString,
														 /*baseURL*/ NULL);
			CFStringRef title = CFCopyLocalizedString(CFSTR("Update Available"), /*comment*/ NULL);
			CFStringRef description = CFCopyLocalizedString(CFSTR("A newer version of Growl is available online. Click here to download it now."), /*comment*/ NULL);
			[GrowlApplicationBridge notifyWithTitle:(NSString *)title
				                        description:(NSString *)description
				                   notificationName:@"Growl update available"
			                               iconData:[appController applicationIconDataForGrowl]
			                               priority:1
			                               isSticky:YES
			                           clickContext:(id)downloadURL
										 identifier:nil];
			CFRelease(title);
			CFRelease(description);
		}
	}

	[productVersionDict release];
}

@implementation GrowlApplicationController

+ (GrowlApplicationController *) sharedController {
	return [self sharedInstance];
}

- (id) initSingleton {
	if ((self = [super initSingleton])) {
		CSSM_RETURN crtn = cdsaInit();
		if (crtn) {
			NSLog(@"ERROR: Could not initialize CDSA.");
			cssmPerror("cdsaInit", crtn);
			[self release];
			return nil;
		}

		// initialize GrowlPreferencesController before observing GrowlPreferencesChanged
		GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];

		NSDistributedNotificationCenter *NSDNC = [NSDistributedNotificationCenter defaultCenter];

		[NSDNC addObserver:self
				  selector:@selector(preferencesChanged:)
					  name:GrowlPreferencesChanged
					object:nil];
		[NSDNC addObserver:self
				  selector:@selector(showPreview:)
					  name:GrowlPreview
					object:nil];
		[NSDNC addObserver:self
				  selector:@selector(shutdown:)
					  name:GROWL_SHUTDOWN
					object:nil];
		[NSDNC addObserver:self
				  selector:@selector(replyToPing:)
					  name:GROWL_PING
					object:nil];

		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self
			   selector:@selector(notificationClicked:)
				   name:GROWL_NOTIFICATION_CLICKED
				 object:nil];
		[nc addObserver:self
			   selector:@selector(notificationTimedOut:)
				   name:GROWL_NOTIFICATION_TIMED_OUT
				 object:nil];

		authenticator = [[MD5Authenticator alloc] init];

		//XXX temporary DNC pathway hack - remove when real pathway support is in
		dncPathway = [[GrowlDistributedNotificationPathway alloc] init];

		ticketController = [GrowlTicketController sharedController];

		[self versionDictionary];

		CFStringRef file = (CFStringRef)[[NSBundle mainBundle] pathForResource:@"GrowlDefaults" ofType:@"plist"];
		CFURLRef fileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, file, kCFURLPOSIXPathStyle, false);
		NSDictionary *defaultDefaults = (NSDictionary *)createPropertyListFromURL((NSURL *)fileURL, kCFPropertyListImmutable, NULL, NULL);
		CFRelease(fileURL);
		if (defaultDefaults) {
			[preferences registerDefaults:defaultDefaults];
			[defaultDefaults release];
		}

		[self preferencesChanged:nil];

		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
															   selector:@selector(applicationLaunched:)
																   name:NSWorkspaceDidLaunchApplicationNotification
																 object:nil];

		growlIcon = [[NSImage imageNamed:@"NSApplicationIcon"] retain];

		[GrowlApplicationBridge setGrowlDelegate:self];

		GrowlIdleStatusController_init();
		[nc addObserver:self
			   selector:@selector(idleStatus:)
				   name:@"GrowlIdleStatus"
				 object:nil];

		NSDate *lastCheck = [preferences objectForKey:LastUpdateCheckKey];
		NSDate *now = [NSDate date];
		if (!lastCheck || [now timeIntervalSinceDate:lastCheck] > UPDATE_CHECK_INTERVAL) {
			checkVersion(NULL, self);
			lastCheck = now;
		}
		CFRunLoopTimerContext context = {0, self, NULL, NULL, NULL};
		updateTimer = CFRunLoopTimerCreate(kCFAllocatorDefault, [[lastCheck addTimeInterval:UPDATE_CHECK_INTERVAL] timeIntervalSinceReferenceDate], UPDATE_CHECK_INTERVAL, 0, 0, checkVersion, &context);
		CFRunLoopAddTimer(CFRunLoopGetMain(), updateTimer, kCFRunLoopCommonModes);

		// create and register GrowlNotificationCenter
		growlNotificationCenter = [[GrowlNotificationCenter alloc] init];
		growlNotificationCenterConnection = [[NSConnection alloc] initWithReceivePort:[NSPort port] sendPort:nil];
		//[growlNotificationCenterConnection enableMultipleThreads];
		[growlNotificationCenterConnection setRootObject:growlNotificationCenter];
		if (![growlNotificationCenterConnection registerName:@"GrowlNotificationCenter"])
			NSLog(@"WARNING: could not register GrowlNotificationCenter");

		// initialize GrowlApplicationBridgePathway
		[GrowlApplicationBridgePathway standardPathway];
	}

	return self;
}

- (void) idleStatus:(NSNotification *)notification {
	if ([[notification object] isEqualToString:@"Idle"]) {
		GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];
		int idleThreshold;
		NSNumber *value = [preferences objectForKey:@"IdleThreshold"];
		NSString *description;

		idleThreshold = (value ? [value intValue] : MACHINE_IDLE_THRESHOLD);
		description = [NSString stringWithFormat:NSLocalizedString(@"No activity for more than %d seconds.", nil), idleThreshold];
		if ([preferences stickyWhenAway])
			description = [description stringByAppendingString:NSLocalizedString(@" New notifications will be sticky.", nil)];

		[GrowlApplicationBridge notifyWithTitle:NSLocalizedString(@"User went idle", nil)
									description:description
							   notificationName:@"User went idle"
									   iconData:growlIconData
									   priority:-1
									   isSticky:NO
								   clickContext:nil
									 identifier:nil];
	} else {
		[GrowlApplicationBridge notifyWithTitle:NSLocalizedString(@"User returned", nil)
									description:NSLocalizedString(@"User activity detected. New notifications will not be sticky by default.", nil)
							   notificationName:@"User returned"
									   iconData:growlIconData
									   priority:-1
									   isSticky:NO
								   clickContext:nil
									 identifier:nil];
	}
}

- (void) destroy {
	//free your world
	[mainThread release]; mainThread = nil;
	[self stopServer];
	[authenticator    release]; authenticator = nil;
	[dncPathway       release]; dncPathway = nil; //XXX temporary DNC pathway hack - remove when real pathway support is in
	[destinations     release]; destinations = nil;
	[growlIcon        release]; growlIcon = nil;
	[displayController release]; displayController = nil;

	if (versionCheckURL)
		CFRelease(versionCheckURL);

	GrowlIdleStatusController_dealloc();
	
	CFRunLoopTimerInvalidate(updateTimer);
	CFRelease(updateTimer);

	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];

	[growlNotificationCenterConnection invalidate];
	[growlNotificationCenterConnection release]; growlNotificationCenterConnection = nil;
	[growlNotificationCenter           release]; growlNotificationCenter = nil;

	cdsaShutdown();

	[super destroy];
}

#pragma mark -
#pragma mark this is a temp fix just to get things running so we can test GPC with the display plugins.  im pretty sure that this is intended to be in a pathway plugin now....

- (void) netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
#pragma unused(sender)
	NSLog(@"WARNING: could not publish Growl service. Error: %@", errorDict);
}

- (BOOL) connection:(NSConnection *)ancestor shouldMakeNewConnection:(NSConnection *)conn {
	[conn setDelegate:[ancestor delegate]];
	return YES;
}

- (NSData *) authenticationDataForComponents:(NSArray *)components {
	return [authenticator authenticationDataForComponents:components];
}

- (BOOL) authenticateComponents:(NSArray *)components withData:(NSData *)signature {
	return [authenticator authenticateComponents:components withData:signature];
}

- (void) startServer {
	socketPort = [[NSSocketPort alloc] initWithTCPPort:GROWL_TCP_PORT];
	serverConnection = [[NSConnection alloc] initWithReceivePort:socketPort sendPort:nil];
	server = [[GrowlRemotePathway alloc] init];
	[serverConnection setRootObject:server];
	[serverConnection setDelegate:self];

	// register with the default NSPortNameServer on the local host
	if (![serverConnection registerName:@"GrowlServer"])
		NSLog(@"WARNING: could not register Growl server.");

	// configure and publish the Bonjour service
	CFStringRef serviceName = SCDynamicStoreCopyComputerName(/*store*/ NULL,
															 /*nameEncoding*/ NULL);
	service = [[NSNetService alloc] initWithDomain:@""	// use local registration domain
											  type:@"_growl._tcp."
											  name:(NSString *)serviceName
											  port:GROWL_TCP_PORT];
	CFRelease(serviceName);
	[service setDelegate:self];
	[service publish];

	// start UDP service
	udpServer = [[GrowlUDPPathway alloc] init];
}

- (void) stopServer {
	[udpServer        release];
	[serverConnection registerName:nil];	// unregister
	[serverConnection invalidate];
	[serverConnection release];
	[socketPort       invalidate];
	[socketPort       release];
	[server           release];
	[service          stop];
	[service          release];
	service = nil;
}

- (void) startStopServer {
	BOOL enabled = [[GrowlPreferencesController sharedController] boolForKey:GrowlStartServerKey];

	// Setup notification server
	if (enabled && !service)
		[self startServer];
	else if (!enabled && service)
		[self stopServer];
}

#pragma mark -

- (void) showPreview:(NSNotification *) note {
	NSString *displayName = [note object];
	GrowlDisplayPlugin *displayPlugin = (GrowlDisplayPlugin *)[[GrowlPluginController sharedController] displayPluginInstanceWithName:displayName author:nil version:nil type:nil];

	NSString *desc = [[NSString alloc] initWithFormat:@"This is a preview of the %@ display", displayName];
	NSNumber *priority = [[NSNumber alloc] initWithInt:0];
	NSNumber *sticky = [[NSNumber alloc] initWithBool:NO];
	NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:
		@"Growl",   GROWL_APP_NAME,
		@"Preview", GROWL_NOTIFICATION_NAME,
		@"Preview", GROWL_NOTIFICATION_TITLE,
		desc,       GROWL_NOTIFICATION_DESCRIPTION,
		priority,   GROWL_NOTIFICATION_PRIORITY,
		sticky,     GROWL_NOTIFICATION_STICKY,
		growlIcon,  GROWL_NOTIFICATION_ICON,
		nil];
	[desc     release];
	[priority release];
	[sticky   release];
	GrowlApplicationNotification *notification = [[GrowlApplicationNotification alloc] initWithDictionary:info];
	[info release];
	[displayPlugin displayNotification:notification];
	[notification release];
}

- (void) forwardDictionary:(NSDictionary *)dict withSelector:(SEL)forwardMethod {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSNumber *requestTimeout = [defaults objectForKey:@"ForwardingRequestTimeout"];
	NSNumber *replyTimeout = [defaults objectForKey:@"ForwardingReplyTimeout"];

	NSEnumerator *enumerator = [destinations objectEnumerator];
	NSDictionary *entry;
	while ((entry = [enumerator nextObject])) {
		if (getBooleanForKey(entry, @"use") && getBooleanForKey(entry, @"active")) {
			NSData *destAddress = getObjectForKey(entry, @"address");
			NSString *password = getObjectForKey(entry, @"password");
			NSSocketPort *serverPort = [[NSSocketPort alloc]
				initRemoteWithProtocolFamily:AF_INET
								  socketType:SOCK_STREAM
									protocol:IPPROTO_TCP
									 address:destAddress];

			NSConnection *connection = [[NSConnection alloc] initWithReceivePort:nil
																		sendPort:serverPort];
			MD5Authenticator *auth = [[MD5Authenticator alloc] initWithPassword:password];
			[connection setDelegate:auth];

			if (requestTimeout && [requestTimeout respondsToSelector:@selector(floatValue)])
				[connection setRequestTimeout:[requestTimeout floatValue]];
			if (replyTimeout && [replyTimeout respondsToSelector:@selector(floatValue)])
				[connection setReplyTimeout:[replyTimeout floatValue]];

			@try {
				NSDistantObject *theProxy = [connection rootProxy];
				[theProxy setProtocolForProxy:@protocol(GrowlNotificationProtocol)];
				NSProxy <GrowlNotificationProtocol> *growlProxy = (NSProxy <GrowlNotificationProtocol> *)theProxy;
				[growlProxy performSelector:forwardMethod withObject:dict];
			} @catch (NSException *e) {
				if ([[e name] isEqualToString:@"NSFailedAuthenticationException"]) {
					NSString *addressString = createStringWithAddressData(destAddress);
					NSString *hostName = createHostNameForAddressData(destAddress);
					NSLog(@"Authentication failed while forwarding to %@ (%@)",
						  addressString, hostName);
					[addressString release];
					[hostName      release];
				} else
					NSLog(@"Exception while forwarding dictionary with selector %s (description of dictionary follows): %@\n%@", forwardMethod, e, dict);
			} @finally {
				[connection invalidate];
				[serverPort invalidate];
				[serverPort release];
				[connection release];
				[auth release];
			}
		}
	}

	[pool release];
}

- (void) forwardNotification:(NSDictionary *)dict {
	[self forwardDictionary:dict withSelector:@selector(postNotificationWithDictionary:)];
}

- (void) forwardRegistration:(NSDictionary *)dict {
	[self forwardDictionary:dict withSelector:@selector(registerApplicationWithDictionary:)];
}

- (void) dispatchNotificationWithDictionary:(NSDictionary *) dict {
	GrowlLog_logNotificationDictionary(dict);

	// Make sure this notification is actually registered
	NSString *appName = getObjectForKey(dict, GROWL_APP_NAME);
	GrowlApplicationTicket *ticket = [ticketController ticketForApplicationName:appName];
	NSString *notificationName = getObjectForKey(dict, GROWL_NOTIFICATION_NAME);
	if (!ticket || ![ticket isNotificationAllowed:notificationName]) {
		// Either the app isn't registered or the notification is turned off
		// We should do nothing
		return;
	}

	NSMutableDictionary *aDict = [dict mutableCopy];

	// Check icon
	Class NSImageClass = [NSImage class];
	Class NSDataClass  = [NSData  class];
	NSImage *icon = nil;
	id image = getObjectForKey(aDict, GROWL_NOTIFICATION_ICON);
	if (image) {
		if ([image isKindOfClass:NSImageClass])
			icon = [image copy];
		else if ([image isKindOfClass:NSDataClass])
			icon = [[NSImage alloc] initWithData:image];
	}
	if (!icon)
		icon = [[ticket icon] copy];

	if (icon) {
		setObjectForKey(aDict, GROWL_NOTIFICATION_ICON, icon);
		[icon release];
	} else {
		[aDict removeObjectForKey:GROWL_NOTIFICATION_ICON]; // remove any invalid NSDatas
	}

	// If app icon present, convert to NSImage
	icon = nil;
	image = getObjectForKey(aDict, GROWL_NOTIFICATION_APP_ICON);
	if (image) {
		if ([image isKindOfClass:NSImageClass])
			icon = [image copy];
		else if ([image isKindOfClass:NSDataClass])
			icon = [[NSImage alloc] initWithData:image];
	}
	if (icon) {
		setObjectForKey(aDict, GROWL_NOTIFICATION_APP_ICON, icon);
		[icon release];
	} else
		[aDict removeObjectForKey:GROWL_NOTIFICATION_APP_ICON];

	// To avoid potential exceptions, make sure we have both text and title
	if (!getObjectForKey(aDict, GROWL_NOTIFICATION_DESCRIPTION))
		setObjectForKey(aDict, GROWL_NOTIFICATION_DESCRIPTION, @"");
	if (!getObjectForKey(aDict, GROWL_NOTIFICATION_TITLE))
		setObjectForKey(aDict, GROWL_NOTIFICATION_TITLE, @"");

	//Retrieve and set the the priority of the notification
	GrowlNotificationTicket *notification = [ticket notificationTicketForName:notificationName];
	int priority = [notification priority];
	NSNumber *value;
	if (priority == GrowlPriorityUnset) {
		value = getObjectForKey(dict, GROWL_NOTIFICATION_PRIORITY);
		if (!value)
			value = [NSNumber numberWithInt:0];
	} else
		value = [NSNumber numberWithInt:priority];
	setObjectForKey(aDict, GROWL_NOTIFICATION_PRIORITY, value);

	GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];

	// Retrieve and set the sticky bit of the notification
	int sticky = [notification sticky];
	if (sticky >= 0)
		setBooleanForKey(aDict, GROWL_NOTIFICATION_STICKY, sticky);
	else if ([preferences stickyWhenAway] && !getBooleanForKey(aDict, GROWL_NOTIFICATION_STICKY))
		setBooleanForKey(aDict, GROWL_NOTIFICATION_STICKY, GrowlIdleStatusController_isIdle());

	BOOL saveScreenshot = [[NSUserDefaults standardUserDefaults] boolForKey:GROWL_SCREENSHOT_MODE];
	setBooleanForKey(aDict, GROWL_SCREENSHOT_MODE, saveScreenshot);
	setBooleanForKey(aDict, @"ClickHandlerEnabled", [ticket clickHandlersEnabled]);

	isFullscreenProcessInFront();

	if (![preferences squelchMode]) {
		GrowlDisplayPlugin *display = [notification displayPlugin];

		if (!display) {
			NSString *displayPluginName = getObjectForKey(aDict, GROWL_DISPLAY_PLUGIN);
			if (displayPluginName)
				display = (GrowlDisplayPlugin *)[[[GrowlPluginController sharedController] displayPluginDictionaryWithName:displayPluginName author:nil version:nil type:nil] pluginInstance];
		}

		if (!display)
			display = [ticket displayPlugin];

		if (!display) {
			if (!displayController) {
				NSString *displayPluginName = [[GrowlPreferencesController sharedController] defaultDisplayPluginName];
				displayController = [(GrowlDisplayPlugin *)[[GrowlPluginController sharedController] displayPluginInstanceWithName:displayPluginName author:nil version:nil type:nil] retain];
			}
			display = displayController;
		}

		GrowlApplicationNotification *appNotification = [[GrowlApplicationNotification alloc] initWithDictionary:aDict];
		[display displayNotification:appNotification];
		[appNotification release];
	}

	// send to DO observers
	[growlNotificationCenter notifyObservers:aDict];

	[aDict release];

	// forward to remote destinations
	if (enableForward && !getObjectForKey(dict, GROWL_REMOTE_ADDRESS)) {
		if ([NSThread currentThread] == mainThread)
			[NSThread detachNewThreadSelector:@selector(forwardNotification:)
									 toTarget:self
								   withObject:dict];
		else
			[self forwardNotification:dict];
	}
}

- (BOOL) registerApplicationWithDictionary:(NSDictionary *)userInfo {
	GrowlLog_logRegistrationDictionary(userInfo);

	NSString *appName = getObjectForKey(userInfo, GROWL_APP_NAME);

	GrowlApplicationTicket *newApp = [ticketController ticketForApplicationName:appName];

	NSString *notificationName;
	if (newApp) {
		[newApp reregisterWithDictionary:userInfo];
		notificationName = @"Application re-registered";
	} else {
		newApp = [[[GrowlApplicationTicket alloc] initWithDictionary:userInfo] autorelease];
		notificationName = @"Application registered";
	}

	BOOL success = YES;

	if (appName && newApp) {
		if ([newApp hasChanged])
			[newApp saveTicket];
		[ticketController addTicket:newApp];
		CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(),
											 (CFStringRef)GROWL_APP_REGISTRATION_CONF,
											 /*object*/ appName,
											 /*userInfo*/ NULL,
											 /*deliverImmediately*/ false);

		[GrowlApplicationBridge notifyWithTitle:notificationName
									description:[appName stringByAppendingString:@" registered"]
							   notificationName:notificationName
									   iconData:(id)growlIcon
									   priority:0
									   isSticky:NO
								   clickContext:nil
									 identifier:nil];

		if (enableForward && !getObjectForKey(userInfo, GROWL_REMOTE_ADDRESS)) {
			if ([NSThread currentThread] == mainThread)
				[NSThread detachNewThreadSelector:@selector(forwardRegistration:)
										 toTarget:self
									   withObject:userInfo];
			else
				[self forwardRegistration:userInfo];
		}
	} else { //!(appName && newApp)
		NSString *filename = [(appName ? appName : @"unknown-application") stringByAppendingPathExtension:GROWL_REG_DICT_EXTENSION];
		NSString *path = [@"/var/log" stringByAppendingPathComponent:filename];

		NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
		[fh seekToEndOfFile];
		if ([fh offsetInFile]) //we are not at the beginning of the file
			[fh writeData:[@"\n---\n\n" dataUsingEncoding:NSUTF8StringEncoding]];
		[fh writeData:[[[userInfo description] stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
		[fh closeFile];

		if (!appName) appName = @"with no name";

		NSLog(@"Failed application registration for application %@; wrote failed registration dictionary %p to %@", appName, userInfo, path);
		success = NO;
	}

	return success;
}

#pragma mark -
- (void) growlNotificationWasClicked:(id)clickContext {
	CFURLRef downloadURL = (CFURLRef)clickContext;
	[[NSWorkspace sharedWorkspace] openURL:(NSURL *)downloadURL];
	CFRelease(downloadURL);
}

- (void) growlNotificationTimedOut:(id)clickContext {
	CFRelease((CFTypeRef)clickContext);
}

+ (NSString *) growlVersion {
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
}

- (NSDictionary *) versionDictionary {
	if (!versionInfo) {
		if (version.releaseType == releaseType_svn)
			version.development = strtoul(SVN_REVISION, /*endptr*/ NULL, 10);

		const unsigned long long *versionNum = (const unsigned long long *)&version;
		NSNumber *complete = [[NSNumber alloc] initWithUnsignedLongLong:*versionNum];
		NSNumber *major = [[NSNumber alloc] initWithUnsignedShort:version.major];
		NSNumber *minor = [[NSNumber alloc] initWithUnsignedShort:version.minor];
		NSNumber *incremental = [[NSNumber alloc] initWithUnsignedChar:version.incremental];
		NSNumber *releaseType = [[NSNumber alloc] initWithUnsignedChar:version.releaseType];
		NSNumber *development = [[NSNumber alloc] initWithUnsignedShort:version.development];

		versionInfo = [NSDictionary dictionaryWithObjectsAndKeys:
			complete,                                  @"Complete version",
			[GrowlApplicationController growlVersion], (NSString *)kCFBundleVersionKey,

			major,                                     @"Major version",
			minor,                                     @"Minor version",
			incremental,                               @"Incremental version",
			releaseTypeNames[version.releaseType],     @"Release type name",
			releaseType,                               @"Release type",
			development,                               @"Development version",

			nil];

		[complete    release];
		[major       release];
		[minor       release];
		[incremental release];
		[releaseType release];
		[development release];
	}
	return versionInfo;
}

//this method could be moved to Growl.framework, I think.
//pass nil to get GrowlHelperApp's version as a string.
- (NSString *)stringWithVersionDictionary:(NSDictionary *)d {
	if (!d) {
		d = [self versionDictionary];
	}

	//0.6
	NSMutableString *result = [NSMutableString stringWithFormat:@"%@.%@",
		getObjectForKey(d, @"Major version"),
		getObjectForKey(d, @"Minor version")];

	//the .1 in 0.6.1
	NSNumber *incremental = getObjectForKey(d, @"Incremental version");
	if ([incremental unsignedShortValue])
		[result appendFormat:@"%@", incremental];

	NSString *releaseTypeName = getObjectForKey(d, @"Release type name");
	if ([releaseTypeName length]) {
		//"" (release), "b4", " SVN 900"
		[result appendFormat:@"%@%@", releaseTypeName, getObjectForKey(d, @"Development version")];
	}

	return result;
}

- (CFURLRef) versionCheckURL {
	if (!versionCheckURL)
		versionCheckURL = CFURLCreateWithString(kCFAllocatorDefault, CFSTR("http://growl.info/version.xml"), NULL);
	return versionCheckURL;
}

- (NSThread *)mainThread {
	return mainThread;
}

#pragma mark -

- (void) preferencesChanged:(NSNotification *) note {
	//[note object] is the changed key. A nil key means reload our tickets.
	id object = [note object];
	if (!note || (object && [object isEqualTo:GrowlStartServerKey]))
		[self startStopServer];
	if (!note || (object && [object isEqualTo:GrowlUserDefaultsKey]))
		[[GrowlPreferencesController sharedController] synchronize];
	if (!note || (object && [object isEqualTo:GrowlEnabledKey]))
		growlIsEnabled = [[GrowlPreferencesController sharedController] boolForKey:GrowlEnabledKey];
	if (!note || (object && [object isEqualTo:GrowlEnableForwardKey]))
		enableForward = [[GrowlPreferencesController sharedController] isForwardingEnabled];
	if (!note || (object && [object isEqualTo:GrowlForwardDestinationsKey])) {
		[destinations release];
		destinations = [[[GrowlPreferencesController sharedController] objectForKey:GrowlForwardDestinationsKey] retain];
	}
	if (!note || !object)
		[ticketController loadAllSavedTickets];
	if (!note || (object && [object isEqualTo:GrowlDisplayPluginKey]))
		// force reload
		[displayController release];
		displayController = nil;
	if (object) {
		if ([object isEqualTo:@"GrowlTicketDeleted"]) {
			NSString *ticketName = [[note userInfo] objectForKey:@"TicketName"];
			[ticketController removeTicketForApplicationName:ticketName];
		} else if ([object isEqualTo:@"GrowlTicketChanged"]) {
			NSString *ticketName = [[note userInfo] objectForKey:@"TicketName"];
			GrowlApplicationTicket *newTicket = [[GrowlApplicationTicket alloc] initTicketForApplication:ticketName];
			if (newTicket) {
				[ticketController addTicket:newTicket];
				[newTicket release];
			}
		} else if ([object isEqualTo:GrowlUDPPortKey]) {
			[self stopServer];
			[self startServer];
		}
	}
}

- (void) shutdown:(NSNotification *) note {
#pragma unused(note)
	[NSApp terminate:nil];
}

- (void) replyToPing:(NSNotification *) note {
#pragma unused(note)
	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(),
										 (CFStringRef)GROWL_PONG,
										 /*object*/ NULL,
										 /*userInfo*/ NULL,
										 /*deliverImmediately*/ false);
}

#pragma mark NSApplication Delegate Methods

- (BOOL) application:(NSApplication *)theApplication openFile:(NSString *)filename {
#pragma unused(theApplication)
	BOOL retVal = NO;
	NSString *pathExtension = [filename pathExtension];

	if ([pathExtension isEqualToString:GROWL_REG_DICT_EXTENSION]) {
		CFURLRef fileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)filename, kCFURLPOSIXPathStyle, false);
		NSDictionary *regDict = (NSDictionary *)createPropertyListFromURL((NSURL *)fileURL, kCFPropertyListImmutable, NULL, NULL);
		CFRelease(fileURL);

		/*GrowlApplicationBridge 0.6 communicates registration to Growl by
		 *	writing a dictionary file to the temporary items folder, then
		 *	opening the file with GrowlHelperApp.
		 *we need to delete these, lest we fill up the user's disk or (on Tiger)
		 *	surprise him with a 'Recovered items' folder in his Trash.
		 */
		if ([filename isSubpathOf:NSTemporaryDirectory()]) //assume we got here from GAB
			[[NSFileManager defaultManager] removeFileAtPath:filename handler:nil];

		if (regDict) {
			//Register this app using the indicated dictionary
			[self registerApplicationWithDictionary:regDict];
			[regDict release];

			retVal = YES;
		}
	} else {
		GrowlPluginController *controller = [GrowlPluginController sharedController];
		//the set returned by GrowlPluginController is case-insensitive. yay!
		if ([[controller registeredPluginTypes] containsObject:pathExtension]) {
			[controller installPluginFromPath:filename];

			retVal = YES;
		}
	}

	/*If Growl is not enabled and was not already running before
	 *	(for example, via an autolaunch even though the user's last
	 *	preference setting was to click "Stop Growl," setting enabled to NO),
	 *	quit having registered; otherwise, remain running.
	 */
	if (!growlIsEnabled && !growlFinishedLaunching)
		[NSApp terminate:self];

	return retVal;
}

- (void) applicationWillFinishLaunching:(NSNotification *)aNotification {
#pragma unused(aNotification)
	mainThread = [[NSThread currentThread] retain];

	BOOL printVersionAndExit = [[NSUserDefaults standardUserDefaults] boolForKey:@"PrintVersionAndExit"];
	if (printVersionAndExit) {
		printf("This is GrowlHelperApp version %s.\n"
			   "PrintVersionAndExit was set to %u, so GrowlHelperApp will now exit.\n",
			   [[self stringWithVersionDictionary:nil] UTF8String],
			   printVersionAndExit);
		[NSApp terminate:nil];
	}

	NSFileManager *fs = [NSFileManager defaultManager];

	NSString *destDir, *subDir;
	NSArray *searchPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, /*expandTilde*/ YES);

	destDir = [searchPath objectAtIndex:0U]; //first == last == ~/Library
	[fs createDirectoryAtPath:destDir attributes:nil];
	destDir = [destDir stringByAppendingPathComponent:@"Application Support"];
	[fs createDirectoryAtPath:destDir attributes:nil];
	destDir = [destDir stringByAppendingPathComponent:@"Growl"];
	[fs createDirectoryAtPath:destDir attributes:nil];

	subDir  = [destDir stringByAppendingPathComponent:@"Tickets"];
	[fs createDirectoryAtPath:subDir attributes:nil];
	subDir  = [destDir stringByAppendingPathComponent:@"Plugins"];
	[fs createDirectoryAtPath:subDir attributes:nil];
}

//Post a notification when we are done launching so the application bridge can inform participating applications
- (void) applicationDidFinishLaunching:(NSNotification *)aNotification {
#pragma unused(aNotification)
	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(),
										 (CFStringRef)GROWL_IS_READY,
										 /*object*/ NULL,
										 /*userInfo*/ NULL,
										 /*deliverImmediately*/ true);
	growlFinishedLaunching = YES;
}

//Same as applicationDidFinishLaunching, called when we are asked to reopen (that is, we are already running)
- (BOOL) applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
#pragma unused(theApplication, flag)
	return NO;
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
#pragma unused(theApplication)
	return NO;
}

- (void) applicationWillTerminate:(NSNotification *)notification {
#pragma unused(notification)
	[GrowlAbstractSingletonObject destroyAllSingletons];	//Release all our controllers
}

#pragma mark Auto-discovery

//called by NSWorkspace when an application launches.
- (void) applicationLaunched:(NSNotification *)notification {
	NSDictionary *userInfo = [notification userInfo];

	if (!userInfo)
		return;

	NSString *appPath = getObjectForKey(userInfo, @"NSApplicationPath");

	if (appPath) {
		NSString *ticketPath = [NSBundle pathForResource:@"Growl Registration Ticket" ofType:GROWL_REG_DICT_EXTENSION inDirectory:appPath];
		if (ticketPath) {
			CFURLRef ticketURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)ticketPath, kCFURLPOSIXPathStyle, false);
			NSMutableDictionary *ticket = (NSMutableDictionary *)createPropertyListFromURL((NSURL *)ticketURL, kCFPropertyListMutableContainers, NULL, NULL);

			if (ticket) {
				NSString *appName = getObjectForKey(userInfo, @"NSApplicationName");

				//set the app's name in the dictionary, if it's not present already.
				if (![ticket objectForKey:GROWL_APP_NAME])
					[ticket setObject:appName forKey:GROWL_APP_NAME];

				if ([GrowlApplicationTicket isValidTicketDictionary:ticket]) {
					NSLog(@"Auto-discovered registration ticket in %@ (located at %@)", appName, appPath);

					/* set the app's location in the dictionary, avoiding costly
					 *	lookups later.
					 */
					NSURL *url = [[NSURL alloc] initFileURLWithPath:appPath];
					NSDictionary *file_data = createDockDescriptionWithURL(url);
					id location = file_data ? [NSDictionary dictionaryWithObject:file_data forKey:@"file-data"] : appPath;
					[file_data release];
					[ticket setObject:location forKey:GROWL_APP_LOCATION];
					[url release];

					//write the new ticket to disk, and be sure to launch this ticket instead of the one in the app bundle.
					CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
					CFStringRef uuidString = CFUUIDCreateString(kCFAllocatorDefault, uuid);
					CFRelease(uuid);
					ticketPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:(NSString *)uuidString] stringByAppendingPathExtension:GROWL_REG_DICT_EXTENSION];
					CFRelease(uuidString);
					[ticket writeToFile:ticketPath atomically:NO];

					/* open the ticket with ourselves.
					 * we need to use LS in order to launch it with this specific
					 *	GHA, rather than some other.
					 */
					CFURLRef myURL      = (CFURLRef)copyCurrentProcessURL();
					NSArray *URLsToOpen = [NSArray arrayWithObject:(NSURL *)ticketURL];
					struct LSLaunchURLSpec spec = {
						.appURL = myURL,
						.itemURLs = (CFArrayRef)URLsToOpen,
						.passThruParams = NULL,
						.launchFlags = kLSLaunchDontAddToRecents | kLSLaunchDontSwitch | kLSLaunchAsync,
						.asyncRefCon = NULL,
					};
					OSStatus err = LSOpenFromURLSpec(&spec, /*outLaunchedURL*/ NULL);
					if (err != noErr)
						NSLog(@"The registration ticket for %@ could not be opened (LSOpenFromURLSpec returned %li). Pathname for the ticket file: %@", appName, (long)err, ticketPath);
					CFRelease(myURL);
				} else if ([GrowlApplicationTicket isKnownTicketVersion:ticket]) {
					NSLog(@"%@ (located at %@) contains an invalid registration ticket - developer, please consult Growl developer documentation (http://growl.info/documentation/developer/)", appName, appPath);
				} else {
					NSLog(@"%@ (located at %@) contains a ticket whose version (%i) is unrecognised by this version (%@) of Growl", appName, appPath, [[ticket objectForKey:GROWL_TICKET_VERSION] intValue], [self stringWithVersionDictionary:nil]);
				}
				[ticket release];
			}
			CFRelease(ticketURL);
		}
	}
}

#pragma mark Growl Delegate Methods
- (NSData *) applicationIconDataForGrowl {
	return (id)growlIcon;
}

- (NSString *) applicationNameForGrowl {
	return @"Growl";
}

- (NSDictionary *) registrationDictionaryForGrowl {
	NSArray *allNotifications = [[NSArray alloc] initWithObjects:
		@"Growl update available",
		@"Application registered",
		@"Application re-registered",
		@"User went idle",
		@"User returned",
		nil];

	NSNumber *default0 = [[NSNumber alloc] initWithUnsignedInt:0U];
	NSNumber *default1 = [[NSNumber alloc] initWithUnsignedInt:1U];
	NSArray *defaultNotifications = [[NSArray alloc] initWithObjects:
		default0, default1, nil];
	[default0 release];
	[default1 release];

	NSDictionary *registrationDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
		allNotifications,     GROWL_NOTIFICATIONS_ALL,
		defaultNotifications, GROWL_NOTIFICATIONS_DEFAULT,
		nil];

	[allNotifications     release];
	[defaultNotifications release];

	return registrationDictionary;
}

@end

#pragma mark -

@implementation GrowlApplicationController (private)

#pragma mark -

- (void) notificationClicked:(NSNotification *)notification {
	NSString *appName, *growlNotificationClickedName;
	NSString *suffix;
	NSDictionary *clickInfo;
	NSDictionary *userInfo;

	userInfo = [notification userInfo];

	//Build the application-specific notification name
	appName = [notification object];
	if (getBooleanForKey(userInfo, @"ClickHandlerEnabled")) {
		suffix = GROWL_NOTIFICATION_CLICKED;
	} else {
		/*
		 * send GROWL_NOTIFICATION_TIMED_OUT instead, so that an application is
		 * guaranteed to receive feedback for every notification.
		 */
		suffix = GROWL_NOTIFICATION_TIMED_OUT;
	}
	NSNumber *pid = getObjectForKey(userInfo, GROWL_APP_PID);
	if (pid)
		growlNotificationClickedName = [[NSString alloc] initWithFormat:@"%@-%@-%@",
			appName, pid, suffix];
	else
		growlNotificationClickedName = [[NSString alloc] initWithFormat:@"%@%@",
			appName, suffix];
	clickInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
		getObjectForKey(userInfo, GROWL_KEY_CLICKED_CONTEXT), GROWL_KEY_CLICKED_CONTEXT,
		nil];

	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(),
										 (CFStringRef)growlNotificationClickedName,
										 /*object*/ NULL,
										 /*userInfo*/ (CFDictionaryRef)clickInfo,
										 /*deliverImmediately*/ true);

	[clickInfo release];
	[growlNotificationClickedName release];
}

- (void) notificationTimedOut:(NSNotification *)notification {
	NSString *appName, *growlNotificationTimedOutName;
	NSDictionary *clickInfo;
	NSDictionary *userInfo;

	userInfo = [notification userInfo];

	//Build the application-specific notification name
	appName = [notification object];
	NSNumber *pid = [userInfo objectForKey:GROWL_APP_PID];
	if (pid)
		growlNotificationTimedOutName = [[NSString alloc] initWithFormat:@"%@-%@-%@",
			appName, pid, GROWL_NOTIFICATION_TIMED_OUT];
	else
		growlNotificationTimedOutName = [[NSString alloc] initWithFormat:@"%@%@",
			appName, GROWL_NOTIFICATION_TIMED_OUT];
	clickInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
		[userInfo objectForKey:GROWL_KEY_CLICKED_CONTEXT], GROWL_KEY_CLICKED_CONTEXT,
		nil];

	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(),
										 (CFStringRef)growlNotificationTimedOutName,
										 /*object*/ NULL,
										 /*userInfo*/ (CFDictionaryRef)clickInfo,
										 /*deliverImmediately*/ true);

	[clickInfo release];
	[growlNotificationTimedOutName release];
}

@end
