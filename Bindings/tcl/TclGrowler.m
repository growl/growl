#include <Cocoa/Cocoa.h>

#include "GrowlApplicationBridge.h"

#include "TclGrowler.h"

@implementation TclGrowler

- (id)initWithName:(NSString *)aName notifications:(NSArray *)notes icon:(NSImage *)aIcon
{
	if ((self = [super init])) {
		appName = [[NSString alloc] initWithString:aName];
		allNotifications = [[NSArray alloc] initWithArray:notes];
		appIcon = [[NSData alloc] initWithData:[aIcon TIFFRepresentation]];

		[GrowlApplicationBridge setGrowlDelegate:self];
	}

	return self;
}

- (void)dealloc
{
	[appName release];
	[allNotifications release];
	[appIcon release];
	[super dealloc];
}

#pragma mark GrowlApplicationBridgeDelegate

- (NSDictionary *)registrationDictionaryForGrowl
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		allNotifications, GROWL_NOTIFICATIONS_ALL,
		allNotifications, GROWL_NOTIFICATIONS_DEFAULT,
		nil];
}

- (NSString *)applicationNameForGrowl
{
	return appName;
}

- (NSData *)applicationIconDataForGrowl
{
	return appIcon;
}

- (void)growlIsReady
{
}

- (void)growlNotificationWasClicked:(id)clickContext
{
}

@end
