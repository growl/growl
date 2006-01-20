//
//  GrowlApplicationTicket.m
//  Growl
//
//  Created by Karl Adam on Tue Apr 27 2004.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details


#import "GrowlApplicationTicket.h"
#import "GrowlNotificationTicket.h"
#import "GrowlDefines.h"
#import "GrowlDisplayPlugin.h"
#import "NSWorkspaceAdditions.h"
#import "GrowlPathUtilities.h"
#include "CFGrowlAdditions.h"
#include "CFURLAdditions.h"
#include "CFDictionaryAdditions.h"

#define UseDefaultsKey			@"useDefaults"
#define TicketEnabledKey		@"ticketEnabled"
#define ClickHandlersEnabledKey	@"clickHandlersEnabled"

#pragma mark -

@implementation GrowlApplicationTicket

//these are specifically for auto-discovery tickets, hence the requirement of GROWL_TICKET_VERSION.
+ (BOOL) isValidTicketDictionary:(NSDictionary *)dict {
	if (!dict)
		return NO;

	NSNumber *versionNum = getObjectForKey(dict, GROWL_TICKET_VERSION);
	if ([versionNum intValue] == 1) {
		return getObjectForKey(dict, GROWL_NOTIFICATIONS_ALL)
			&& getObjectForKey(dict, GROWL_APP_NAME);
	} else {
		return NO;
	}
}

+ (BOOL) isKnownTicketVersion:(NSDictionary *)dict {
	id version = getObjectForKey(dict, GROWL_TICKET_VERSION);
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
	if ((self = [super init])) {
		appName = [getObjectForKey(ticketDict, GROWL_APP_NAME) retain];

		humanReadableNames = [[ticketDict objectForKey:GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES] retain];
		notificationDescriptions = [[ticketDict objectForKey:GROWL_NOTIFICATIONS_DESCRIPTIONS] retain];

		//Get all the notification names and the data about them
		allNotificationNames = [ticketDict objectForKey:GROWL_NOTIFICATIONS_ALL];
		NSAssert1(allNotificationNames, @"Ticket dictionaries must contain a list of all their notifications (application name: %@)", appName);

		NSArray *inDefaults = [ticketDict objectForKey:GROWL_NOTIFICATIONS_DEFAULT];
		if (!inDefaults) inDefaults = allNotificationNames;

		NSEnumerator *notificationsEnum = [allNotificationNames objectEnumerator];
		NSMutableDictionary *allNotificationsTemp = [[NSMutableDictionary alloc] initWithCapacity:[allNotificationNames count]];
		NSMutableArray *allNamesTemp = [[NSMutableArray alloc] initWithCapacity:[allNotificationNames count]];
		id obj;
		while ((obj = [notificationsEnum nextObject])) {
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
		id location = getObjectForKey(ticketDict, GROWL_APP_LOCATION);
		if (location) {
			if ([location isKindOfClass:[NSDictionary class]]) {
				NSDictionary *file_data = getObjectForKey((NSDictionary *)location, @"file-data");
				NSURL *URL = createFileURLWithDockDescription(file_data);
				fullPath = [URL path];
				[URL release];
			} else if ([location isKindOfClass:[NSString class]]) {
				fullPath = location;
				if (![[NSFileManager defaultManager] fileExistsAtPath:fullPath])
					fullPath = nil;
			} else if ([location isKindOfClass:[NSNumber class]]) {
				doLookup = [location boolValue];
			}
		}
		if (!fullPath && doLookup)
			fullPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:appName];
		appPath = [fullPath retain];
//		NSLog(@"got appPath: %@", appPath);

		[self setIcon:getObjectForKey(ticketDict, GROWL_APP_ICON)];

		id value = getObjectForKey(ticketDict, UseDefaultsKey);
		if (value)
			useDefaults = [value boolValue];
		else
			useDefaults = YES;

		value = getObjectForKey(ticketDict, TicketEnabledKey);
		if (value)
			ticketEnabled = [value boolValue];
		else
			ticketEnabled = YES;

		displayPluginName = [[ticketDict objectForKey:GrowlDisplayPluginKey] copy];

		value = getObjectForKey(ticketDict, ClickHandlersEnabledKey);
		if (value)
			clickHandlersEnabled = [value boolValue];
		else
			clickHandlersEnabled = YES;

		[self setDefaultNotifications:inDefaults];
		changed = YES;
	}

	return self;
}

- (void) dealloc {
	[appName                  release];
	[appPath                  release];
	[icon                     release];
	[iconData                 release];
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
	CFURLRef ticketURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)ticketPath, kCFURLPOSIXPathStyle, false);
	NSDictionary *ticketDict = (NSDictionary *)createPropertyListFromURL((NSURL *)ticketURL, kCFPropertyListImmutable, NULL, NULL);
	CFRelease(ticketURL);
	if (!ticketDict) {
		NSLog(@"Tried to init a ticket from this file, but it isn't a ticket file: %@", ticketPath);
		[self release];
		return nil;
	}
	self = [self initWithDictionary:ticketDict];
	[ticketDict release];
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
	NSString *savePath = [destDir stringByAppendingPathComponent:[appName stringByAppendingPathExtension:@"growlTicket"]];
	NSMutableArray *saveNotifications = [[NSMutableArray alloc] initWithCapacity:[allNotifications count]];
	NSEnumerator *notificationEnum = [allNotifications objectEnumerator];
	GrowlNotificationTicket *obj;
	while ((obj = [notificationEnum nextObject]))
		[saveNotifications addObject:[obj dictionaryRepresentation]];

	NSDictionary *file_data = nil;
	if (appPath) {
		NSURL *url = [[NSURL alloc] initFileURLWithPath:appPath];
		file_data = createDockDescriptionWithURL(url);
		[url release];
	}

	id location = file_data ? [NSDictionary dictionaryWithObject:file_data forKey:@"file-data"] : appPath;
	if (!location)
		location = [NSNumber numberWithBool:NO];
	[file_data release];

	NSNumber *useDefaultsValue = [[NSNumber alloc] initWithBool:useDefaults];
	NSNumber *ticketEnabledValue = [[NSNumber alloc] initWithBool:ticketEnabled];
	NSNumber *clickHandlersEnabledValue = [[NSNumber alloc] initWithBool:clickHandlersEnabled];
	NSData *theIconData = iconData;
	if (!theIconData) {
		NSImage *theIcon = [self icon];
		theIconData = theIcon ? [theIcon TIFFRepresentation] : [NSData data];
	}
	NSMutableDictionary *saveDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
		appName,                   GROWL_APP_NAME,
		saveNotifications,         GROWL_NOTIFICATIONS_ALL,
		defaultNotifications,      GROWL_NOTIFICATIONS_DEFAULT,
		theIconData,               GROWL_APP_ICON,
		useDefaultsValue,          UseDefaultsKey,
		ticketEnabledValue,        TicketEnabledKey,
		clickHandlersEnabledValue, ClickHandlersEnabledKey,
		location,                  GROWL_APP_LOCATION,
		nil];
	[useDefaultsValue          release];
	[ticketEnabledValue        release];
	[clickHandlersEnabledValue release];
	[saveNotifications         release];
	if (displayPluginName)
		[saveDict setObject:displayPluginName forKey:GrowlDisplayPluginKey];

	if (humanReadableNames)
		[saveDict setObject:humanReadableNames forKey:GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES];

	if (notificationDescriptions)
		[saveDict setObject:notificationDescriptions forKey:GROWL_NOTIFICATIONS_DESCRIPTIONS];

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

- (void) synchronize {
	[self saveTicket];
	int pid = getpid();
	CFNumberRef pidValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &pid);
	CFStringRef keys[2] = { CFSTR("TicketName"), CFSTR("pid") };
	CFTypeRef   values[2] = { appName, pidValue };
	CFDictionaryRef userInfo = CFDictionaryCreate(kCFAllocatorDefault, (const void **)keys, (const void **)values, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	CFRelease(pidValue);
	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(),
										 (CFStringRef)GrowlPreferencesChanged,
										 /*object*/ CFSTR("GrowlTicketChanged"),
										 /*userInfo*/ userInfo,
										 /*deliverImmediately*/ false);
	CFRelease(userInfo);
}

#pragma mark -

- (NSImage *) icon {
	if (icon)
		return icon;
	if (iconData) {
		icon = [[NSImage alloc] initWithData:iconData];
		[iconData release];
		iconData = nil;
	}
	if (!icon && appPath)
		icon = [[[NSWorkspace sharedWorkspace] iconForFile:appPath] retain];
	if (!icon) {
		icon = [[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericApplicationIcon)] retain];
		[icon setSize:NSMakeSize(128.0f, 128.0f)];
	}
	return icon;
}

- (void) setIcon:(NSImage *)inIcon {
	if (icon != inIcon) {
		if ([inIcon isEqualTo:icon] || [inIcon isEqualTo:iconData])
			return;
		changed = YES;
		[icon     release];
		[iconData release];
		if (inIcon) {
			if ([inIcon isKindOfClass:[NSImage class]]) {
				icon = [inIcon copy];
				iconData = nil;
			} else {
				icon = nil;
				iconData = (NSData *)[inIcon retain];
			}
		} else {
			icon = nil;
			iconData = nil;
		}
	}
}

- (NSString *) applicationName {
	return appName;
}

- (BOOL) ticketEnabled {
	return ticketEnabled;
}

- (void) setTicketEnabled:(BOOL)inEnabled {
	ticketEnabled = inEnabled;
	[self synchronize];
}

- (BOOL) clickHandlersEnabled {
	return clickHandlersEnabled;
}

- (void) setClickHandlersEnabled:(BOOL)inEnabled {
	clickHandlersEnabled = inEnabled;
	[self synchronize];
}

- (BOOL) useDefaults {
	return useDefaults;
}

- (void) setUseDefaults:(BOOL)flag {
	useDefaults = flag;
}

- (BOOL) hasChanged {
	return changed;
}

- (void) setHasChanged:(BOOL)flag {
	changed = flag;
}

- (NSString *) displayPluginName {
	return displayPluginName;
}

- (GrowlDisplayPlugin *) displayPlugin {
	if (!displayPlugin && displayPluginName)
		displayPlugin = (GrowlDisplayPlugin *)[[[GrowlPluginController sharedController] displayPluginDictionaryWithName:displayPluginName author:nil version:nil type:nil] pluginInstance];
	return displayPlugin;
}

- (void) setDisplayPluginName: (NSString *)name {
	[displayPluginName release];
	displayPluginName = [name copy];
	displayPlugin = nil;
	[self synchronize];
}

#pragma mark -

- (NSString *) description {
	return [NSString stringWithFormat:@"<GrowlApplicationTicket: %p>{\n\tApplicationName: \"%@\"\n\ticon: %@\n\tAll Notifications: %@\n\tDefault Notifications: %@\n\tAllowed Notifications: %@\n\tUse Defaults: %@\n}",
		self, appName, icon, allNotifications, defaultNotifications, [self allowedNotifications], ( useDefaults ? @"YES" : @"NO" )];
}

#pragma mark -

- (void) reregisterWithAllNotifications:(NSArray *)inAllNotes defaults:(id)inDefaults icon:(NSImage *)inIcon {
	if (!useDefaults) {
		/*We want to respect the user's preferences, but if the application has
		 *	added new notifications since it last registered, we want to enable those
		 *	if the application says to.
		 */
		NSEnumerator		*enumerator;
		NSMutableDictionary *allNotesCopy = [allNotifications mutableCopy];

		if ([inDefaults respondsToSelector:@selector(objectEnumerator)] ) {
			enumerator = [inDefaults objectEnumerator];
			Class NSNumberClass = [NSNumber class];
			unsigned numAllNotifications = [inAllNotes count];
			id obj;
			while ((obj = [enumerator nextObject])) {
				NSString *note;
				if ([obj isKindOfClass:NSNumberClass]) {
					//it's an index into the all-notifications list
					unsigned notificationIndex = [obj unsignedIntValue];
					if (notificationIndex >= numAllNotifications) {
						NSLog(@"WARNING: application %@ tried to allow notification at index %u by default, but there is no such notification in its list of %u", appName, notificationIndex, numAllNotifications);
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
			unsigned notificationIndex;
			unsigned numAllNotifications = [inAllNotes count];
			NSIndexSet *iset = (NSIndexSet *)inDefaults;
			for (notificationIndex = [iset firstIndex]; notificationIndex != NSNotFound; notificationIndex = [iset indexGreaterThanIndex:notificationIndex]) {
				if (notificationIndex >= numAllNotifications) {
					NSLog(@"WARNING: application %@ tried to allow notification at index %u by default, but there is no such notification in its list of %u", appName, notificationIndex, numAllNotifications);
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

		if (![allNotifications isEqualTo:allNotesCopy]) {
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

	[self setIcon:inIcon];
}

- (void) reregisterWithDictionary:(NSDictionary *)dict {
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];

	NSImage *appIcon = [dict objectForKey:GROWL_APP_ICON];

	//XXX - should assimilate reregisterWithAllNotifications:defaults:icon: here
	NSArray	*all      = [dict objectForKey:GROWL_NOTIFICATIONS_ALL];
	NSArray	*defaults = [dict objectForKey:GROWL_NOTIFICATIONS_DEFAULT];

	NSDictionary *newNames = [dict objectForKey:GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES];
	if (newNames != humanReadableNames && ![newNames isEqualTo:humanReadableNames]) {
		[humanReadableNames release];
		humanReadableNames = [newNames retain];
		changed = YES;
	}

	NSDictionary *newDescriptions = [dict objectForKey:GROWL_NOTIFICATIONS_DESCRIPTIONS];
	if (newDescriptions != notificationDescriptions && ![newDescriptions isEqualTo:notificationDescriptions]) {
		[notificationDescriptions release];
		notificationDescriptions = [newDescriptions retain];
		changed = YES;
	}

	if (!defaults) defaults = all;
	[self reregisterWithAllNotifications:all
								defaults:defaults
									icon:appIcon];

	NSString *fullPath = nil;
	id location = [dict objectForKey:GROWL_APP_LOCATION];
	if (location) {
		if ([location isKindOfClass:[NSDictionary class]]) {
			NSDictionary *file_data = [location objectForKey:@"file-data"];
			NSURL *URL = createFileURLWithDockDescription(file_data);
			fullPath = [URL path];
			[URL release];
		} else if ([location isKindOfClass:[NSString class]]) {
			fullPath = location;
			if (![[NSFileManager defaultManager] fileExistsAtPath:fullPath])
				fullPath = nil;
		}
		/* Don't handle the NSNumber case here, the app might have moved and we
		 * use the re-registration to update our stored appPath.
		*/
	}
	if (!fullPath)
		fullPath = [workspace fullPathForApplication:appName];
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
		NSEnumerator *newEnum = [inArray objectEnumerator];
		NSMutableDictionary *tmp = [[NSMutableDictionary alloc] initWithCapacity:[inArray count]];
		id key, obj;
		while ((key = [newEnum nextObject])) {
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
		if (![defaultNotifications isEqualTo:inObject]) {
			[defaultNotifications release];
			defaultNotifications = [inObject retain];
			changed = YES;
		}
	} else if ([inObject respondsToSelector:@selector(objectEnumerator)] ) {
		NSEnumerator *mightBeIndicesEnum = [inObject objectEnumerator];
		NSNumber *num;
		unsigned numDefaultNotifications;
		unsigned numAllNotifications = [allNotificationNames count];
		if ([inObject respondsToSelector:@selector(count)])
			numDefaultNotifications = [inObject count];
		else
			numDefaultNotifications = numAllNotifications;
		NSMutableArray *mDefaultNotifications = [[NSMutableArray alloc] initWithCapacity:numDefaultNotifications];
		Class NSNumberClass = [NSNumber class];
		while ((num = [mightBeIndicesEnum nextObject])) {
			if ([num isKindOfClass:NSNumberClass]) {
				//it's an index into the all-notifications list
				unsigned notificationIndex = [num unsignedIntValue];
				if (notificationIndex >= numAllNotifications)
					NSLog(@"WARNING: application %@ tried to allow notification at index %u by default, but there is no such notification in its list of %u", appName, notificationIndex, numAllNotifications);
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
		unsigned notificationIndex;
		unsigned numAllNotifications = [allNotificationNames count];
		NSIndexSet *iset = (NSIndexSet *)inObject;
		NSMutableArray *mDefaultNotifications = [[NSMutableArray alloc] initWithCapacity:[iset count]];
		for (notificationIndex = [iset firstIndex]; notificationIndex != NSNotFound; notificationIndex = [iset indexGreaterThanIndex:notificationIndex]) {
			if (notificationIndex >= numAllNotifications) {
				NSLog(@"WARNING: application %@ tried to allow notification at index %u by default, but there is no such notification in its list of %u", appName, notificationIndex, numAllNotifications);
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
	NSEnumerator *notificationEnum = [allNotifications objectEnumerator];
	GrowlNotificationTicket *obj;
	while ((obj = [notificationEnum nextObject]))
		if ([obj enabled])
			[allowed addObject:[obj name]];
	return allowed;
}

- (void) setAllowedNotifications:(NSArray *) inArray {
	NSSet *allowed = [[NSSet alloc] initWithArray:inArray];
	NSEnumerator *notificationEnum = [allNotifications objectEnumerator];
	GrowlNotificationTicket *obj;
	while ((obj = [notificationEnum nextObject]))
		[obj setEnabled:[allowed containsObject:[obj name]]];
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
	return [appName caseInsensitiveCompare:[aTicket applicationName]];
}

#pragma mark Notification Accessors
- (NSArray *) notifications {
	return [allNotifications allValues];
}

- (GrowlNotificationTicket *) notificationTicketForName:(NSString *)name {
	return [allNotifications objectForKey:name];
}
@end
