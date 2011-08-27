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
#import "GrowlNotification.h"
#import "GrowlTicketController.h"
#import "GrowlNotificationTicket.h"
#import "GrowlNotificationDatabase.h"
#import "GrowlNotificationDatabase+GHAAdditions.h"
#import "GrowlPathway.h"
#import "GrowlPathwayController.h"
#import "GrowlPropertyListFilePathway.h"
#import "GrowlPathUtilities.h"
#import "NSStringAdditions.h"
#import "GrowlDisplayPlugin.h"
#import "GrowlPluginController.h"
#import "GrowlIdleStatusController.h"
#import "GrowlDefines.h"
#import "GrowlVersionUtilities.h"
#import "GrowlMenu.h"
#import "HgRevision.h"
#import "GrowlLog.h"
#import "GrowlNotificationCenter.h"
#import "GrowlImageAdditions.h"
#import "GrowlFirstLaunchWindowController.h"
#include "CFURLAdditions.h"
#include <SystemConfiguration/SystemConfiguration.h>
#include <sys/errno.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/fcntl.h>
#include <netinet/in.h>
#include <arpa/inet.h>

//XXX Networking; move me
#import "GCDAsyncSocket.h"
#import "GrowlGNTPOutgoingPacket.h"
//#import "GrowlTCPPathway.h"
#import "GrowlNotificationGNTPPacket.h"
#import "GrowlRegisterGNTPPacket.h"
#import "GrowlGNTPPacketParser.h"
#import "GrowlGNTPPacket.h"

#import "GNTPKey.h"
#import "GrowlGNTPKeyController.h"

//Notifications posted by GrowlApplicationController
#define USER_WENT_IDLE_NOTIFICATION       @"User went idle"
#define USER_RETURNED_NOTIFICATION        @"User returned"

extern CFRunLoopRef CFRunLoopGetMain(void);

@interface GrowlApplicationController (PRIVATE)
- (void) notificationClicked:(NSNotification *)notification;
- (void) notificationTimedOut:(NSNotification *)notification;
@end

/*applications that go full-screen (games in particular) are expected to capture
 *	whatever display(s) they're using.
 *we [will] use this to notice, and turn on auto-sticky or something (perhaps
 *	to be decided by the user), when this happens.
 */
#if 0
static BOOL isAnyDisplayCaptured(void) {
	BOOL result = NO;

	CGDisplayCount numDisplays;
	CGDisplayErr err = CGGetActiveDisplayList(/*maxDisplays*/ 0U, /*activeDisplays*/ NULL, &numDisplays);
	if (err != noErr)
		[[GrowlLog sharedController] writeToLog:@"Checking for captured displays: Could not count displays: %li", (long)err];
	else {
		CGDirectDisplayID *displays = malloc(numDisplays * sizeof(CGDirectDisplayID));
		CGGetActiveDisplayList(numDisplays, displays, /*numDisplays*/ NULL);

		if (!displays)
			[[GrowlLog sharedController] writeToLog:@"Checking for captured displays: Could not allocate list of displays: %s", strerror(errno)];
		else {
			for (CGDisplayCount i = 0U; i < numDisplays; ++i) {
				if (CGDisplayIsCaptured(displays[i])) {
					result = YES;
					break;
				}
			}

			free(displays);
		}
	}

	return result;
}
#endif

static struct Version version = { 0U, 0U, 0U, releaseType_svn, 0U, };

@implementation GrowlApplicationController
@synthesize statusMenu;

+ (GrowlApplicationController *) sharedController {
	return [self sharedInstance];
}

- (id) initSingleton {
	if ((self = [super initSingleton])) {

		// initialize GrowlPreferencesController before observing GrowlPreferencesChanged
		GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];

		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

		[nc addObserver:self
				  selector:@selector(preferencesChanged:)
					  name:GrowlPreferencesChanged
					object:nil];
		[nc addObserver:self
				  selector:@selector(showPreview:)
					  name:GrowlPreview
					object:nil];
		[nc addObserver:self
				  selector:@selector(replyToPing:)
					  name:GROWL_PING
					object:nil];

		[nc addObserver:self
			   selector:@selector(notificationClicked:)
				   name:GROWL_NOTIFICATION_CLICKED
				 object:nil];
		[nc addObserver:self
			   selector:@selector(notificationTimedOut:)
				   name:GROWL_NOTIFICATION_TIMED_OUT
				 object:nil];

		ticketController = [GrowlTicketController sharedController];
		
		[self versionDictionary];

		NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"GrowlDefaults" withExtension:@"plist"];
		NSDictionary *defaultDefaults = [NSDictionary dictionaryWithContentsOfURL:fileURL];
		if (defaultDefaults) {
			[preferences registerDefaults:defaultDefaults];
		}

        //This class doesn't exist in the prefpane.
        Class pathwayControllerClass = NSClassFromString(@"GrowlPathwayController");
        if (pathwayControllerClass)
            [pathwayControllerClass sharedController];
		
		[self preferencesChanged:nil];
		
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
															   selector:@selector(applicationLaunched:)
																   name:NSWorkspaceDidLaunchApplicationNotification
																 object:nil];

		growlIcon = [[NSImage imageNamed:@"NSApplicationIcon"] retain];

		GrowlIdleStatusController_init();
				
		// create and register GrowlNotificationCenter
		growlNotificationCenter = [[GrowlNotificationCenter alloc] init];
		growlNotificationCenterConnection = [[NSConnection alloc] initWithReceivePort:[NSPort port] sendPort:nil];
		//[growlNotificationCenterConnection enableMultipleThreads];
		[growlNotificationCenterConnection setRootObject:growlNotificationCenter];
		if (![growlNotificationCenterConnection registerName:@"GrowlNotificationCenter"])
			NSLog(@"WARNING: could not register GrowlNotificationCenter for interprocess access");
         
      [[GrowlNotificationDatabase sharedInstance] setupMaintenanceTimers];
      
	}

	return self;
}

- (void) destroy {
	//free your world
	[mainThread release]; mainThread = nil;
	Class pathwayControllerClass = NSClassFromString(@"GrowlPathwayController");
	if (pathwayControllerClass)
		[(id)[pathwayControllerClass sharedController] setServerEnabled:NO];
	[destinations     release]; destinations = nil;
	[growlIcon        release]; growlIcon = nil;
	[defaultDisplayPlugin release]; defaultDisplayPlugin = nil;

	GrowlIdleStatusController_dealloc();

	CFRunLoopTimerInvalidate(updateTimer);
	CFRelease(updateTimer);

	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
	
	[growlNotificationCenterConnection invalidate];
	[growlNotificationCenterConnection release]; growlNotificationCenterConnection = nil;
	[growlNotificationCenter           release]; growlNotificationCenter = nil;
	
	[super destroy];
}

#pragma mark Guts

- (void) showPreview:(NSNotification *) note {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *displayName = [note object];
	GrowlDisplayPlugin *displayPlugin = (GrowlDisplayPlugin *)[[GrowlPluginController sharedController] displayPluginInstanceWithName:displayName author:nil version:nil type:nil];

	NSString *desc = [[NSString alloc] initWithFormat:NSLocalizedString(@"This is a preview of the %@ display", "Preview message shown when clicking Preview in the system preferences pane. %@ becomes the name of the display style being used."), displayName];
	NSNumber *priority = [[NSNumber alloc] initWithInt:0];
	NSNumber *sticky = [[NSNumber alloc] initWithBool:NO];
	NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:
		@"Growl",   GROWL_APP_NAME,
		@"Preview", GROWL_NOTIFICATION_NAME,
		NSLocalizedString(@"Preview", "Title of the Preview notification shown to demonstrate Growl displays"), GROWL_NOTIFICATION_TITLE,
		desc,       GROWL_NOTIFICATION_DESCRIPTION,
		priority,   GROWL_NOTIFICATION_PRIORITY,
		sticky,     GROWL_NOTIFICATION_STICKY,
		[growlIcon PNGRepresentation],  GROWL_NOTIFICATION_ICON_DATA,
		nil];
	[desc     release];
	[priority release];
	[sticky   release];
	GrowlNotification *notification = [[GrowlNotification alloc] initWithDictionary:info];
	[info release];
	[displayPlugin displayNotification:notification];
	[notification release];
	[pool release];
}


/* XXX This network stuff shouldn't be in GrowlApplicationController! */

/*!
 * @brief Get address data for a Growl server
 *
 * @param name The name of the server
 * @result An NSData which contains a (struct sockaddr *)'s data. This may actually be a sockaddr_in or a sockaddr_in6.
 */
- (NSData *)addressDataForGrowlServerOfType:(NSString *)type withName:(NSString *)name withDomain:(NSString*)domain
{
	if ([name hasSuffix:@".local"])
		name = [name substringWithRange:NSMakeRange(0, [name length] - [@".local" length])];

	if ([name Growl_isLikelyDomainName]) {
		CFHostRef host = CFHostCreateWithName(kCFAllocatorDefault, (CFStringRef)name);
		CFStreamError error;
		if (CFHostStartInfoResolution(host, kCFHostAddresses, &error)) {
			NSArray *addresses = (NSArray *)CFHostGetAddressing(host, NULL);
			
			if ([addresses count]) {
				/* DNS lookup success! */
                CFRelease(host);
				return [addresses objectAtIndex:0];
			}
		}
		if (host) CFRelease(host);
		
	} else if ([name Growl_isLikelyIPAddress]) {
      struct in_addr addr4;
      struct in6_addr addr6;
      
      if(inet_pton(AF_INET, [name cStringUsingEncoding:NSUTF8StringEncoding], &addr4) == 1){
         struct sockaddr_in serverAddr;
         
         memset(&serverAddr, 0, sizeof(serverAddr));
         serverAddr.sin_len = sizeof(struct sockaddr_in);
         serverAddr.sin_family = AF_INET;
         serverAddr.sin_addr.s_addr = addr4.s_addr;
         serverAddr.sin_port = htons(GROWL_TCP_PORT);
         return [NSData dataWithBytes:&serverAddr length:sizeof(serverAddr)];
      }
      else if(inet_pton(AF_INET6, [name cStringUsingEncoding:NSUTF8StringEncoding], &addr6) == 1){
         struct sockaddr_in6 serverAddr;
         
         memset(&serverAddr, 0, sizeof(serverAddr));
         serverAddr.sin6_len        = sizeof(struct sockaddr_in6);
         serverAddr.sin6_family     = AF_INET6;
         serverAddr.sin6_addr       = addr6;
         serverAddr.sin6_port       = htons(GROWL_TCP_PORT);
         return [NSData dataWithBytes:&serverAddr length:sizeof(serverAddr)];
      }else{
         NSLog(@"No address (shouldnt happen)");
         return nil;
      }
   } 
	
    NSString *machineDomain = domain;
    if(!machineDomain)
        machineDomain = @"local.";
	/* If we make it here, treat it as a computer name on the local network */ 
	NSNetService *service = [[[NSNetService alloc] initWithDomain:machineDomain type:type name:name] autorelease];
	if (!service) {
		/* No such service exists. The computer is probably offline. */
		return nil;
	}
	
	/* Work for 8 seconds to resolve the net service to an IP and port. We should be running
	 * on a thread, so blocking is fine.
	 */
	[service scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:@"PrivateGrowlMode"];
	[service resolveWithTimeout:8.0];
	CFAbsoluteTime deadline = CFAbsoluteTimeGetCurrent() + 8.0;
	CFTimeInterval remaining;
	while ((remaining = (deadline - CFAbsoluteTimeGetCurrent())) > 0 && [[service addresses] count] == 0) {
		CFRunLoopRunInMode((CFStringRef)@"PrivateGrowlMode", remaining, true);
	}
	[service stop];
	
	NSArray *addresses = [service addresses];
	if (![addresses count]) {
		/* Lookup failed */
		return nil;
	}
	
	return [addresses objectAtIndex:0];
}	

/*
 This will be called whenever AsyncSocket is about to disconnect. In Echo Server,
 it does not do anything other than report what went wrong (this delegate method
 is the only place to get that information), but in a more serious app, this is
 a good place to do disaster-recovery by getting partially-read data. This is
 not, however, a good place to do cleanup. The socket must still exist when this
 method returns.
 */
-(void) onSocket:(GCDAsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
	if (err != nil)
		NSLog (@"Socket %@ will disconnect. Error domain %@, code %d (%@).",
			   sock,
			   [err domain], (int)[err code], [err localizedDescription]);
	else
		NSLog (@"Socket will disconnect. No error.");
	
	NSLog(@"Releasing %@", sock);
	[sock release];
}

- (void)onSocket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
	NSLog(@"Connected to %@ on %@:%hu", sock, host, port);
}

- (void)mainThread_sendViaTCP:(NSDictionary *)sendingDetails
{
	
	[[GrowlGNTPPacketParser sharedParser] sendPacket:[sendingDetails objectForKey:@"Packet"]
										   toAddress:[sendingDetails objectForKey:@"Destination"]];
}

// Need run loop to run
// Need to retain AsyncSocket until its work is complete
- (void)sendViaTCP:(GrowlGNTPOutgoingPacket *)packet
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//	NSNumber *requestTimeout = [defaults objectForKey:@"ForwardingRequestTimeout"];
//	NSNumber *replyTimeout = [defaults objectForKey:@"ForwardingReplyTimeout"];

	for(NSDictionary *entry in destinations) {
		if ([[entry objectForKey:@"use"] boolValue]) {
			//NSLog(@"Looking up address for %@", [entry objectForKey:@"computer"]);
			NSData *destAddress = [self addressDataForGrowlServerOfType:@"_gntp._tcp." withName:[entry objectForKey:@"computer"] withDomain:[entry objectForKey:@"domain"]];
			if (!destAddress) {
				/* No destination address. Nothing to see here; move along. */
				NSLog(@"Could not obtain destination address for %@", [entry objectForKey:@"computer"]);
				continue;
			}
			GNTPKey *key = [[GrowlGNTPKeyController sharedInstance] keyForUUID:[entry objectForKey:@"uuid"]];
			[packet setKey:key];
			//NSMutableData *result = [NSMutableData data];
			//for(id item in [packet outgoingItems])
			//	[result appendData:[item GNTPRepresentation]];
			//NSLog(@"Sending %@", HexUnencode(HexEncode(result)));
			[self performSelectorOnMainThread:@selector(mainThread_sendViaTCP:)
								   withObject:[NSDictionary dictionaryWithObjectsAndKeys:
											   destAddress, @"Destination",
											   packet, @"Packet",
											   nil]
								waitUntilDone:NO];
		} else {
			//NSLog(@"6  destination %@", entry);
		}
	}

	[pool release];	
}

- (void) forwardNotification:(NSDictionary *)dict
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	GrowlGNTPOutgoingPacket *outgoingPacket = [GrowlGNTPOutgoingPacket outgoingPacketOfType:GrowlGNTPOutgoingPacket_NotifyType
																					forDict:dict];
	[self sendViaTCP:outgoingPacket];
   
	[pool release];
}
	
- (void) forwardRegistration:(NSDictionary *)dict
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	GrowlGNTPOutgoingPacket *outgoingPacket = [GrowlGNTPOutgoingPacket outgoingPacketOfType:GrowlGNTPOutgoingPacket_RegisterType
																					forDict:dict];
	[self sendViaTCP:outgoingPacket];

	[pool release];
}
	
#pragma mark Retrieving sounds

- (OSStatus) getFSRef:(out FSRef *)outRef forSoundNamed:(NSString *)soundName {
	BOOL foundIt = NO;

	NSArray *soundTypes = [NSSound soundUnfilteredTypes];

	//Throw away all the HFS types, leaving only filename extensions.
	NSPredicate *noHFSTypesPredicate = [NSPredicate predicateWithFormat:@"NOT (self BEGINSWITH \"'\")"];
	soundTypes = [soundTypes filteredArrayUsingPredicate:noHFSTypesPredicate];

	//If there are no types left, abort.
	if ([soundTypes count] == 0U)
		return unknownFormatErr;

	//We only want the filename extensions, not the HFS types.
	//Also, we want the longest one last so that we can use lastObject's length to allocate the buffer.
	NSSortDescriptor *sortDesc = [[[NSSortDescriptor alloc] initWithKey:@"length" ascending:YES] autorelease];
	NSArray *sortDescs = [NSArray arrayWithObject:sortDesc];
	soundTypes = [soundTypes sortedArrayUsingDescriptors:sortDescs];

	NSMutableArray *filenames = [NSMutableArray arrayWithCapacity:[soundTypes count]];
	for (NSString *soundType in soundTypes) {
		[filenames addObject:[soundName stringByAppendingPathExtension:soundType]];
	}

	//The additions are for appending '.' plus the longest filename extension.
	size_t filenameLen = [soundName length] + 1U + [[soundTypes lastObject] length];
	unichar *filenameBuf = malloc(filenameLen * sizeof(unichar));
	if (!filenameBuf) return memFullErr;

	FSRef folderRef;
	OSStatus err;

	err = FSFindFolder(kUserDomain, kSystemSoundsFolderType, kDontCreateFolder, &folderRef);
	if (err == noErr) {
		//Folder exists. If it didn't, FSFindFolder would have returned fnfErr.
		for (NSString *filename in filenames) {
			[filename getCharacters:filenameBuf];
			err = FSMakeFSRefUnicode(&folderRef, [filename length], filenameBuf, kTextEncodingUnknown, outRef);
			if (err == noErr) {
				foundIt = YES;
				break;
			}
		}
	}

	if (!foundIt) {
		err = FSFindFolder(kLocalDomain, kSystemSoundsFolderType, kDontCreateFolder, &folderRef);
		if (err == noErr) {
			//Folder exists. If it didn't, FSFindFolder would have returned fnfErr.
			for (NSString *filename in filenames) {
				[filename getCharacters:filenameBuf];
				err = FSMakeFSRefUnicode(&folderRef, [filename length], filenameBuf, kTextEncodingUnknown, outRef);
				if (err == noErr) {
					foundIt = YES;
					break;
				}
			}
		}
	}

	if (!foundIt) {
		err = FSFindFolder(kSystemDomain, kSystemSoundsFolderType, kDontCreateFolder, &folderRef);
		if (err == noErr) {
			//Folder exists. If it didn't, FSFindFolder would have returned fnfErr.
			for (NSString *filename in filenames) {
				[filename getCharacters:filenameBuf];
				err = FSMakeFSRefUnicode(&folderRef, [filename length], filenameBuf, kTextEncodingUnknown, outRef);
				if (err == noErr) {
					break;
				}
			}
		}
	}

	free(filenameBuf);

	return err;
}

#pragma mark Dispatching notifications

- (GrowlNotificationResult) dispatchNotificationWithDictionary:(NSDictionary *) dict {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[[GrowlLog sharedController] writeNotificationDictionaryToLog:dict];

	// Make sure this notification is actually registered
	NSString *appName = [dict objectForKey:GROWL_APP_NAME];
    NSString *hostName = [dict objectForKey:GROWL_NOTIFICATION_GNTP_SENT_BY];
	GrowlApplicationTicket *ticket = [ticketController ticketForApplicationName:appName hostName:hostName];
	NSString *notificationName = [dict objectForKey:GROWL_NOTIFICATION_NAME];
	NSLog(@"Dispatching notification from %@: %@", appName, notificationName);
	if (!ticket) {
		[pool release];
		NSLog(@"Never heard of this app!");
		return GrowlNotificationResultNotRegistered;
	}

	if (![ticket isNotificationAllowed:notificationName]) {
		// Either the app isn't registered or the notification is turned off
		// We should do nothing
		[pool release];
		NSLog(@"The user disabled this notification!");
		return GrowlNotificationResultDisabled;
	}

	NSMutableDictionary *aDict = [dict mutableCopy];

	// Check icon
	Class NSImageClass = [NSImage class];
	Class NSDataClass  = [NSData  class];
	NSData *iconData = nil;
	id sourceIconData = [aDict objectForKey:GROWL_NOTIFICATION_ICON_DATA];
	if (sourceIconData) {
		if ([sourceIconData isKindOfClass:NSImageClass])
			iconData = [(NSImage *)sourceIconData PNGRepresentation];
		else if ([sourceIconData isKindOfClass:NSDataClass])
			iconData = sourceIconData;
	}
	if (!iconData)
		iconData = [ticket iconData];

	if (iconData)
		[aDict setObject:iconData forKey:GROWL_NOTIFICATION_ICON_DATA];

	// If app icon present, convert to NSImage
	iconData = nil;
	sourceIconData = [aDict objectForKey:GROWL_NOTIFICATION_APP_ICON_DATA];
	if (sourceIconData) {
		if ([sourceIconData isKindOfClass:NSImageClass])
			iconData = [(NSImage *)sourceIconData PNGRepresentation];
		else if ([sourceIconData isKindOfClass:NSDataClass])
			iconData = sourceIconData;
	}
	if (iconData)
		[aDict setObject:iconData forKey:GROWL_NOTIFICATION_APP_ICON_DATA];

	// To avoid potential exceptions, make sure we have both text and title
	if (![aDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION])
		[aDict setObject:@"" forKey:GROWL_NOTIFICATION_DESCRIPTION];
	if (![aDict objectForKey:GROWL_NOTIFICATION_TITLE])
		[aDict setObject:@"" forKey:GROWL_NOTIFICATION_TITLE];

	//Retrieve and set the the priority of the notification
	GrowlNotificationTicket *notification = [ticket notificationTicketForName:notificationName];
	int priority = [notification priority];
	NSNumber *value;
	if (priority == GrowlPriorityUnset) {
		value = [dict objectForKey:GROWL_NOTIFICATION_PRIORITY];
		if (!value)
			value = [NSNumber numberWithInt:0];
	} else
		value = [NSNumber numberWithInt:priority];
	[aDict setObject:value forKey:GROWL_NOTIFICATION_PRIORITY];

	GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];

	// Retrieve and set the sticky bit of the notification
	int sticky = [notification sticky];
	if (sticky >= 0)
		[aDict setObject:[NSNumber numberWithBool:sticky] forKey:GROWL_NOTIFICATION_STICKY];

	BOOL saveScreenshot = [[NSUserDefaults standardUserDefaults] boolForKey:GROWL_SCREENSHOT_MODE];
   [aDict setObject:[NSNumber numberWithBool:saveScreenshot] forKey:GROWL_SCREENSHOT_MODE];
   [aDict setObject:[NSNumber numberWithBool:[ticket clickHandlersEnabled]] forKey:GROWL_CLICK_HANDLER_ENABLED];

	/* Set a unique ID which we can use globally to identify this particular notification if it doesn't have one */
	if (![aDict objectForKey:GROWL_NOTIFICATION_INTERNAL_ID]) {
		CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
		NSString *uuid = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
		[aDict setValue:uuid
				 forKey:GROWL_NOTIFICATION_INTERNAL_ID];
		[uuid release];
		CFRelease(uuidRef);
	}
   
   GrowlNotification *appNotification = [[GrowlNotification alloc] initWithDictionary:aDict];

   [[GrowlNotificationDatabase sharedInstance] logNotificationWithDictionary:aDict];
   
   if([preferences isForwardingEnabled])
      [self performSelectorInBackground:@selector(forwardNotification:) withObject:[[dict copy] autorelease]];
   
    if(![preferences squelchMode])
    {
        GrowlDisplayPlugin *display = [notification displayPlugin];
        
        if (!display)
            display = [ticket displayPlugin];
        
        if (!display) {
            if (!defaultDisplayPlugin) {
                NSString *displayPluginName = [[GrowlPreferencesController sharedController] defaultDisplayPluginName];
                defaultDisplayPlugin = [(GrowlDisplayPlugin *)[[GrowlPluginController sharedController] displayPluginInstanceWithName:displayPluginName author:nil version:nil type:nil] retain];
                if (!defaultDisplayPlugin) {
                    //User's selected default display has gone AWOL. Change to the default default.
                    NSString *file = [[NSBundle mainBundle] pathForResource:@"GrowlDefaults" ofType:@"plist"];
                    NSURL *fileURL = [NSURL fileURLWithPath:file];
                   NSDictionary *defaultDefaults = [NSDictionary dictionaryWithContentsOfURL:fileURL];
                    if (defaultDefaults) {
                        displayPluginName = [defaultDefaults objectForKey:GrowlDisplayPluginKey];
                        if (!displayPluginName)
                            GrowlLog_log(@"No default display specified in default preferences! Perhaps your Growl installation is corrupted?");
                        else {
                            defaultDisplayPlugin = (GrowlDisplayPlugin *)[[[GrowlPluginController sharedController] displayPluginDictionaryWithName:displayPluginName author:nil version:nil type:nil] pluginInstance];
                            
                            //Now fix the user's preferences to forget about the missing display plug-in.
                            [preferences setObject:displayPluginName forKey:GrowlDisplayPluginKey];
                        }
                        
                        [defaultDefaults release];
                    }
                }
            }
            display = defaultDisplayPlugin;
        }
        
        [display displayNotification:appNotification];
    }
    
    NSString *soundName = [notification sound];
    if (soundName) {
        NSError *error = nil;
        NSDictionary *userInfo;
        
        FSRef soundRef;
        OSStatus err = [self getFSRef:&soundRef forSoundNamed:soundName];
        if (err == noErr) {
        } else {
            userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                        [NSString stringWithFormat:NSLocalizedString(@"Could not find sound file named \"%@\": %s", /*comment*/ nil), soundName, GetMacOSStatusCommentString(err)], NSLocalizedDescriptionKey,
                        nil];
        }
        
        if (err != noErr) {
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:userInfo];
            [NSApp presentError:error];
        }
	}
   
   [appNotification release];
   
	// send to DO observers
	[growlNotificationCenter notifyObservers:aDict];

	[aDict release];
	[pool release];
	
	NSLog(@"Notification successful");
	return GrowlNotificationResultPosted;
}

- (BOOL) registerApplicationWithDictionary:(NSDictionary *)userInfo {
	[[GrowlLog sharedController] writeRegistrationDictionaryToLog:userInfo];

	NSString *appName = [userInfo objectForKey:GROWL_APP_NAME];
	NSLog(@"Registering application with name %@", appName);
   NSString *hostName = [userInfo objectForKey:GROWL_NOTIFICATION_GNTP_SENT_BY];
	GrowlApplicationTicket *newApp = [ticketController ticketForApplicationName:appName hostName:hostName];

	if (newApp) {
		[newApp reregisterWithDictionary:userInfo];
	} else {
		newApp = [[[GrowlApplicationTicket alloc] initWithDictionary:userInfo] autorelease];
	}

	BOOL success = YES;

	if (appName && newApp) {
		if ([newApp hasChanged])
			[newApp saveTicket];
		[ticketController addTicket:newApp];

	} else { //!(appName && newApp)
		NSString *filename = [(appName ? appName : @"unknown-application") stringByAppendingPathExtension:GROWL_REG_DICT_EXTENSION];

		//We'll be writing the file to ~/Library/Logs/Failed Growl registrations.
		NSFileManager *mgr = [NSFileManager defaultManager];
		NSString *userLibraryFolder = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, /*expandTilde*/ YES) lastObject];
		NSString *logsFolder = [userLibraryFolder stringByAppendingPathComponent:@"Logs"];
		[mgr createDirectoryAtPath:logsFolder withIntermediateDirectories:YES attributes:nil error:nil];
		NSString *failedTicketsFolder = [logsFolder stringByAppendingPathComponent:@"Failed Growl registrations"];
		[mgr createDirectoryAtPath:failedTicketsFolder withIntermediateDirectories:YES attributes:nil error:nil];
		NSString *path = [failedTicketsFolder stringByAppendingPathComponent:filename];

		//NSFileHandle will not create the file for us, so we must create it separately.
		[mgr createFileAtPath:path contents:nil attributes:nil];

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
   
   if([[GrowlPreferencesController sharedController] isForwardingEnabled])
      [self performSelectorInBackground:@selector(forwardRegistration:) withObject:[[userInfo copy] autorelease]];

	NSLog(@"Registration %@", success ? @"succeeded!" : @"FAILED");
   
	return success;
}

#pragma mark Version of Growl

+ (NSString *) growlVersion {
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
}

- (NSDictionary *) versionDictionary {
	if (!versionInfo) {
		NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];

		// Due to the way NSAssert1 works, this will generate an unused variable
		// warning if we compile in release mode.  With -Wall -Werror on, this is
		// Bad Juju.  So we need to use gcc compiler attributes to cancel the error.
		BOOL parseSucceeded __attribute__((unused)) = parseVersionString(versionString, &version);
		NSAssert1(parseSucceeded, @"Could not parse version string: %@", versionString);
		
		if (version.releaseType == releaseType_svn)
			version.development = (u_int32_t)HG_REVISION;

		NSNumber *major = [[NSNumber alloc] initWithUnsignedShort:version.major];
		NSNumber *minor = [[NSNumber alloc] initWithUnsignedShort:version.minor];
		NSNumber *incremental = [[NSNumber alloc] initWithUnsignedChar:version.incremental];
		NSNumber *releaseType = [[NSNumber alloc] initWithUnsignedChar:version.releaseType];
		NSNumber *development = [[NSNumber alloc] initWithUnsignedShort:version.development];

		versionInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
			[GrowlApplicationController growlVersion], (NSString *)kCFBundleVersionKey,

			major,                                     @"Major version",
			minor,                                     @"Minor version",
			incremental,                               @"Incremental version",
			releaseTypeNames[version.releaseType],     @"Release type name",
			releaseType,                               @"Release type",
			development,                               @"Development version",

			nil];

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
	if (!d)
		d = [self versionDictionary];

	//0.6
	NSMutableString *result = [NSMutableString stringWithFormat:@"%@.%@",
		[d objectForKey:@"Major version"],
		[d objectForKey:@"Minor version"]];

	//the .1 in 0.6.1
	NSNumber *incremental = [d objectForKey:@"Incremental version"];
	if ([incremental unsignedShortValue])
		[result appendFormat:@".%@", incremental];

	NSString *releaseTypeName = [d objectForKey:@"Release type name"];
	if ([releaseTypeName length]) {
		//"" (release), "b4", " SVN 900"
		[result appendFormat:@"%@%@", releaseTypeName, [d objectForKey:@"Development version"]];
	}

	return result;
}

#pragma mark Accessors

- (BOOL) quitAfterOpen {
	return quitAfterOpen;
}
- (void) setQuitAfterOpen:(BOOL)flag {
	quitAfterOpen = flag;
}

#pragma mark What NSThread should implement as a class method

- (NSThread *)mainThread {
	return mainThread;
}

#pragma mark Notifications (not the Growl kind)

- (void) preferencesChanged:(NSNotification *) note {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	//[note object] is the changed key. A nil key means reload our tickets.
	id object = [note object];

	if (!quitAfterOpen) {
		if (!note || (object && [object isEqual:GrowlStartServerKey])) {
			Class pathwayControllerClass = NSClassFromString(@"GrowlPathwayController");
			if (pathwayControllerClass)
				[(id)[pathwayControllerClass sharedController] setServerEnabledFromPreferences];
		}
	}
	if (!note || (object && [object isEqual:GrowlStickyIdleThresholdKey]))
		GrowlIdleStatusController_setThreshold([[[GrowlPreferencesController sharedController] idleThreshold] intValue]);
	if (!note || (object && [object isEqual:GrowlUserDefaultsKey]))
		[[GrowlPreferencesController sharedController] synchronize];
	if (!note || (object && [object isEqual:GrowlEnabledKey]))
		growlIsEnabled = [[GrowlPreferencesController sharedController] boolForKey:GrowlEnabledKey];
	if (!note || (object && [object isEqual:GrowlEnableForwardKey]))
		enableForward = [[GrowlPreferencesController sharedController] isForwardingEnabled];
	if (!note || (object && [object isEqual:GrowlForwardDestinationsKey])) {
		NSMutableArray *oldList = [[destinations mutableCopyWithZone:nil] autorelease];
		NSArray *newList = [[GrowlPreferencesController sharedController] objectForKey:GrowlForwardDestinationsKey];
		NSMutableArray *mutableDestinations = [[newList mutableCopy] autorelease];         

		NSUInteger idx = 0UL;
		for(NSDictionary *dict in newList)
		{
			GNTPKey *key = nil;

			OSStatus status;
			const char *growlOutgoing = [@"GrowlOutgoingNetworkConnection" UTF8String];
			const char *uuidChars = NULL;

			NSString *uuid = [dict objectForKey:@"uuid"];
			NSString *password = nil;
			if (!uuid) {
				//Stored destination that does not have a UUID: Migrate it to UUID-based storage.
				CFUUIDRef cfUUID = CFUUIDCreate(kCFAllocatorDefault);
				if (cfUUID) {
					uuid = [NSMakeCollectable(CFUUIDCreateString(kCFAllocatorDefault, cfUUID)) autorelease];
					CFRelease(cfUUID);
				}

				NSMutableDictionary *amendedDict = [[dict mutableCopy] autorelease];
				[amendedDict setObject:uuid forKey:@"uuid"];

				password = [dict objectForKey:@"password"];
				if (password) {
					if (uuid) {
						uuidChars = [uuid UTF8String];

						status = SecKeychainAddGenericPassword(NULL,
							(UInt32)strlen(growlOutgoing), growlOutgoing,
							(UInt32)strlen(uuidChars), uuidChars,
							(UInt32)[password length], [password UTF8String],
							NULL);
						if (status == noErr) {
							[amendedDict removeObjectForKey:@"password"];
						} else {
							NSLog(@"Failed to store password for %@ with UUID %@ in keychain. Error: %d", [dict objectForKey:@"computer"], uuid, (int)status);
						}
					}
				}

				[mutableDestinations replaceObjectAtIndex:idx withObject:amendedDict];
			}
			else
			{
				unsigned char *passwordChars;
				UInt32 passwordLength;
				uuidChars = [uuid UTF8String];
				status = SecKeychainFindGenericPassword(NULL,
					(UInt32)strlen(growlOutgoing), growlOutgoing,
					(UInt32)strlen(uuidChars), uuidChars,
					&passwordLength, (void **)&passwordChars, NULL);		
				if (status == noErr) {
					password = [[[NSString alloc] initWithBytes:passwordChars
						length:passwordLength
						encoding:NSUTF8StringEncoding] autorelease];
					SecKeychainItemFreeContent(NULL, passwordChars);
				} else {
					if (status != errSecItemNotFound)
						NSLog(@"Failed to retrieve password for %@ with UUID %@ from keychain. Error: %d", [dict objectForKey:@"computer"], uuid, (int)status);
					password = nil;
				}
			}

			if (!password)
				key = [[[GNTPKey alloc] initWithPassword:@"" hashAlgorithm:GNTPNoHash encryptionAlgorithm:GNTPNone] autorelease];
			else
				key = [[[GNTPKey alloc] initWithPassword:password hashAlgorithm:GNTPSHA512 encryptionAlgorithm:GNTPNone] autorelease];
			[[GrowlGNTPKeyController sharedInstance] setKey:key forUUID:uuid];

			[oldList removeObject:dict];
			++idx;
		}

		if([oldList count] > 0) {
			for(NSDictionary *dict in oldList)
				[[GrowlGNTPKeyController sharedInstance] removeKeyForUUID:[dict objectForKey:@"uuid"]];
		}

		[destinations release];
		destinations = [mutableDestinations retain];
   }
	if (!note || !object)
		[ticketController loadAllSavedTickets];
	if (!note || (object && [object isEqual:GrowlDisplayPluginKey]))
		// force reload
		[defaultDisplayPlugin release];
		defaultDisplayPlugin = nil;
	if (object) {
		if ([object isEqual:@"GrowlTicketDeleted"]) {
			NSString *ticketName = [[note userInfo] objectForKey:@"TicketName"];
			[ticketController removeTicketForApplicationName:ticketName];
		} else if ([object isEqual:@"GrowlTicketChanged"]) {
			NSString *ticketName = [[note userInfo] objectForKey:@"TicketName"];
			GrowlApplicationTicket *newTicket = [[GrowlApplicationTicket alloc] initTicketForApplication:ticketName];
			if (newTicket) {
				[ticketController addTicket:newTicket];
				[newTicket release];
			}
		} else if ((!quitAfterOpen) && [object isEqual:GrowlUDPPortKey]) {
			Class pathwayControllerClass = NSClassFromString(@"GrowlPathwayController");
			if (pathwayControllerClass) {
				id pathwayController = [pathwayControllerClass sharedController];
				[pathwayController setServerEnabled:NO];
				[pathwayController setServerEnabled:YES];
			}
		}
	}
	
	[pool release];
}

- (void) replyToPing:(NSNotification *) note {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_PONG
	                                                               object:nil
	                                                             userInfo:nil
	                                                   deliverImmediately:NO];
	
	[pool release];
}

- (void)firstLaunchClosed
{
    if(firstLaunchWindow){
        [firstLaunchWindow release];
        firstLaunchWindow = nil;
    }
}

#pragma mark NSApplication Delegate Methods

- (BOOL) application:(NSApplication *)theApplication openFile:(NSString *)filename {
	BOOL retVal = NO;
	NSString *pathExtension = [filename pathExtension];

	if ([pathExtension isEqualToString:GROWL_REG_DICT_EXTENSION]) {
		//If the auto-quit flag is set, it's probably because we are not the real GHAÑwe're some other GHA that a broken (pre-1.1.3) GAB opened this file with. If that's the case, find the real one and open the file with it.
		BOOL registerItOurselves = YES;
		NSString *realHelperAppBundlePath = nil;

		if (quitAfterOpen) {
			//But, just to make sure we don't infinitely loop, make sure this isn't our own bundle.
			NSString *ourBundlePath = [[NSBundle mainBundle] bundlePath];
			realHelperAppBundlePath = [[GrowlPathUtilities runningHelperAppBundle] bundlePath];
			if (![ourBundlePath isEqualToString:realHelperAppBundlePath])
				registerItOurselves = NO;
		}

		if (registerItOurselves) {
			//We are the real GHA.
			//Have the property-list-file pathway process this registration dictionary file.
			GrowlPropertyListFilePathway *pathway = [GrowlPropertyListFilePathway standardPathway];
			[pathway application:theApplication openFile:filename];
		} else {
			//We're definitely not the real GHA, so pass it to the real GHA to be registered.
			[[NSWorkspace sharedWorkspace] openFile:filename
									withApplication:realHelperAppBundlePath];
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
	if (!growlIsEnabled && !growlFinishedLaunching) {
		//Terminate after one second to give us time to process any other openFile: messages.
		[NSObject cancelPreviousPerformRequestsWithTarget:NSApp
												 selector:@selector(terminate:)
												   object:nil];
		[NSApp performSelector:@selector(terminate:)
					withObject:nil
					afterDelay:1.0];
	}

	return retVal;
}

- (void) applicationWillFinishLaunching:(NSNotification *)aNotification {
	mainThread = [[NSThread currentThread] retain];

	BOOL printVersionAndExit = [[NSUserDefaults standardUserDefaults] boolForKey:@"PrintVersionAndExit"];
	if (printVersionAndExit) {
		printf("This is GrowlHelperApp version %s.\n"
			   "PrintVersionAndExit was set to %hhi, so GrowlHelperApp will now exit.\n",
			   [[self stringWithVersionDictionary:nil] UTF8String],
			   printVersionAndExit);
		[NSApp terminate:nil];
	}

	NSFileManager *fs = [NSFileManager defaultManager];

	NSString *destDir, *subDir;
	NSArray *searchPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, /*expandTilde*/ YES);

	destDir = [searchPath objectAtIndex:0U]; //first == last == ~/Library
	destDir = [destDir stringByAppendingPathComponent:@"Application Support"];
	destDir = [destDir stringByAppendingPathComponent:@"Growl"];

	subDir  = [destDir stringByAppendingPathComponent:@"Tickets"];
	[fs createDirectoryAtPath:subDir withIntermediateDirectories:YES attributes:nil error:nil];
	subDir  = [destDir stringByAppendingPathComponent:@"Plugins"];
	[fs createDirectoryAtPath:subDir withIntermediateDirectories:YES attributes:nil error:nil];
}

//Post a notification when we are done launching so the application bridge can inform participating applications
- (void) applicationDidFinishLaunching:(NSNotification *)aNotification {
    //NSNumber *firstLaunchNum = [[GrowlPreferencesController sharedController] objectForKey:GrowlFirstLaunch];
    if(/*[GrowlFirstLaunchWindowController shouldRunFirstLaunch]*/ YES){
        [[GrowlPreferencesController sharedController] setBool:NO forKey:GrowlFirstLaunch];
        firstLaunchWindow = [[GrowlFirstLaunchWindowController alloc] init];
        [firstLaunchWindow showWindow:self];
    }
    
    self.statusMenu = [[[GrowlMenu alloc] init] autorelease];
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_IS_READY
	                                                               object:nil
	                                                             userInfo:nil
	                                                   deliverImmediately:YES];
	growlFinishedLaunching = YES;

	if (quitAfterOpen) {
		//We provide a delay of 1 second to give NSApp time to send us application:openFile: messages for any .growlRegDict files the GrowlPropertyListFilePathway needs to process.
		[NSApp performSelector:@selector(terminate:)
					withObject:nil
					afterDelay:1.0];
	}
}

//Same as applicationDidFinishLaunching, called when we are asked to reopen (that is, we are already running)
//We return yes, so we can handle activating the right window.
- (BOOL) applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
    return YES;
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
	return NO;
}

- (void) applicationWillTerminate:(NSNotification *)notification {
	[GrowlAbstractSingletonObject destroyAllSingletons];	//Release all our controllers
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication {
    [NSApp activateIgnoringOtherApps:YES];
    //if our history window isn't up, bring up preferences
    if(![[[[GrowlNotificationDatabase sharedInstance] historyWindow] window] isVisible])
        [[self statusMenu] openGrowlPreferences:self];
    return YES;
}

#pragma mark Auto-discovery

//called by NSWorkspace when an application launches.
- (void) applicationLaunched:(NSNotification *)notification {
	NSDictionary *userInfo = [notification userInfo];

	if (!userInfo)
		return;

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *appPath = [userInfo objectForKey:@"NSApplicationPath"];

	if (appPath) {
		NSString *ticketPath = [NSBundle pathForResource:@"Growl Registration Ticket" ofType:GROWL_REG_DICT_EXTENSION inDirectory:appPath];
		if (ticketPath) {
			NSURL *ticketURL = [NSURL fileURLWithPath:ticketPath];
			NSMutableDictionary *ticket = [NSDictionary dictionaryWithContentsOfURL:ticketURL];

			if (ticket) {
				NSString *appName = [userInfo objectForKey:@"NSApplicationName"];

				//set the app's name in the dictionary, if it's not present already.
				if (![ticket objectForKey:GROWL_APP_NAME])
					[ticket setObject:appName forKey:GROWL_APP_NAME];

				if ([GrowlApplicationTicket isValidTicketDictionary:ticket]) {
					NSLog(@"Auto-discovered registration ticket in %@ (located at %@)", appName, appPath);

					/* set the app's location in the dictionary, avoiding costly
					 *	lookups later.
					 */
					NSURL *url = [[NSURL alloc] initFileURLWithPath:appPath];
					NSDictionary *file_data = dockDescriptionWithURL(url);
					id location = file_data ? [NSDictionary dictionaryWithObject:file_data forKey:@"file-data"] : appPath;
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
					CFURLRef myURL = (CFURLRef)[[NSBundle mainBundle] bundleURL];
					NSArray *URLsToOpen = [NSArray arrayWithObject:[NSURL fileURLWithPath:ticketPath]];
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
					NSNumber *versionNum = [ticket objectForKey:GROWL_TICKET_VERSION];
					if (versionNum)
						NSLog(@"%@ (located at %@) contains a ticket whose format version (%i) is unrecognised by this version (%@) of Growl", appName, appPath, [versionNum intValue], [self stringWithVersionDictionary:nil]);
					else
						NSLog(@"%@ (located at %@) contains a ticket with no format version number; Growl requires that a registration dictionary include a format version number, so that Growl knows whether it will understand the dictionary's format. This ticket will be ignored.", appName, appPath);
				}
			}
		}
	}

	[pool release];
}

#pragma mark Growl Application Bridge delegate

/*click feedback comes here first. GAB picks up the DN and calls our
 *	-growlNotificationWasClicked:/-growlNotificationTimedOut: with it if it's a
 *	GHA notification.
 */
- (void)growlNotificationDict:(NSDictionary *)growlNotificationDict didCloseViaNotificationClick:(BOOL)viaClick onLocalMachine:(BOOL)wasLocal
{
	static BOOL isClosingFromRemoteClick = NO;
	/* Don't post a second close notification on the local machine if we close a notification from this method in
	 * response to a click on a remote machine.
	 */
	if (isClosingFromRemoteClick)
		return;
	
	id clickContext = [growlNotificationDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
	if (clickContext) {
		NSString *suffix, *growlNotificationClickedName;
		NSDictionary *clickInfo;
		
		NSString *appName = [growlNotificationDict objectForKey:GROWL_APP_NAME];
      NSString *hostName = [growlNotificationDict objectForKey:GROWL_NOTIFICATION_GNTP_SENT_BY];
		GrowlApplicationTicket *ticket = [ticketController ticketForApplicationName:appName hostName:hostName];
		
		if (viaClick && [ticket clickHandlersEnabled]) {
			suffix = GROWL_DISTRIBUTED_NOTIFICATION_CLICKED_SUFFIX;
		} else {
			/*
			 * send GROWL_NOTIFICATION_TIMED_OUT instead, so that an application is
			 * guaranteed to receive feedback for every notification.
			 */
			suffix = GROWL_DISTRIBUTED_NOTIFICATION_TIMED_OUT_SUFFIX;
		}
		
		//Build the application-specific notification name
		NSNumber *pid = [growlNotificationDict objectForKey:GROWL_APP_PID];
		if (pid)
			growlNotificationClickedName = [[NSString alloc] initWithFormat:@"%@-%@-%@",
											appName, pid, suffix];
		else
			growlNotificationClickedName = [[NSString alloc] initWithFormat:@"%@%@",
											appName, suffix];
		clickInfo = [NSDictionary dictionaryWithObject:clickContext
												forKey:GROWL_KEY_CLICKED_CONTEXT];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:growlNotificationClickedName
																	   object:nil
																	 userInfo:clickInfo
														   deliverImmediately:YES];
		[growlNotificationClickedName release];
	}
	
	if (!wasLocal) {
		isClosingFromRemoteClick = YES;
		[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_CLOSE_NOTIFICATION
															object:[growlNotificationDict objectForKey:GROWL_NOTIFICATION_INTERNAL_ID]];
		isClosingFromRemoteClick = NO;
	}
}

@end

#pragma mark -

@implementation GrowlApplicationController (PRIVATE)

#pragma mark Click feedback from displays

- (void) notificationClicked:(NSNotification *)notification {
	GrowlNotification *growlNotification = [notification object];
		
	[self growlNotificationDict:[growlNotification dictionaryRepresentation] didCloseViaNotificationClick:YES onLocalMachine:YES];
}

- (void) notificationTimedOut:(NSNotification *)notification {
	GrowlNotification *growlNotification = [notification object];
	
	[self growlNotificationDict:[growlNotification dictionaryRepresentation] didCloseViaNotificationClick:NO onLocalMachine:YES];
}

@end
