//
//	GrowlApplicationNotification.m
//	Growl
//
//	Created by Mac-arena the Bored Zo on 2005-07-31.
//	Copyright 2005 The Growl Project. All rights reserved.
//

#import "GrowlApplicationNotification.h"
#import "GrowlDefines.h"

@implementation GrowlApplicationNotification

+ (GrowlApplicationNotification *) notificationWithDictionary:(NSDictionary *)dict {
	return [[[self alloc] initWithDictionary:dict] autorelease];
}

- (GrowlApplicationNotification *) initWithDictionary:(NSDictionary *)dict {
	if ((self = [self initWithName:[dict objectForKey:GROWL_NOTIFICATION_NAME]
				   applicationName:[dict objectForKey:GROWL_APP_NAME]
							 title:[dict objectForKey:GROWL_NOTIFICATION_TITLE]
						 HTMLTitle:[dict objectForKey:GROWL_NOTIFICATION_TITLE_HTML]
					   description:[dict objectForKey:GROWL_NOTIFICATION_DESCRIPTION]
				   HTMLDescription:[dict objectForKey:GROWL_NOTIFICATION_DESCRIPTION_HTML]])) {
		NSMutableDictionary *mutableDict = [dict mutableCopy];
		[mutableDict removeObjectsForKeys:[[GrowlApplicationNotification standardKeys] allObjects]];
		if ([mutableDict count])
			[self setAuxiliaryDictionary:mutableDict];
		[mutableDict release];
	}
	return self;
}

//you can pass nil for description.
- (GrowlApplicationNotification *) initWithName:(NSString *)newName
                                applicationName:(NSString *)newAppName
                                          title:(NSString *)newTitle
                                    description:(NSString *)newDesc
{
	return [self initWithName:newName
	          applicationName:newAppName
	                    title:newTitle
	                HTMLTitle:nil
	              description:newDesc
	          HTMLDescription:nil];
}

//you can pass nil for description, or for either or both of the HTML properties.
- (GrowlApplicationNotification *) initWithName:(NSString *)newName
                                applicationName:(NSString *)newAppName
                                          title:(NSString *)newTitle
                                      HTMLTitle:(NSString *)newHTMLTitle
                                    description:(NSString *)newDesc
                                HTMLDescription:(NSString *)newHTMLDesc
{
	if ((self = [super init])) {
		name            = [newName      copy];
		applicationName = [newAppName   copy];

		title           = [newTitle     copy];
		HTMLTitle       = [newHTMLTitle copy];
		description     = [newDesc      copy];
		HTMLDescription = [newHTMLDesc  copy];

		hasHTMLTitle       = HTMLTitle       != nil;
		hasHTMLDescription = HTMLDescription != nil;
	}
	return self;
}

- (void) dealloc {
	[name            release];
	[applicationName release];
	[title           release];
	[HTMLTitle       release];
	[description     release];
	[HTMLDescription release];

	[dictionary          release];
	[auxiliaryDictionary release];

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
			GROWL_NOTIFICATION_TITLE_HTML,
			GROWL_NOTIFICATION_DESCRIPTION,
			GROWL_NOTIFICATION_DESCRIPTION_HTML,
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
		//try cache first.
		if (dictionary)
			return [[dictionary retain] autorelease];

		//no joy - create it.
		dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
			name,            GROWL_NOTIFICATION_NAME,
			applicationName, GROWL_APP_NAME,
			title,           GROWL_NOTIFICATION_TITLE,
			description,     GROWL_NOTIFICATION_DESCRIPTION,
			nil];

		if (HTMLTitle)
			[dict setObject:HTMLTitle       forKey:GROWL_NOTIFICATION_TITLE_HTML];
		if (HTMLDescription)
			[dict setObject:HTMLDescription forKey:GROWL_NOTIFICATION_DESCRIPTION_HTML];

		NSEnumerator *auxKeyEnum = [auxiliaryDictionary keyEnumerator];
		id key;
		while ((key = [auxKeyEnum nextObject]))
			if (![dict objectForKey:key])
				[dict setObject:[auxiliaryDictionary objectForKey:key] forKey:key];
	} else {
		//only include keys in the set.
		dict = [[NSMutableDictionary alloc] initWithCapacity:[keys count]];

		if ([keys containsObject:GROWL_NOTIFICATION_NAME])
			[dict setObject:name forKey:GROWL_NOTIFICATION_NAME];
		if ([keys containsObject:GROWL_APP_NAME])
			[dict setObject:applicationName forKey:GROWL_APP_NAME];
		if ([keys containsObject:GROWL_NOTIFICATION_TITLE])
			[dict setObject:title forKey:GROWL_NOTIFICATION_TITLE];
		if ([keys containsObject:GROWL_NOTIFICATION_DESCRIPTION])
			[dict setObject:description forKey:GROWL_NOTIFICATION_DESCRIPTION];
		if (HTMLTitle && [keys containsObject:GROWL_NOTIFICATION_TITLE_HTML])
			[dict setObject:HTMLTitle forKey:GROWL_NOTIFICATION_TITLE_HTML];
		if (HTMLDescription && [keys containsObject:GROWL_NOTIFICATION_DESCRIPTION_HTML])
			[dict setObject:HTMLDescription forKey:GROWL_NOTIFICATION_DESCRIPTION_HTML];

		NSEnumerator *auxKeyEnum = [auxiliaryDictionary keyEnumerator];
		id key;
		while ((key = [auxKeyEnum nextObject]))
			if ([keys containsObject:key] && ![dict objectForKey:key])
				[dict setObject:[auxiliaryDictionary objectForKey:key] forKey:key];
	}

	NSDictionary *result = [NSDictionary dictionaryWithDictionary:dict];
	[dict release];

	if (!keys) {
		//update our cache.
		[dictionary release];
		 dictionary = nil;

		dictionary = [result retain];
	}

	return result;
}

#pragma mark -

- (NSString *) name {
	return name;
}
- (NSString *) applicationName {
	return applicationName;
}

- (NSString *) title {
	return title;
}
- (NSAttributedString *) attributedTitle {
	if (HTMLTitle)
		return [[[NSAttributedString alloc] initWithHTML:[HTMLTitle dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:NULL] autorelease];
	else
		return [[[NSAttributedString alloc] initWithString:title] autorelease];
}
- (NSString *) HTMLTitle {
	return HTMLTitle;
}

- (NSString *) description {
	return description;
}
- (NSAttributedString *) attributedDescription {
	if (HTMLDescription)
		return [[[NSAttributedString alloc] initWithHTML:[HTMLDescription dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:NULL] autorelease];
	else
		return [[[NSAttributedString alloc] initWithString:description] autorelease];
}
- (NSString *) HTMLDescription {
	return HTMLDescription;
}

- (NSDictionary *) auxiliaryDictionary {
	return auxiliaryDictionary;
}
- (void) setAuxiliaryDictionary:(NSDictionary *)newAuxDict {
	[auxiliaryDictionary release];
	 auxiliaryDictionary = [newAuxDict copy];

	/*-dictionaryRepresentationWithKeys:nil depends on the auxiliary dictionary.
	 *so if the auxiliary dictionary changes, we must dirty the cache used by
	 *	-dictionaryRepresentation.
	 */
	[dictionary release];
	 dictionary = nil;
}

@end
