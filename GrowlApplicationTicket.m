//
//  GrowlApplicationTicket.m
//  Growl
//
//  Created by Karl Adam on Tue Apr 27 2004.
//

#import "GrowlApplicationTicket.h"
#import "GrowlController.h"
#import "NSGrowlAdditions.h"

NSString * UseDefaultsKey = @"useDefaults";
NSString * TicketEnabledKey = @"ticketEnabled";
NSString * UsesCustomDisplayKey = @"usesCustomDisplay";

@implementation GrowlApplicationNotification
+ (GrowlApplicationNotification*) notificationWithName:(NSString*)name {
    return [[[GrowlApplicationNotification alloc] initWithName:name priority:GP_normal enabled:YES] autorelease];
}

+ (GrowlApplicationNotification*) notificationFromDict:(NSDictionary*)dict {
    NSString* name = [dict objectForKey:@"Name"];
    GrowlPriority priority = [[dict objectForKey:@"Priority"] intValue];
    BOOL enabled = [[dict objectForKey:@"Enabled"] boolValue];
    return [[[GrowlApplicationNotification alloc] initWithName:name priority:priority enabled:enabled] autorelease];
}

- (GrowlApplicationNotification*) initWithName:(NSString*)name priority:(GrowlPriority)priority enabled:(BOOL)enabled {
    [self init];
    _name = [name retain];
    _priority = priority;
    _enabled = enabled;
    return self;
}

- (NSDictionary*) notificationAsDict {
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
        _name, @"Name",
        [NSNumber numberWithInt:(int)_priority], @"Priority",
        [NSNumber numberWithBool:_enabled], @"Enabled",
        nil];
    return dict;
}

- (void) dealloc {
    if (_name)
        [_name release];
}

#pragma mark -
- (NSString*) name {
	return [[_name copy] autorelease];
}

- (GrowlPriority) priority {
	return _priority;
}

- (void) setPriority:(GrowlPriority)newPriority {
    _priority = newPriority;
}

- (BOOL) enabled {
	return _enabled;
}

- (void) setEnabled:(BOOL)yorn {
    _enabled = yorn;
}

- (void) enable {
    [self setEnabled:YES];
}

- (void) disable {
    [self setEnabled:NO];
}
@end

#pragma mark -
#pragma mark -

@implementation GrowlApplicationTicket

+ (NSDictionary *) allSavedTickets {
	NSArray *libraryDirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, /*expandTilde*/ YES);
	NSEnumerator *libraryDirEnum = [libraryDirs objectEnumerator];
	NSString *libraryPath, *growlSupportPath;
	NSMutableDictionary *result = [NSMutableDictionary dictionary];

	while ( libraryPath = [libraryDirEnum nextObject] ) {
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

	while ( filename = [growlSupportEnum nextObject] ) {
		filename = [srcDir stringByAppendingPathComponent:filename];
		[mgr fileExistsAtPath:filename isDirectory:&isDir];
		
		if ( (!isDir) && [[filename pathExtension] isEqualToString:@"growlTicket"] ) {
			GrowlApplicationTicket *newTicket = [[self alloc] initTicketFromPath:filename];
			NSString *appName = [newTicket applicationName];
			
			if ( clobber || ![dict objectForKey:appName] ) {
				[dict setObject:newTicket forKey:appName];
				[newTicket release];
			}
		}
	}
	
}

- (id) initWithApplication:(NSString *) inAppName
				  withIcon:(NSImage *) inIcon
		  andNotifications:(NSArray *) inAllNotifications
		   andDefaultNotes:(NSArray *) inDefaults {

	if ( self = [super init] ) {
		_appName	= [inAppName retain];
		_icon		= [inIcon retain];

        NSEnumerator *notificationsEnum = [inAllNotifications objectEnumerator];
        NSMutableDictionary *notificationDict = [NSMutableDictionary dictionary];
        id obj; while (obj = [notificationsEnum nextObject]) {
            [notificationDict setObject:[GrowlApplicationNotification notificationWithName:(NSString*)obj] forKey:obj];
        }
        _allNotifications = [[NSDictionary alloc] initWithDictionary:notificationDict];
		_defaultNotifications = [inDefaults retain];

		[self setAllowedNotifications:inDefaults];
		
		usesCustomDisplay = NO;
		displayPlugin = nil;
		
		_useDefaults = YES;
		ticketEnabled = YES;
	}
	return self;
}

- (void) dealloc {
	[_appName release];
	[_icon release];
	[_allNotifications release];
	[_defaultNotifications release];
	
	[super dealloc];
}

#pragma mark -
- (id) initTicketFromPath:(NSString *) inPath {
    id iconObject;
    self = [super init];
    
    NSDictionary *ticketsList = [NSDictionary dictionaryWithContentsOfFile:inPath];
    _appName = [[ticketsList objectForKey:GROWL_APP_NAME] retain];
    _defaultNotifications = [[NSArray alloc] initWithArray:[ticketsList objectForKey:GROWL_NOTIFICATIONS_DEFAULT]];

    //Get all the notification names and the data about them
    NSArray* allNotificationNames = [[[NSArray alloc] initWithArray:[ticketsList objectForKey:GROWL_NOTIFICATIONS_ALL]] autorelease];
    NSEnumerator *notificationsEnum = [allNotificationNames objectEnumerator];
    NSMutableDictionary *notificationDict = [NSMutableDictionary dictionary];
    id obj; while (obj = [notificationsEnum nextObject]) {
        if ([obj isKindOfClass:[NSString class]]) {
            NSLog(@"updatingTicketFromPath: %@", inPath);
            [notificationDict setObject:[GrowlApplicationNotification notificationWithName:obj] forKey:obj];
            [self setAllowedNotifications:[ticketsList objectForKey:GROWL_NOTIFICATIONS_USER_SET]];
        } else {
            [notificationDict setObject:[GrowlApplicationNotification notificationFromDict:obj] forKey:[obj objectForKey:@"Name"]];
        }
    }
    _allNotifications = [[NSDictionary alloc] initWithDictionary:notificationDict];

    if (iconObject = [ticketsList objectForKey:GROWL_APP_ICON]) {
        _icon = [[NSImage alloc] initWithData:iconObject];
    } else {
        _icon = [[[NSWorkspace sharedWorkspace] iconForApplication:_appName] retain];
    }
    _useDefaults = [[ticketsList objectForKey:UseDefaultsKey] boolValue];

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

- (void) saveTicket {
	NSString *destDir;

	destDir = [[GrowlPreferences preferences] growlSupportDir];
	destDir = [destDir stringByAppendingPathComponent:@"Tickets"];

	[self saveTicketToPath:destDir];
}

- (void) saveTicketToPath:(NSString *)destDir {
	// Save a Plist file of this object to configure the prefs of apps that aren't running
	// construct a dictionary of our state data then save that dictionary to a file.
	NSString *savePath = [destDir stringByAppendingPathComponent:[_appName stringByAppendingPathExtension:@"growlTicket"]];
    NSMutableArray *saveNotifications = [NSMutableArray array];
    NSEnumerator *notificationEnum = [_allNotifications objectEnumerator];
    id obj; while (obj = [notificationEnum nextObject]) {
        [saveNotifications addObject:[obj notificationAsDict]];
    }

    NSDictionary *saveDict = [NSDictionary dictionaryWithObjectsAndKeys:
		_appName, GROWL_APP_NAME,
		_icon ? [_icon TIFFRepresentation] : [NSData data], GROWL_APP_ICON,
		saveNotifications, GROWL_NOTIFICATIONS_ALL,
		_defaultNotifications, GROWL_NOTIFICATIONS_DEFAULT,
		[NSNumber numberWithBool:_useDefaults], UseDefaultsKey,
		[NSNumber numberWithBool:ticketEnabled], TicketEnabledKey,
		[NSNumber numberWithBool:usesCustomDisplay], UsesCustomDisplayKey,
		[displayPlugin name], GrowlDisplayPluginKey,
		nil];
	// NSString *aString = [saveDict description];
	[saveDict writeToFile:savePath atomically:YES];
}

#pragma mark -

- (NSImage *) icon {
	if (_icon)
		return _icon;
	NSImage* icon = [[NSWorkspace sharedWorkspace] iconForFileType: NSFileTypeForHFSTypeCode(kGenericApplicationIcon)];
	[icon setSize:NSMakeSize(128.,128.)];
	return icon;

}
- (void) setIcon:(NSImage *) inIcon {
	if ( _icon != inIcon ) {
		[_icon release];
		_icon = [inIcon retain];
	}
}

- (NSString *) applicationName {
	return _appName;
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
		self, _appName, _icon, _allNotifications, _defaultNotifications, [self allowedNotifications], ( _useDefaults ? @"YES" : @"NO" )];
}

#pragma mark -

-(void)reRegisterWithAllNotes:(NSArray *) inAllNotes defaults: (NSArray *) inDefaults icon:(NSImage *) inIcon {
	[self setIcon:inIcon];
	if(!_useDefaults) {
		//We want to respect the user's preferences, but if the application has
		//added new notifications since it last registered, we want to enable those
		//if the application says to.
		NSEnumerator		* enumerator;
		NSString			* note;
		NSMutableDictionary *allNotesCopy = [[_allNotifications mutableCopy] autorelease];
        
		enumerator = [inDefaults objectEnumerator];
		while(note = [enumerator nextObject]) {
            if (![allNotesCopy objectForKey:note]) {
                [allNotesCopy setObject:[GrowlApplicationNotification notificationWithName:note] forKey:note];
            }
		}
        [_allNotifications release];
        _allNotifications = [[NSDictionary alloc] initWithDictionary:allNotesCopy];
	}
	
	[self setAllNotifications:inAllNotes];
	[self setDefaultNotifications:inDefaults];
	return;
}

- (NSArray *) allNotifications {
    return [[[_allNotifications allKeys] retain] autorelease];
}

- (void) setAllNotifications:(NSArray *) inArray {
    NSMutableSet *new, *cur;
    new = [NSMutableSet setWithArray:inArray];
    
    //We want to keep all of the old notification settings and create entries for the new ones
    cur = [NSMutableSet setWithArray:[_allNotifications allKeys]];
    [cur intersectSet:new];
    NSEnumerator *newEnum = [new objectEnumerator];
    NSMutableDictionary* tmp = [NSMutableDictionary dictionary];
    id obj; while (obj = [newEnum nextObject]) {
        if ([_allNotifications objectForKey:obj])
            [tmp setObject:[_allNotifications objectForKey:obj] forKey:obj];
        else
            [tmp setObject:[GrowlApplicationNotification notificationWithName:obj] forKey:obj];
    }
    [_allNotifications release];
    _allNotifications = [[NSDictionary dictionaryWithDictionary:tmp] retain];
    
    // And then make sure the list of default notifications also doesn't have any straglers...
    cur = [NSMutableSet setWithArray:_defaultNotifications];
    [cur intersectSet:new];
    [_defaultNotifications autorelease];
    _defaultNotifications = [[cur allObjects] retain];
}

- (NSArray *) defaultNotifications {
	return [[_defaultNotifications retain] autorelease];
}

- (void) setDefaultNotifications:(NSArray *) inArray {
	[_defaultNotifications autorelease];
	_defaultNotifications = [inArray retain];
	
	if( _useDefaults ) {
		[self setAllowedNotifications:inArray];
        _useDefaults = YES;
	}
}

- (NSArray *) allowedNotifications {
    NSMutableArray* allowed = [NSMutableArray array];
    NSEnumerator *notificationEnum = [_allNotifications objectEnumerator];
    id obj; while (obj = [notificationEnum nextObject]) {
        if ([obj enabled])
            [allowed addObject:[obj name]];
    }
    return allowed;
}

- (void) setAllowedNotifications:(NSArray *) inArray {
    NSEnumerator *notificationEnum = [inArray objectEnumerator];
    [[_allNotifications allValues] makeObjectsPerformSelector:@selector(disable)];
    id obj; while (obj = [notificationEnum nextObject]) {
        [[_allNotifications objectForKey:obj] enable];
    }
	_useDefaults = NO;
}

- (void) setAllowedNotificationsToDefault {
	[self setAllowedNotifications:_defaultNotifications];
	_useDefaults = YES;
}

- (void) setNotificationEnabled:(NSString *) name {
    [[_allNotifications objectForKey:name] setEnabled: YES];
    _useDefaults = NO;
}

- (void) setNotificationDisabled:(NSString *) name {
    [[_allNotifications objectForKey:name] setEnabled: NO];
	_useDefaults = NO;
}

- (BOOL) isNotificationAllowed:(NSString *) name {
	return ticketEnabled && [self isNotificationEnabled:name];
}

- (BOOL) isNotificationEnabled:(NSString *) name {
    return [[_allNotifications objectForKey:name] enabled];
}

#pragma mark Notification Priority

- (int) priorityForNotification:(NSString *) name {
	return [[_allNotifications objectForKey:name] priority];
}

- (void) setPriority:(int)priority forNotification:(NSString *) name {
    [[_allNotifications objectForKey:name] setPriority:(GrowlPriority)priority];
	return;
}
@end

