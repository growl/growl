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
- (GrowlPriority) priority {
	return _priority;
}

- (void) setPriority:(GrowlPriority)newPriority {
    _priority = newPriority;
}

- (NSString*) name {
	return [[_name copy] autorelease];
}

- (BOOL) enabled {
	return _enabled;
}

- (void) setEnabled:(BOOL)yorn {
    _enabled = yorn;
}

- (NSDictionary*) notificationAsDict {
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
        _name, @"Name",
        [NSNumber numberWithInt:(int)_priority], @"Priority",
        [NSNumber numberWithBool:_enabled], @"Enabled",
        nil];
    return dict;
}

+ (GrowlApplicationNotification*) notificationFromDict:(NSDictionary*)dict {
    NSString* name = [dict objectForKey:@"Name"];
    GrowlPriority priority = [[dict objectForKey:@"Priority"] intValue];
    BOOL enabled = [[dict objectForKey:@"Enabled"] boolValue];
    return [[[GrowlApplicationNotification alloc] initWithName:name priority:priority enabled:enabled] autorelease];
}

- (GrowlApplicationNotification*) initWithName:(NSString*)name priority:(GrowlPriority)priority enabled:(BOOL)enabled {
    self = [super init];
    _name = [name retain];
    _priority = priority;
    _enabled = enabled;
    return self;
}

- (void) dealloc {
    if (_name)
        [_name release];
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
		_allNotifications = [inAllNotifications retain];
		_defaultNotifications = [inDefaults retain];
		_allowedNotifications = [[NSMutableArray alloc] init];
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
	[_allowedNotifications release];
	
	[super dealloc];
}

#pragma mark -
- (id) initTicketFromPath:(NSString *) inPath {
	//load a Plist file of this object to maintain configuration through launches
	id iconObject;
	if ( self = [super init] ) {
		NSDictionary *ticketsList = [NSDictionary dictionaryWithContentsOfFile:inPath];
		_appName = [[ticketsList objectForKey:GROWL_APP_NAME] retain];
		_defaultNotifications = [[NSArray alloc] initWithArray:[ticketsList objectForKey:GROWL_NOTIFICATIONS_DEFAULT]];
		_allNotifications = [[NSArray alloc] initWithArray:[ticketsList objectForKey:GROWL_NOTIFICATIONS_ALL]];
		_allowedNotifications = [[NSMutableArray alloc] init];
		
		[self setAllowedNotifications:[ticketsList objectForKey:GROWL_NOTIFICATIONS_USER_SET]];
		
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
	}
	
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
	// save a Plist file of this object to configure the prefs of apps that aren't running
	// construct a dictionary of our state data then save that dictionary to a file.
	NSString *savePath = [destDir stringByAppendingPathComponent:[_appName stringByAppendingPathExtension:@"growlTicket"]];
	NSDictionary *saveDict = [NSDictionary dictionaryWithObjectsAndKeys:
		_appName, GROWL_APP_NAME,
		_icon ? [_icon TIFFRepresentation] : [NSData data], GROWL_APP_ICON,
		_allNotifications, GROWL_NOTIFICATIONS_ALL,
		_defaultNotifications, GROWL_NOTIFICATIONS_DEFAULT,
		_allowedNotifications, GROWL_NOTIFICATIONS_USER_SET,
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
		self, _appName, _icon, _allNotifications, _defaultNotifications, _allowedNotifications, ( _useDefaults ? @"YES" : @"NO" )];
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
		
		enumerator = [inDefaults objectEnumerator];
		while(note = [enumerator nextObject]) {
			//For each new default ...
			if(![_allNotifications containsObject:note]) {
				//Enable it only if we just found out about it now.
				//If we already knew about it, respect the user's preferences
				[self setNotificationEnabled:note];
			}
		}
	}
	
	[self setAllNotifications:inAllNotes];
	[self setDefaultNotifications:inDefaults];
	return;
}

- (NSArray *) allNotifications {
	return [[_allNotifications retain] autorelease];
}

- (void) setAllNotifications:(NSArray *) inArray {
	if ( inArray != _allNotifications ) {
		[_allNotifications release];
		_allNotifications = [inArray retain];
		
		NSMutableSet * tmp;
		NSSet * inSet = [NSSet setWithArray:inArray];
		
		//Intersect the allowed and default sets with the new set
		tmp = [NSMutableSet setWithArray:_allowedNotifications];
		[tmp intersectSet:inSet];
		[_allowedNotifications setArray:[tmp allObjects]];
		
		tmp = [NSMutableSet setWithArray:_defaultNotifications];
		[tmp intersectSet:inSet];
		[_defaultNotifications autorelease];
		_defaultNotifications = [[tmp allObjects] retain];
	}
}

- (NSArray *) defaultNotifications {
	return [[_defaultNotifications retain] autorelease];
}

- (void) setDefaultNotifications:(NSArray *) inArray {
	[_defaultNotifications autorelease];
	_defaultNotifications = [inArray retain];
	
	if( _useDefaults ) {
		[self setAllowedNotifications:inArray];
	}
}

- (NSArray *) allowedNotifications {
	return [NSArray arrayWithArray:_allowedNotifications];
}

- (void) setAllowedNotifications:(NSArray *) inArray {
	[_allowedNotifications setArray:inArray];
	_useDefaults = NO;
}

- (void) setAllowedNotificationsToDefault {
	[self setAllowedNotifications:_defaultNotifications];
	_useDefaults = YES;
}

- (void) setNotificationEnabled:(NSString *) name {
	if ( ! [_allowedNotifications containsObject:name] ) {
		[_allowedNotifications addObject:name];
		_useDefaults = NO;
	}
}

- (void) setNotificationDisabled:(NSString *) name {
	[_allowedNotifications removeObject:name];
	_useDefaults = NO;
}

- (BOOL) isNotificationAllowed:(NSString *) name {
	return ticketEnabled && [self isNotificationEnabled:name];
}

- (BOOL) isNotificationEnabled:(NSString *) name {
	return [_allowedNotifications containsObject:name];
}

#pragma mark Notification Priority

- (int) priorityForNotification:(NSString *) name {
	return 0;
}

- (void) setPriority:(int)priority forNotification:(NSString *) name {
	return;
}
@end

