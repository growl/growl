//
//  GrowlApplicationTicket.m
//  Growl
//
//  Created by Karl Adam on Tue Apr 27 2004.
//  Copyright 2004 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details


#import "GrowlApplicationTicket.h"
#import "GrowlController.h"
#import "NSGrowlAdditions.h"

NSString * UseDefaultsKey = @"useDefaults";
NSString * TicketEnabledKey = @"ticketEnabled";
NSString * UsesCustomDisplayKey = @"usesCustomDisplay";

@implementation GrowlApplicationNotification
+ (GrowlApplicationNotification*) notificationWithName:(NSString*)theName {
	return [[[GrowlApplicationNotification alloc] initWithName:theName priority:GP_unset enabled:YES sticky:NSMixedState] autorelease];
}

+ (GrowlApplicationNotification*) notificationFromDict:(NSDictionary*)dict {
	NSString* inName = [dict objectForKey:@"Name"];
	GrowlPriority inPriority;
	if ([dict objectForKey:@"Priority"]) {
		inPriority = [[dict objectForKey:@"Priority"] intValue];
	} else {
		inPriority = GP_unset;
	}
	BOOL inEnabled = [[dict objectForKey:@"Enabled"] boolValue];
	int inSticky = ([[dict objectForKey:@"Sticky"] intValue] >= 0 ? ([[dict objectForKey:@"Sticky"] intValue] > 0 ? NSOnState : NSOffState) : NSMixedState);
	return [[[GrowlApplicationNotification alloc] initWithName:inName priority:inPriority enabled:inEnabled sticky:inSticky] autorelease];
}

- (GrowlApplicationNotification*) initWithName:(NSString*)inName priority:(GrowlPriority)inPriority enabled:(BOOL)inEnabled sticky:(int)inSticky {
	if ( (self = [super init] ) ) {
		name = [inName retain];
		priority = inPriority;
		enabled = inEnabled;
		sticky = inSticky;
	}
	return self;
}

- (NSDictionary*) notificationAsDict {
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		name, @"Name",
		[NSNumber numberWithBool:enabled], @"Enabled",
		[NSNumber numberWithInt:sticky], @"Sticky",
		nil];
	if (priority != GP_unset) {
		[dict setObject:[NSNumber numberWithInt:priority] forKey:@"Priority"];
	}
	return dict;
}

- (void) dealloc {
	[name release];
	[super dealloc];
}

#pragma mark -
- (NSString*) name {
	return [[name retain] autorelease];
}

- (GrowlPriority) priority {
	return priority;
}

- (void) setPriority:(GrowlPriority)newPriority {
	priority = newPriority;
}

- (void) resetPriority {
	priority = GP_unset;
}

- (BOOL) enabled {
	return enabled;
}

- (void) setEnabled:(BOOL)flag {
	enabled = flag;
}

- (void) enable {
	[self setEnabled:YES];
}

- (void) disable {
	[self setEnabled:NO];
}

- (int) sticky {
	return sticky;
}

- (void) setSticky:(int)value {
	sticky = value;
}
@end

#pragma mark -

@implementation GrowlApplicationTicket

+ (NSDictionary *) allSavedTickets {
	NSArray *libraryDirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, /*expandTilde*/ YES);
	NSEnumerator *libraryDirEnum = [libraryDirs objectEnumerator];
	NSString *libraryPath, *growlSupportPath;
	NSMutableDictionary *result = [NSMutableDictionary dictionary];

	while ( ( libraryPath = [libraryDirEnum nextObject] ) ) {
		growlSupportPath = [libraryPath stringByAppendingPathComponent:@"Application Support"];
		growlSupportPath = [growlSupportPath stringByAppendingPathComponent:@"Growl"];
		growlSupportPath = [growlSupportPath stringByAppendingPathComponent:@"Tickets"];
		//The search paths are returned in the order we should search in, so earlier results should take priority
		//Thus, clobbering:NO
		[self loadTicketsFromDirectory:growlSupportPath intoDictionary:result clobbering:NO];
	}

	return result;
}

+ (void) loadTicketsFromDirectory:(NSString *)srcDir intoDictionary:(NSMutableDictionary *)dict clobbering:(BOOL)clobber {
	NSFileManager *mgr = [NSFileManager defaultManager];
	BOOL isDir;
	NSDirectoryEnumerator *growlSupportEnum = [mgr enumeratorAtPath:srcDir];
	NSString *filename;

	while ( ( filename = [growlSupportEnum nextObject] ) ) {
		filename = [srcDir stringByAppendingPathComponent:filename];
		[mgr fileExistsAtPath:filename isDirectory:&isDir];
		
		if ( (!isDir) && [[filename pathExtension] isEqualToString:@"growlTicket"] ) {
			GrowlApplicationTicket *newTicket = [[self alloc] initTicketFromPath:filename];
			NSString *applicationName = [newTicket applicationName];

			if ( clobber || ![dict objectForKey:applicationName] ) {
				[dict setObject:newTicket forKey:applicationName];
				[newTicket release];
			}
		}
	}
}

- (id) initWithApplication:(NSString *) inAppName
				  withIcon:(NSImage *) inIcon
		  andNotifications:(NSArray *) inAllNotifications
		   andDefaultNotes:(NSArray *) inDefaults {

	if ( ( self = [super init] ) ) {
		appName	= [inAppName retain];
		icon		= [inIcon retain];

		allNotificationNames = [inAllNotifications retain];
		NSEnumerator *notificationsEnum = [allNotificationNames objectEnumerator];
		NSMutableDictionary *notificationDict = [NSMutableDictionary dictionary];
		id obj;
		while ( (obj = [notificationsEnum nextObject] ) ) {
			[notificationDict setObject:[GrowlApplicationNotification notificationWithName:(NSString*)obj] forKey:obj];
		}
		allNotifications = [[NSDictionary alloc] initWithDictionary:notificationDict];
		[self setDefaultNotifications:inDefaults];

		[self setAllowedNotificationsToDefault];

		usesCustomDisplay = NO;
		displayPlugin = nil;
		
		useDefaults = YES;
		ticketEnabled = YES;
	}
	return self;
}

- (void) dealloc {
	[appName release];
	[icon release];
	[allNotifications release];
	[defaultNotifications release];
	
	[super dealloc];
}

#pragma mark -
- (id) initTicketFromPath:(NSString *) inPath {
	id iconObject;
	self = [super init];

	NSDictionary *ticketsList = [NSDictionary dictionaryWithContentsOfFile:inPath];
	appName = [[ticketsList objectForKey:GROWL_APP_NAME] retain];
	defaultNotifications = [[NSArray alloc] initWithArray:[ticketsList objectForKey:GROWL_NOTIFICATIONS_DEFAULT]];

	//Get all the notification names and the data about them
	allNotificationNames = [[NSArray alloc] initWithArray:[ticketsList objectForKey:GROWL_NOTIFICATIONS_ALL]];
	NSEnumerator *notificationsEnum = [allNotificationNames objectEnumerator];
	NSMutableDictionary *notificationDict = [NSMutableDictionary dictionary];
	id obj;
	while ( (obj = [notificationsEnum nextObject] ) ) {
		if ([obj isKindOfClass:[NSString class]]) {
			NSLog(@"updatingTicketFromPath: %@", inPath);
			[notificationDict setObject:[GrowlApplicationNotification notificationWithName:obj] forKey:obj];
			[self setAllowedNotifications:[ticketsList objectForKey:GROWL_NOTIFICATIONS_USER_SET]];
		} else {
			[notificationDict setObject:[GrowlApplicationNotification notificationFromDict:obj] forKey:[obj objectForKey:@"Name"]];
		}
	}
	allNotifications = [[NSDictionary alloc] initWithDictionary:notificationDict];

	if ( (iconObject = [ticketsList objectForKey:GROWL_APP_ICON] ) ) {
		icon = [[NSImage alloc] initWithData:iconObject];
	} else {
		icon = [[[NSWorkspace sharedWorkspace] iconForApplication:appName] retain];
	}
	useDefaults = [[ticketsList objectForKey:UseDefaultsKey] boolValue];

	if ([ticketsList objectForKey:TicketEnabledKey]) {
		ticketEnabled = [[ticketsList objectForKey:TicketEnabledKey] boolValue];
	} else {
		ticketEnabled = YES;
	}
	
	if ([ticketsList objectForKey:UsesCustomDisplayKey]) {
		usesCustomDisplay = [[ticketsList objectForKey:UsesCustomDisplayKey] boolValue];
	} else {
		usesCustomDisplay = NO;
	}
	
	if ([ticketsList objectForKey:GrowlDisplayPluginKey]) {
		[self setDisplayPluginNamed:[ticketsList objectForKey:GrowlDisplayPluginKey]];
	} else {
		displayPlugin = nil;
	}
	[self saveTicket];
	return self;
}

- (id) initTicketForApplication: (NSString *) inApp {
	return [self initTicketFromPath:[[[[[GrowlPreferences preferences] growlSupportDir] 
												stringByAppendingPathComponent:@"Tickets"]
												stringByAppendingPathComponent:inApp]
												stringByAppendingPathExtension:@"growlTicket"]];
}

- (NSString *) path {
	NSString *destDir;
	destDir = [[GrowlPreferences preferences] growlSupportDir];
	destDir = [destDir stringByAppendingPathComponent:@"Tickets"];
	destDir = [destDir stringByAppendingPathComponent:[appName stringByAppendingPathExtension:@"growlTicket"]];
	return destDir;
}

- (void) saveTicket {
	NSString *destDir;

	destDir = [[GrowlPreferences preferences] growlSupportDir];
	destDir = [destDir stringByAppendingPathComponent:@"Tickets"];

	[self saveTicketToPath:destDir];
}

- (void) saveTicketToPath:(NSString *)destDir {
	// Save a Plist file of this object to configure the prefs of apps that aren't running
	// construct a dictionary of our state data then save that dictionary to a file.
	NSString *savePath = [destDir stringByAppendingPathComponent:[appName stringByAppendingPathExtension:@"growlTicket"]];
	NSMutableArray *saveNotifications = [NSMutableArray array];
	NSEnumerator *notificationEnum = [allNotifications objectEnumerator];
	id obj;
	while ( (obj = [notificationEnum nextObject] ) ) {
		[saveNotifications addObject:[obj notificationAsDict]];
	}

	NSDictionary *saveDict = [NSDictionary dictionaryWithObjectsAndKeys:
		appName, GROWL_APP_NAME,
		icon ? [icon TIFFRepresentation] : [NSData data], GROWL_APP_ICON,
		saveNotifications, GROWL_NOTIFICATIONS_ALL,
		defaultNotifications, GROWL_NOTIFICATIONS_DEFAULT,
		[NSNumber numberWithBool:useDefaults], UseDefaultsKey,
		[NSNumber numberWithBool:ticketEnabled], TicketEnabledKey,
		[NSNumber numberWithBool:usesCustomDisplay], UsesCustomDisplayKey,
		[displayPlugin name], GrowlDisplayPluginKey,
		nil];
	// NSString *aString = [saveDict description];
	[saveDict writeToFile:savePath atomically:YES];
}

#pragma mark -

- (NSImage *) icon {
	if (icon) {
		return icon;
	}
	NSImage* genericIcon = [[NSWorkspace sharedWorkspace] iconForFileType: NSFileTypeForHFSTypeCode(kGenericApplicationIcon)];
	[genericIcon setSize:NSMakeSize(128.0f, 128.0f)];
	return genericIcon;

}
- (void) setIcon:(NSImage *) inIcon {
	if ( icon != inIcon ) {
		[icon release];
		icon = [inIcon retain];
	}
}

- (NSString *) applicationName {
	return appName;
}

- (BOOL) ticketEnabled {
	return ticketEnabled;
}

- (void) setEnabled:(BOOL)inEnabled {
	ticketEnabled = inEnabled;
}

- (BOOL)usesCustomDisplay {
	return usesCustomDisplay;
}

- (void)setUsesCustomDisplay: (BOOL)inUsesCustomDisplay {
	usesCustomDisplay = inUsesCustomDisplay;
}

- (id <GrowlDisplayPlugin>) displayPlugin {
	return displayPlugin;
}

- (void) setDisplayPluginNamed: (NSString *)name {
	displayPlugin = [[GrowlPluginController controller] displayPluginNamed:name];
}

#pragma mark -

- (NSString *) description {
	return [NSString stringWithFormat:@"<GrowlApplicationTicket: %p>{\n\tApplicationName: \"%@\"\n\ticon: %@\n\tAll Notifications: %@\n\tDefault Notifications: %@\n\tAllowed Notifications: %@\n\tUse Defaults: %@\n}",
		self, appName, icon, allNotifications, defaultNotifications, [self allowedNotifications], ( useDefaults ? @"YES" : @"NO" )];
}

#pragma mark -

-(void) reregisterWithAllNotifications:(NSArray *) inAllNotes defaults: (NSArray *) inDefaults icon:(NSImage *) inIcon {
	[self setIcon:inIcon];
	if (!useDefaults) {
		//We want to respect the user's preferences, but if the application has
		//added new notifications since it last registered, we want to enable those
		//if the application says to.
		NSEnumerator		* enumerator;
		NSString			* note;
		NSMutableDictionary * allNotesCopy = [[allNotifications mutableCopy] autorelease];
		
		enumerator = [inDefaults objectEnumerator];
		while ( (note = [enumerator nextObject] ) ) {
			if (![allNotesCopy objectForKey:note]) {
				[allNotesCopy setObject:[GrowlApplicationNotification notificationWithName:note] forKey:note];
			}
		}
		[allNotifications release];
		allNotifications = [[NSDictionary alloc] initWithDictionary:allNotesCopy];
	}

	//ALWAYS set all notifications list first, to enable handling of numeric indices in the default notifications list!
	[self setAllNotifications:inAllNotes];
	[self setDefaultNotifications:inDefaults];
}

- (NSArray *) allNotifications {
	return [[[allNotifications allKeys] retain] autorelease];
}

- (void) setAllNotifications:(NSArray *) inArray {
	allNotificationNames = [[NSArray alloc] initWithArray:inArray];
	NSMutableSet *new, *cur;
	new = [NSMutableSet setWithArray:inArray];
	
	//We want to keep all of the old notification settings and create entries for the new ones
	cur = [NSMutableSet setWithArray:[allNotifications allKeys]];
	[cur intersectSet:new];
	NSEnumerator *newEnum = [new objectEnumerator];
	NSMutableDictionary *tmp = [NSMutableDictionary dictionary];
	id key, obj;
	while ( (key = [newEnum nextObject] ) ) {
		obj = [allNotifications objectForKey:key];
		if ( obj ) {
			[tmp setObject:obj forKey:key];
		} else {
			[tmp setObject:[GrowlApplicationNotification notificationWithName:key] forKey:key];
		}
	}
	[allNotifications release];
	allNotifications = [[NSDictionary dictionaryWithDictionary:tmp] retain];

	// And then make sure the list of default notifications also doesn't have any straglers...
	cur = [NSMutableSet setWithArray:defaultNotifications];
	[cur intersectSet:new];
	[defaultNotifications autorelease];
	defaultNotifications = [[cur allObjects] retain];
}

- (NSArray *) defaultNotifications {
	return [[defaultNotifications retain] autorelease];
}

- (void) setDefaultNotifications:(NSArray *) inArray {
	[defaultNotifications autorelease];
	if(!allNotifications) {
		/*WARNING: if you try to pass an array containing numeric indices, and
		 *	the all-notifications list has not been supplied yet, the indices
		 *	WILL NOT be dereferenced. ALWAYS set the all-notifications list FIRST.
		 */
		defaultNotifications = [inArray retain];
	} else {
		NSEnumerator *mightBeIndicesEnum = [inArray objectEnumerator];
		NSNumber *num;
		NSMutableArray *mDefaultNotifications = [[NSMutableArray alloc] init];
		unsigned numAllNotifications = [allNotificationNames count];
		Class NSNumberClass = [NSNumber class];
		while((num = [mightBeIndicesEnum nextObject])) {
			if([num isKindOfClass:NSNumberClass]) {
				//it's an index into the all-notifications list
				unsigned notificationIndex = [num unsignedIntValue];
				if(notificationIndex >= numAllNotifications)
					NSLog(@"WARNING: application %@ tried to allow notification at index %u by default, but there is no such notification in its list of %u", appName, notificationIndex, numAllNotifications);
				else {
					[mDefaultNotifications addObject:[allNotificationNames objectAtIndex:notificationIndex]];
				}
			} else {
				//it's probably a notification name
				[mDefaultNotifications addObject:num];
			}
		}
		defaultNotifications = mDefaultNotifications;
	}

	if ( useDefaults ) {
		[self setAllowedNotifications:defaultNotifications];
		useDefaults = YES;
	}
}

- (NSArray *) allowedNotifications {
	NSMutableArray* allowed = [NSMutableArray array];
	NSEnumerator *notificationEnum = [allNotifications objectEnumerator];
	id obj;
	while ( (obj = [notificationEnum nextObject] ) ) {
		if ([obj enabled]) {
			[allowed addObject:[obj name]];
		}
	}
	return allowed;
}

- (void) setAllowedNotifications:(NSArray *) inArray {
	NSEnumerator *notificationEnum = [inArray objectEnumerator];
	[[allNotifications allValues] makeObjectsPerformSelector:@selector(disable)];
	id obj;
	while ( (obj = [notificationEnum nextObject] ) ) {
		[[allNotifications objectForKey:obj] enable];
	}
	useDefaults = NO;
}

- (void) setAllowedNotificationsToDefault {
	[self setAllowedNotifications:defaultNotifications];
	useDefaults = YES;
}

- (void) setNotificationEnabled:(NSString *) name {
	[[allNotifications objectForKey:name] setEnabled: YES];
	useDefaults = NO;
}

- (void) setNotificationDisabled:(NSString *) name {
	[[allNotifications objectForKey:name] setEnabled: NO];
	useDefaults = NO;
}

- (BOOL) isNotificationAllowed:(NSString *) name {
	return ticketEnabled && [self isNotificationEnabled:name];
}

- (BOOL) isNotificationEnabled:(NSString *) name {
	return [[allNotifications objectForKey:name] enabled];
}

#pragma mark Notification Accessors
// With sticky, 1 is on, 0 is off, -1 means use what's passed
// This corresponds to NSOnState, NSOffState, and NSMixedState
- (int) stickyForNotification:(NSString *) name {
	return [[allNotifications objectForKey:name] sticky];
}

- (void) setSticky:(int)sticky forNotification:(NSString *) name {
	[(GrowlApplicationNotification *)[allNotifications objectForKey:name] setSticky:sticky];
}

- (int) priorityForNotification:(NSString *) name {
	return [[allNotifications objectForKey:name] priority];
}

- (void) setPriority:(int)priority forNotification:(NSString *) name {
	[[allNotifications objectForKey:name] setPriority:(GrowlPriority)priority];
}

- (void) resetPriorityForNotification:(NSString *) name {
	[[allNotifications objectForKey:name] resetPriority];
}
@end

