#include <TclGrowler.h>

@implementation TclGrowler

- (id)initWithName:(NSString *)appName notifications:(NSArray *)notes icon:(NSImage *)appIcon
{
	[self init];

	_appName = [[NSString alloc] initWithString:appName];
	_allNotifications = [[NSArray alloc] initWithArray:notes];
	_appIcon = [[NSData alloc] initWithData:[appIcon TIFFRepresentation]];

	[GrowlApplicationBridge setGrowlDelegate:self];

	return self;
}

- (void)dealloc
{
	[_appName release];
	[_allNotifications release];
	[_appIcon release];
	[super dealloc];
}

#pragma mark GrowlApplicationBridgeDelegate

- (NSDictionary *)registrationDictionaryForGrowl
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		_allNotifications, GROWL_NOTIFICATIONS_ALL,
		_allNotifications, GROWL_NOTIFICATIONS_DEFAULT,
		nil];
}

- (NSString *)applicationNameForGrowl
{
	return _appName;
}

- (NSData *)applicationIconDataForGrowl
{
	return _appIcon;
}

- (void)growlIsReady
{
}

- (void)growlNotificationWasClicked:(id)clickContext
{
}

@end
