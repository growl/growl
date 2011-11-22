//
//	GrowlNotification.m
//	Growl
//
//	Copyright 2005-2011 The Growl Project. All rights reserved.
//

#import "GrowlNotification.h"
#import "GrowlDefines.h"

@implementation GrowlNotification

@synthesize name;
@synthesize applicationName;
@synthesize title;
@synthesize messageText;
@synthesize icon;
@synthesize identifier;
@synthesize sticky;
@synthesize priority;
@synthesize auxiliaryDictionary;

+ (GrowlNotification *) notificationWithDictionary:(NSDictionary *)dict {
	return [[[self alloc] initWithDictionary:dict] autorelease];
}

- (GrowlNotification *) initWithDictionary:(NSDictionary *)dict {
	if ((self = [self initWithName:[dict objectForKey:GROWL_NOTIFICATION_NAME]
				   applicationName:[dict objectForKey:GROWL_APP_NAME]
							 title:[dict objectForKey:GROWL_NOTIFICATION_TITLE]
					   description:[dict objectForKey:GROWL_NOTIFICATION_DESCRIPTION]])) {
		NSMutableDictionary *mutableDict = [dict mutableCopy];
		[mutableDict removeObjectsForKeys:[[GrowlNotification standardKeys] allObjects]];
		if ([mutableDict count])
			[self setAuxiliaryDictionary:mutableDict];
		[mutableDict release];
	}
	return self;
}

- (GrowlNotification *) initWithName:(NSString *)newName
                                applicationName:(NSString *)newAppName
                                          title:(NSString *)newTitle
                                    description:(NSString *)newDesc
{
	if ((self = [self init])) {
		name            = [newName      copy];
		applicationName = [newAppName   copy];

		title           = [newTitle     copy];
		messageText     = [newDesc      copy];
	}
	return self;
}

- (void) dealloc {
	[name            release];
	[applicationName release];
	[title           release];
	[messageText     release];
	[auxiliaryDictionary release];

	[cachedDictionaryRepresentation release];

	[super dealloc];
}

#pragma mark -

+ (NSSet *) standardKeys {
	static NSSet *standardKeys = nil;

	if (!standardKeys) {
		standardKeys = [[NSSet alloc] initWithObjects:
			GROWL_NOTIFICATION_NAME,
			GROWL_APP_NAME,
			GROWL_NOTIFICATION_TITLE,
			GROWL_NOTIFICATION_DESCRIPTION,
			nil];
	}

	return standardKeys;
}

- (NSDictionary *) dictionaryRepresentation {
	return [self dictionaryRepresentationWithKeys:nil];
}
- (NSDictionary *) dictionaryRepresentationWithKeys:(NSSet *)keys {
	NSMutableDictionary *dict = nil;

	if (!keys) {
		//Try cache first.
		if (cachedDictionaryRepresentation)
			return [[cachedDictionaryRepresentation retain] autorelease];

		//No joy - create it.
		dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
			name,            GROWL_NOTIFICATION_NAME,
			applicationName, GROWL_APP_NAME,
			title,           GROWL_NOTIFICATION_TITLE,
			messageText,     GROWL_NOTIFICATION_DESCRIPTION,
			nil];

		for (id key in auxiliaryDictionary)
			if (![dict objectForKey:key])
				[dict setObject:[auxiliaryDictionary objectForKey:key] forKey:key];
	} else {
		//Only include keys in the set.
		dict = [[NSMutableDictionary alloc] initWithCapacity:[keys count]];

		if ([keys containsObject:GROWL_NOTIFICATION_NAME])
			[dict setObject:name forKey:GROWL_NOTIFICATION_NAME];
		if ([keys containsObject:GROWL_APP_NAME])
			[dict setObject:applicationName forKey:GROWL_APP_NAME];
		if ([keys containsObject:GROWL_NOTIFICATION_TITLE])
			[dict setObject:title forKey:GROWL_NOTIFICATION_TITLE];
		if ([keys containsObject:GROWL_NOTIFICATION_DESCRIPTION])
			[dict setObject:messageText forKey:GROWL_NOTIFICATION_DESCRIPTION];

		for (id key in auxiliaryDictionary)
			if ([keys containsObject:key] && ![dict objectForKey:key])
				[dict setObject:[auxiliaryDictionary objectForKey:key] forKey:key];
	}

	NSDictionary *result = [NSDictionary dictionaryWithDictionary:dict];
	[dict release];

	if (!keys) {
		//Update our cache.
		[cachedDictionaryRepresentation release];
		 cachedDictionaryRepresentation = nil;

		cachedDictionaryRepresentation = [result retain];
	}

	return result;
}

#pragma mark -

- (NSString *) notificationDescription {
	return self.messageText;
}

- (void) setAuxiliaryDictionary:(NSDictionary *)newAuxDict {
	[auxiliaryDictionary release];
	 auxiliaryDictionary = [newAuxDict copy];

	/*-dictionaryRepresentationWithKeys:nil depends on the auxiliary dictionary.
	 *so if the auxiliary dictionary changes, we must dirty the cache used by
	 *	-dictionaryRepresentation.
	 */
	[cachedDictionaryRepresentation release];
	 cachedDictionaryRepresentation = nil;
}

@end
