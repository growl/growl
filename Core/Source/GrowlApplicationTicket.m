//
//  GrowlApplicationTicket.m
//  Growl
//
//  Created by Karl Adam on Tue Apr 27 2004.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details


#import "GrowlApplicationTicket.h"
#import "GrowlNotificationTicket.h"
#import "GrowlDefines.h"
#import "GrowlDisplayPlugin.h"
#import "NSStringAdditions.h"
#import "NSWorkspaceAdditions.h"
#import "GrowlPathUtilities.h"
#import "GrowlImageAdditions.h"
#include "CFURLAdditions.h"

#define UseDefaultsKey			@"useDefaults"
#define TicketEnabledKey		@"ticketEnabled"
#define ClickHandlersEnabledKey	@"clickHandlersEnabled"
#define PositionTypeKey			@"positionType"

#pragma mark -

@implementation GrowlApplicationTicket
@synthesize appNameHostName;
@synthesize isLocalHost;

@synthesize hasChanged = changed;
@synthesize useDefaults;
@synthesize selectedPosition = selectedCustomPosition;
@synthesize positionType;
@synthesize clickHandlersEnabled;
@synthesize ticketEnabled;
@synthesize displayPluginName;

//these are specifically for auto-discovery tickets, hence the requirement of GROWL_TICKET_VERSION.
+ (BOOL) isValidTicketDictionary:(NSDictionary *)dict {
	if (!dict)
		return NO;

	NSNumber *versionNum = [dict objectForKey:GROWL_TICKET_VERSION];
	if ([versionNum intValue] == 1) {
		return [dict objectForKey:GROWL_NOTIFICATIONS_ALL]
			&& [dict objectForKey:GROWL_APP_NAME];
	} else {
		return NO;
	}
}

+ (BOOL) isKnownTicketVersion:(NSDictionary *)dict {
	id version = [dict objectForKey:GROWL_TICKET_VERSION];
	return version && ([version intValue] == 1);
}

#pragma mark -

+ (id) ticketWithDictionary:(NSDictionary *)ticketDict {
	return [[[GrowlApplicationTicket alloc] initWithDictionary:ticketDict] autorelease];
}

- (id) initWithDictionary:(NSDictionary *)ticketDict {
	if (!ticketDict) {
		[self release];
		NSParameterAssert(ticketDict != nil);
		return nil;
	}
	if ((self = [self init])) {
		synchronizeOnChanges = NO;

		appName = [[ticketDict objectForKey:GROWL_APP_NAME] retain];
		appId = [[ticketDict objectForKey:GROWL_APP_ID] retain];
      NSString *host = [ticketDict valueForKey:GROWL_NOTIFICATION_GNTP_SENT_BY];
      if ([host hasSuffix:@".local"]) {
         host = [host substringToIndex:([host length] - [@".local" length])];
      }
      if(!host){
         isLocalHost = YES;
      }else {
         if ([ticketDict valueForKey:@"isGrowlAppLocalHost"]) {
            isLocalHost = [[ticketDict valueForKey:@"isGrowlAppLocalHost"] boolValue];
         }else {
            isLocalHost = [host isLocalHost];
         }
      }
      if(isLocalHost){
         appNameHostName = appName;
      }else {
         hostName = [host retain];
         appNameHostName = [[[NSString alloc] initWithFormat:@"%@ - %@", hostName, appName] autorelease];
      }
      
		if (appId && ![appId isKindOfClass:[NSString class]]) {
			NSLog(@"Ticket for application %@ contains invalid bundle ID %@! Rejecting.", appName, appId);
			[self release];
			return nil;
		}

		humanReadableNames = [[ticketDict objectForKey:GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES] retain];
		notificationDescriptions = [[ticketDict objectForKey:GROWL_NOTIFICATIONS_DESCRIPTIONS] retain];

		//Get all the notification names and the data about them
		allNotificationNames = [ticketDict objectForKey:GROWL_NOTIFICATIONS_ALL];
		NSAssert1(allNotificationNames, @"Ticket dictionaries must contain a list of all their notifications (application name: %@)", appName);

		NSArray *inDefaults = [ticketDict objectForKey:GROWL_NOTIFICATIONS_DEFAULT];
		if (!inDefaults) inDefaults = allNotificationNames;

		NSMutableDictionary *allNotificationsTemp = [[NSMutableDictionary alloc] initWithCapacity:[allNotificationNames count]];
		NSMutableArray *allNamesTemp = [[NSMutableArray alloc] initWithCapacity:[allNotificationNames count]];
		for (id obj in allNotificationNames) {
			NSString *name;
			GrowlNotificationTicket *notification;
			if ([obj isKindOfClass:[NSString class]]) {
				name = obj;
				notification = [[GrowlNotificationTicket alloc] initWithName:obj];
			} else {
				name = [obj objectForKey:@"Name"];
				notification = [[GrowlNotificationTicket alloc] initWithDictionary:obj];
			}
			[allNamesTemp addObject:name];
			[notification setTicket:self];

			//Set the human readable name if we were supplied one
			[notification setHumanReadableName:[humanReadableNames objectForKey:name]];
			[notification setNotificationDescription:[notificationDescriptions objectForKey:name]];

			[allNotificationsTemp setObject:notification forKey:name];
			[notification release];
		}
		allNotifications = allNotificationsTemp;
		allNotificationNames = allNamesTemp;

		BOOL doLookup = YES;
		NSString *fullPath = nil;
		id location = [ticketDict objectForKey:GROWL_APP_LOCATION];
		if (location) {
			if ([location isKindOfClass:[NSDictionary class]]) {
				NSDictionary *file_data = [(NSDictionary *)location objectForKey:@"file-data"];
				NSURL *url = fileURLWithDockDescription(file_data);
				if (url) {
					fullPath = [url path];
				}
			} else if ([location isKindOfClass:[NSString class]]) {
				fullPath = location;
				if (![[NSFileManager defaultManager] fileExistsAtPath:fullPath])
					fullPath = nil;
			} else if ([location isKindOfClass:[NSNumber class]]) {
				doLookup = [location boolValue];
			}
		}
		if (!fullPath && doLookup) {
			if (appId) {
				CFURLRef appURL = NULL;
				OSStatus err = LSFindApplicationForInfo(kLSUnknownCreator,
														(CFStringRef)appId,
														/*inName*/ NULL,
														/*outAppRef*/ NULL,
														&appURL);
				if (err == noErr) {
					fullPath = [(NSString *)CFURLCopyPath(appURL) autorelease];
					CFRelease(appURL);
				}
			}
			if (!fullPath)
				fullPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:appName];
		}
		appPath = [fullPath retain];
//		NSLog(@"got appPath: %@", appPath);

		[self setIconData:[ticketDict objectForKey:GROWL_APP_ICON_DATA]];

		id value = [ticketDict objectForKey:UseDefaultsKey];
		if (value)
			useDefaults = [value boolValue];
		else
			useDefaults = YES;

		value = [ticketDict objectForKey:TicketEnabledKey];
		if (value)
			ticketEnabled = [value boolValue];
		else
			ticketEnabled = YES;

		displayPluginName = [[ticketDict objectForKey:GrowlDisplayPluginKey] copy];

		value = [ticketDict objectForKey:ClickHandlersEnabledKey];
		if (value)
			clickHandlersEnabled = [value boolValue];
		else
			clickHandlersEnabled = YES;
		
		value = [ticketDict objectForKey:PositionTypeKey];
		if (value)
			positionType = [value integerValue];
		else
			positionType = 0;	
		
		value = [ticketDict objectForKey:GROWL_POSITION_PREFERENCE_KEY];
		if (value)
			selectedCustomPosition = [value integerValue];
		else
			selectedCustomPosition = 0;				

		[self setDefaultNotifications:inDefaults];

		changed = YES;
		synchronizeOnChanges = YES;
		
		[self addObserver:self forKeyPath:@"displayPluginName" options:NSKeyValueObservingOptionNew context:self];
		[self addObserver:self forKeyPath:@"ticketEnabled" options:NSKeyValueObservingOptionNew context:self];
		[self addObserver:self forKeyPath:@"clickHandlersEnabled" options:NSKeyValueObservingOptionNew context:self];
		[self addObserver:self forKeyPath:@"positionType" options:NSKeyValueObservingOptionNew context:self];
		[self addObserver:self forKeyPath:@"selectedPosition" options:NSKeyValueObservingOptionNew context:self];
	}
	return self;
}

- (void) dealloc {
	
	[self removeObserver:self forKeyPath:@"displayPluginName"];
	[self removeObserver:self forKeyPath:@"ticketEnabled"];
	[self removeObserver:self forKeyPath:@"clickHandlersEnabled"];
	[self removeObserver:self forKeyPath:@"positionType"];
	[self removeObserver:self forKeyPath:@"selectedPosition"];
	
	[appName                  release];
	[appId                    release];
	[appPath                  release];
	[iconData                 release];
	[icon					  release];
	[allNotifications         release];
	[defaultNotifications     release];
	[humanReadableNames       release];
	[notificationDescriptions release];
	[allNotificationNames     release];
	[displayPluginName        release];

	[super dealloc];
}

#pragma mark -

- (id) initTicketFromPath:(NSString *) ticketPath {	
	NSURL *ticketURL = [NSURL fileURLWithPath:ticketPath isDirectory:NO];
	NSDictionary *ticketDict = [NSDictionary dictionaryWithContentsOfURL:ticketURL];

	if (!ticketDict) {
		NSLog(@"Tried to init a ticket from this file, but it isn't a ticket file: %@", ticketPath);
		[self release];
		return nil;
	}

	self = [self initWithDictionary:ticketDict];
	return self;
}

- (id) initTicketForApplication: (NSString *) inApp {
	return [self initTicketFromPath:[[[[GrowlPathUtilities growlSupportDirectory]
										stringByAppendingPathComponent:@"Tickets"]
										stringByAppendingPathComponent:inApp]
										stringByAppendingPathExtension:@"growlTicket"]];
}

- (NSString *) path {
	NSString *destDir = [GrowlPathUtilities growlSupportDirectory];
	destDir = [destDir stringByAppendingPathComponent:@"Tickets"];
	destDir = [destDir stringByAppendingPathComponent:[appName stringByAppendingPathExtension:@"growlTicket"]];
	return destDir;
}

- (void) saveTicket {
	NSString *destDir = [GrowlPathUtilities growlSupportDirectory];
	destDir = [destDir stringByAppendingPathComponent:@"Tickets"];

	[self saveTicketToPath:destDir];
}

- (void) saveTicketToPath:(NSString *)destDir {
	// Save a Plist file of this object to configure the prefs of apps that aren't running
	// construct a dictionary of our state data then save that dictionary to a file.
	NSString *savePath = [destDir stringByAppendingPathComponent:[appNameHostName stringByAppendingPathExtension:@"growlTicket"]];
	NSMutableArray *saveNotifications = [[NSMutableArray alloc] initWithCapacity:[allNotifications count]];
	for (GrowlNotificationTicket *obj in [allNotifications objectEnumerator]) {
		[saveNotifications addObject:[obj dictionaryRepresentation]];
	}
	
	NSDictionary *file_data = nil;
	if (appPath) {
		NSURL *url = [[NSURL alloc] initFileURLWithPath:appPath];
		file_data = dockDescriptionWithURL(url);
		[url release];
	}

	id location = file_data ? [NSDictionary dictionaryWithObject:file_data forKey:@"file-data"] : appPath;
	if (!location)
		location = [NSNumber numberWithBool:NO];

	NSNumber *useDefaultsValue = [[NSNumber alloc] initWithBool:useDefaults];
	NSNumber *ticketEnabledValue = [[NSNumber alloc] initWithBool:ticketEnabled];
	NSNumber *clickHandlersEnabledValue = [[NSNumber alloc] initWithBool:clickHandlersEnabled];
	NSNumber *positionTypeValue = [[NSNumber alloc] initWithInteger:positionType];
	NSNumber *selectedCustomPositionValue = [[NSNumber alloc] initWithInteger:selectedCustomPosition];
   NSNumber *localHost = [NSNumber numberWithBool:isLocalHost];
	NSData *theIconData = iconData;
	NSMutableDictionary *saveDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
		appName,						GROWL_APP_NAME,
		saveNotifications,				GROWL_NOTIFICATIONS_ALL,
		defaultNotifications,			GROWL_NOTIFICATIONS_DEFAULT,
		theIconData,					GROWL_APP_ICON_DATA,
		useDefaultsValue,				UseDefaultsKey,
		ticketEnabledValue,				TicketEnabledKey,
		clickHandlersEnabledValue,		ClickHandlersEnabledKey,
		positionTypeValue,				PositionTypeKey,
		selectedCustomPositionValue,	GROWL_POSITION_PREFERENCE_KEY,
		location,						GROWL_APP_LOCATION,
      localHost,               @"isGrowlAppLocalHost",
		nil];
	[useDefaultsValue					release];
	[ticketEnabledValue					release];
	[clickHandlersEnabledValue			release];
	[positionTypeValue					release];
	[selectedCustomPositionValue		release];
	[saveNotifications					release];
	
   if (hostName)
      [saveDict setObject:hostName forKey:GROWL_NOTIFICATION_GNTP_SENT_BY];
      
	if (displayPluginName)
		[saveDict setObject:displayPluginName forKey:GrowlDisplayPluginKey];

	if (humanReadableNames)
		[saveDict setObject:humanReadableNames forKey:GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES];

	if (notificationDescriptions)
		[saveDict setObject:notificationDescriptions forKey:GROWL_NOTIFICATIONS_DESCRIPTIONS];

	if (appId)
		[saveDict setObject:appId forKey:GROWL_APP_ID];

	NSData *plistData;
	NSString *error;
	plistData = [NSPropertyListSerialization dataFromPropertyList:saveDict
														   format:NSPropertyListBinaryFormat_v1_0
												 errorDescription:&error];
	if (plistData)
		[plistData writeToFile:savePath atomically:YES];
	else
		NSLog(@"Error writing ticket for application %@: %@", appName, error);
	[saveDict release];

	changed = NO;
}

- (void) doSynchronize {
	[self saveTicket];

	NSNumber *pid = [[NSNumber alloc] initWithInt:[[NSProcessInfo processInfo] processIdentifier]];
	NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
		appName, @"TicketName",
		pid,     @"pid",
		nil];
	[pid release];
	//this should no longer be necessary
    //[[NSNotificationCenter defaultCenter] postNotificationName:GrowlPreferencesChanged object:@"GrowlTicketChanged" userInfo:userInfo];
	[userInfo release];	
}

- (void) synchronize {
	if (synchronizeOnChanges) {
		//Coalesce a series of changes into a single message; this makes mass changes (such as registration) much faster.
		[NSObject cancelPreviousPerformRequestsWithTarget:self
												 selector:@selector(doSynchronize)
												   object:nil];
		[self performSelector:@selector(doSynchronize)
				   withObject:nil
				   afterDelay:0.5];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if(([keyPath isEqualToString:@"displayPluginName"] ||
	    [keyPath isEqualToString:@"ticketEnabled"] ||
	    [keyPath isEqualToString:@"clickHandlersEnabled"] ||
	    [keyPath isEqualToString:@"positionType"] ||
	    [keyPath isEqualToString:@"selectedPosition"]) && [object isEqual:self])
	{
		[self synchronize];
	}	
}
#pragma mark -

- (NSData *) iconData {
	if (!iconData) {
		if (appPath) {
			[icon release];
			icon = [[[NSWorkspace sharedWorkspace] iconForFile:appPath] retain];
			iconData = [[icon PNGRepresentation] retain];
		}
		if (!iconData) {
			[icon release];
			icon = [[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericApplicationIcon)] retain];
			[icon setSize:NSMakeSize(128.0f, 128.0f)];
			iconData = [[icon PNGRepresentation] retain];
		}
	}
	return iconData;
}

- (void) setIconData:(NSData *)inIconData {
	if (iconData != inIconData) {
		if (iconData && [inIconData isEqual:iconData])
			return;
		changed = YES;

		//Test that this data is valid. If it isn't, set the data to nil instead.
		BOOL isValidData = NO;
		for (Class imageRepClass in [NSImageRep registeredImageRepClasses]) {
			if ([imageRepClass canInitWithData:inIconData]) {
				isValidData = YES;
				break;
			}
		}
		if (!isValidData)
			inIconData = nil;

		[iconData release];
		iconData = [inIconData retain];
		[icon release]; icon = nil;
	}
}

- (void)setIcon:(NSImage *)inIcon {
	[self setIconData:[inIcon PNGRepresentation]];

	[icon autorelease];
	icon = [inIcon retain];
}

- (NSString *) applicationName {
   return appName;
}

- (GrowlDisplayPlugin *) displayPlugin {
	if (!displayPlugin && displayPluginName)
		displayPlugin = (GrowlDisplayPlugin *)[[GrowlPluginController sharedController] displayPluginInstanceWithName:displayPluginName author:nil version:nil type:nil];
	return displayPlugin;
}

#pragma mark -

- (NSString *) description {
	return [NSString stringWithFormat:@"<GrowlApplicationTicket: %p>{\n\tApplicationName: \"%@\"\n\ticon data length: %i\n\tAll Notifications: %@\n\tDefault Notifications: %@\n\tAllowed Notifications: %@\n\tUse Defaults: %@\n}",
		self, appName, [iconData length], allNotifications, defaultNotifications, [self allowedNotifications], ( useDefaults ? @"YES" : @"NO" )];
}

#pragma mark -

- (void) reregisterWithAllNotifications:(NSArray *)inAllNotes defaults:(id)inDefaults iconData:(NSData *)inIconData {
	if (!useDefaults) {
		/*We want to respect the user's preferences, but if the application has
		 *	added new notifications since it last registered, we want to enable those
		 *	if the application says to.
		 */
		NSMutableDictionary *allNotesCopy = [allNotifications mutableCopy];

		if ([inDefaults respondsToSelector:@selector(objectEnumerator)] ) {
			Class NSNumberClass = [NSNumber class];
			NSUInteger numAllNotifications = [inAllNotes count];
			for (id obj in inDefaults) {
				NSString *note;
				if ([obj isKindOfClass:NSNumberClass]) {
					//it's an index into the all-notifications list
					unsigned notificationIndex = [obj unsignedIntValue];
					if (notificationIndex >= numAllNotifications) {
						NSLog(@"WARNING: application %@ tried to allow notification at index %u by default, but there is no such notification in its list of %u", appName, (unsigned int)notificationIndex, (unsigned int)numAllNotifications);
						note = nil;
					} else {
						note = [inAllNotes objectAtIndex:notificationIndex];
					}
				} else {
					//it's probably a notification name
					note = obj;
				}

				if (note && ![allNotesCopy objectForKey:note]) {
					GrowlNotificationTicket *ticket = [GrowlNotificationTicket notificationWithName:note];
					[ticket setHumanReadableName:[humanReadableNames objectForKey:note]];
					[ticket setNotificationDescription:[notificationDescriptions objectForKey:note]];
					[allNotesCopy setObject:ticket forKey:note];
				}
			}

		} else if ([inDefaults isKindOfClass:[NSIndexSet class]]) {
			NSUInteger notificationIndex;
			NSUInteger numAllNotifications = [inAllNotes count];
			NSIndexSet *iset = (NSIndexSet *)inDefaults;
			for (notificationIndex = [iset firstIndex]; notificationIndex != NSNotFound; notificationIndex = [iset indexGreaterThanIndex:notificationIndex]) {
				if (notificationIndex >= numAllNotifications) {
					NSLog(@"WARNING: application %@ tried to allow notification at index %u by default, but there is no such notification in its list of %u", appName, (unsigned int)notificationIndex, (unsigned int)numAllNotifications);
					// index sets are sorted, so we can stop here
					break;
				} else {
					NSString *note = [inAllNotes objectAtIndex:notificationIndex];
					if (![allNotesCopy objectForKey:note]) {
						GrowlNotificationTicket *ticket = [GrowlNotificationTicket notificationWithName:note];
						[ticket setHumanReadableName:[humanReadableNames objectForKey:note]];
						[ticket setNotificationDescription:[notificationDescriptions objectForKey:note]];
						[allNotesCopy setObject:ticket forKey:note];
					}
				}
			}

		} else {
			if (inDefaults)
				NSLog(@"WARNING: application %@ passed an invalid object for the default notifications: %@.", appName, inDefaults);
		}

		if (![allNotifications isEqual:allNotesCopy]) {
			[allNotifications release];
			allNotifications = allNotesCopy;
			changed = YES;
		} else {
			[allNotesCopy release];
		}
	}

	//ALWAYS set all notifications list first, to enable handling of numeric indices in the default notifications list!
	[self setAllNotifications:inAllNotes];
	[self setDefaultNotifications:inDefaults];

	[self setIconData:inIconData];
}

- (void) reregisterWithDictionary:(NSDictionary *)dict {
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];

	NSData *appIconData = [dict objectForKey:GROWL_APP_ICON_DATA];
	NSString *bundleId = [dict objectForKey:GROWL_APP_ID];

	if (bundleId != appId && ![bundleId isEqualToString:appId]) {
		[appId release];
		appId = [bundleId retain];
		changed = YES;
	}

	//XXX - should assimilate reregisterWithAllNotifications:defaults:iconData: here
	NSArray	*all      = [dict objectForKey:GROWL_NOTIFICATIONS_ALL];
	NSArray	*defaults = [dict objectForKey:GROWL_NOTIFICATIONS_DEFAULT];

	NSDictionary *newNames = [dict objectForKey:GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES];
	if (newNames != humanReadableNames && ![newNames isEqual:humanReadableNames]) {
		[humanReadableNames release];
		humanReadableNames = [newNames retain];
		changed = YES;
	}

	NSDictionary *newDescriptions = [dict objectForKey:GROWL_NOTIFICATIONS_DESCRIPTIONS];
	if (newDescriptions != notificationDescriptions && ![newDescriptions isEqual:notificationDescriptions]) {
		[notificationDescriptions release];
		notificationDescriptions = [newDescriptions retain];
		changed = YES;
	}

	if (!defaults) defaults = all;
	[self reregisterWithAllNotifications:all
								defaults:defaults
								iconData:appIconData];

	NSString *fullPath = nil;
	id location = [dict objectForKey:GROWL_APP_LOCATION];
	if (location) {
		if ([location isKindOfClass:[NSDictionary class]]) {
			NSDictionary *file_data = [location objectForKey:@"file-data"];
			NSURL *url = fileURLWithDockDescription(file_data);
			if (url) {
				fullPath = [url path];
			}
		} else if ([location isKindOfClass:[NSString class]]) {
			fullPath = location;
			if (![[NSFileManager defaultManager] fileExistsAtPath:fullPath])
				fullPath = nil;
		}
		/* Don't handle the NSNumber case here, the app might have moved and we
		 * use the re-registration to update our stored appPath.
		*/
	}
	if (!fullPath) {
		if (appId) {
			CFURLRef appURL = NULL;
			OSStatus err = LSFindApplicationForInfo(kLSUnknownCreator,
													(CFStringRef)appId,
													/*inName*/ NULL,
													/*outAppRef*/ NULL,
													&appURL);
			if (err == noErr) {
				fullPath = [(NSString *)CFURLCopyPath(appURL) autorelease];
				if(fullPath)
					CFMakeCollectable(fullPath);		
				CFRelease(appURL);
			}
		}
		if (!fullPath)
			fullPath = [workspace fullPathForApplication:appName];
	}
	if (fullPath != appPath && ![fullPath isEqualToString:appPath]) {
		[appPath release];
		appPath = [fullPath retain];
		changed = YES;
	}
}

- (NSArray *) allNotifications {
	return [[[allNotifications allKeys] retain] autorelease];
}

- (void) setAllNotifications:(NSArray *)inArray {
	if (allNotificationNames != inArray) {
		if ([inArray isEqualToArray:allNotificationNames])
			return;
		changed = YES;
		[allNotificationNames release];
		allNotificationNames = [inArray retain];

		//We want to keep all of the old notification settings and create entries for the new ones
		NSMutableDictionary *tmp = [[NSMutableDictionary alloc] initWithCapacity:[inArray count]];
		id obj;
		for (id key in inArray) {
			obj = [allNotifications objectForKey:key];
			if (obj) {
				[tmp setObject:obj forKey:key];
			} else {
				GrowlNotificationTicket *notification = [[GrowlNotificationTicket alloc] initWithName:key];
				[notification setHumanReadableName:[humanReadableNames objectForKey:key]];
				[notification setNotificationDescription:[notificationDescriptions objectForKey:key]];
				[tmp setObject:notification forKey:key];
				[notification release];
			}
		}
		[allNotifications release];
		allNotifications = tmp;

		// And then make sure the list of default notifications also doesn't have any straglers...
		NSMutableSet *cur = [[NSMutableSet alloc] initWithArray:defaultNotifications];
		NSSet *new = [[NSSet alloc] initWithArray:allNotificationNames];
		[cur intersectSet:new];
		[defaultNotifications release];
		defaultNotifications = [[cur allObjects] retain];
		[cur release];
		[new release];
	}
}

- (NSArray *) defaultNotifications {
	return [[defaultNotifications retain] autorelease];
}

- (void) setDefaultNotifications:(id)inObject {
	if (!allNotifications) {
		/*WARNING: if you try to pass an array containing numeric indices, and
		 *	the all-notifications list has not been supplied yet, the indices
		 *	WILL NOT be dereferenced. ALWAYS set the all-notifications list FIRST.
		 */
		if (![defaultNotifications isEqual:inObject]) {
			[defaultNotifications release];
			defaultNotifications = [inObject retain];
			changed = YES;
		}
	} else if ([inObject isKindOfClass:NSClassFromString(@"NSArray")] ) {
		NSUInteger numDefaultNotifications;
		NSUInteger numAllNotifications = [allNotificationNames count];
		if ([inObject respondsToSelector:@selector(count)])
			numDefaultNotifications = [inObject count];
		else
			numDefaultNotifications = numAllNotifications;
		NSMutableArray *mDefaultNotifications = [[NSMutableArray alloc] initWithCapacity:numDefaultNotifications];
		Class NSNumberClass = [NSNumber class];
		for (NSNumber *num in inObject) {
			if ([num isKindOfClass:NSNumberClass]) {
				//it's an index into the all-notifications list
				unsigned notificationIndex = [num unsignedIntValue];
				if (notificationIndex >= numAllNotifications)
					NSLog(@"WARNING: application %@ tried to allow notification at index %u by default, but there is no such notification in its list of %u", appName, (unsigned int)notificationIndex, (unsigned int)numAllNotifications);
				else
					[mDefaultNotifications addObject:[allNotificationNames objectAtIndex:notificationIndex]];
			} else {
				//it's probably a notification name
				[mDefaultNotifications addObject:num];
			}
		}
		if (![defaultNotifications isEqualToArray:mDefaultNotifications]) {
			[defaultNotifications release];
			defaultNotifications = mDefaultNotifications;
			changed = YES;
		} else {
			[mDefaultNotifications release];
		}
	} else if ([inObject isKindOfClass:[NSIndexSet class]]) {
		NSUInteger notificationIndex;
		NSUInteger numAllNotifications = [allNotificationNames count];
		NSIndexSet *iset = (NSIndexSet *)inObject;
		NSMutableArray *mDefaultNotifications = [[NSMutableArray alloc] initWithCapacity:[iset count]];
		for (notificationIndex = [iset firstIndex]; notificationIndex != NSNotFound; notificationIndex = [iset indexGreaterThanIndex:notificationIndex]) {
			if (notificationIndex >= numAllNotifications) {
				NSLog(@"WARNING: application %@ tried to allow notification at index %u by default, but there is no such notification in its list of %u", appName, (unsigned int)notificationIndex, (unsigned int)numAllNotifications);
				// index sets are sorted, so we can stop here
				break;
			} else {
				[mDefaultNotifications addObject:[allNotificationNames objectAtIndex:notificationIndex]];
			}
		}
		if (![defaultNotifications isEqualToArray:mDefaultNotifications]) {
			[defaultNotifications release];
			defaultNotifications = mDefaultNotifications;
			changed = YES;
		} else {
			[mDefaultNotifications release];
		}
	} else {
		if (inObject)
			NSLog(@"WARNING: application %@ passed an invalid object for the default notifications: %@.", appName, inObject);
		if (![defaultNotifications isEqualToArray:allNotificationNames]) {
			[defaultNotifications release];
			defaultNotifications = [allNotificationNames retain];
			changed = YES;
		}
	}

	if (useDefaults)
		[self setAllowedNotificationsToDefault];
}

- (NSArray *) allowedNotifications {
	NSMutableArray* allowed = [NSMutableArray array];

	for (GrowlNotificationTicket *obj in [allNotifications objectEnumerator])
		if ([obj enabled])
			[allowed addObject:[obj name]];
	return allowed;
}

- (void) setAllowedNotifications:(NSArray *) inArray {
	NSSet *allowed = [[NSSet alloc] initWithArray:inArray];

	for (GrowlNotificationTicket *obj in [allNotifications objectEnumerator]) {
		[obj setEnabled:[allowed containsObject:[obj name]]];
	}
	[allowed release];

	useDefaults = NO;
}

- (void) setAllowedNotificationsToDefault {
	[self setAllowedNotifications:defaultNotifications];
	useDefaults = YES;
}

- (BOOL) isNotificationAllowed:(NSString *) name {
	return ticketEnabled && [[allNotifications objectForKey:name] enabled];
}

- (NSComparisonResult) caseInsensitiveCompare:(GrowlApplicationTicket *)aTicket {
	return [appNameHostName caseInsensitiveCompare:[aTicket appNameHostName]];
}

#pragma mark Notification Accessors
- (NSArray *) notifications {
	return [allNotifications allValues];
}

- (GrowlNotificationTicket *) notificationTicketForName:(NSString *)name {
	return [allNotifications objectForKey:name];
}
@end
