//
//	GrowlNotification.h
//	Growl
//
//	Copyright 2005-2011 The Growl Project. All rights reserved.
//

@interface GrowlNotification: NSObject
{
	NSString *name, *applicationName;
	NSString *title, *description;
	NSAttributedString *attributedTitle, *attributedDescription;

	NSDictionary *dictionary, *auxiliaryDictionary;

	unsigned GANReserved: 30;
}

+ (GrowlNotification *) notificationWithDictionary:(NSDictionary *)dict;

- (GrowlNotification *) initWithDictionary:(NSDictionary *)dict;

//You can pass nil for description.
- (GrowlNotification *) initWithName:(NSString *)newName
                                applicationName:(NSString *)newAppName
                                          title:(NSString *)newTitle
                                    description:(NSString *)newDesc;

#pragma mark -

/*As of 1.3, this returns:
 *	*	GROWL_NOTIFICATION_NAME
 *	*	GROWL_APP_NAME
 *	*	GROWL_NOTIFICATION_TITLE
 *	*	GROWL_NOTIFICATION_DESCRIPTION
 *You can pass this set to -dictionaryRepresentationWithKeys:.
 */
+ (NSSet *) standardKeys;

//Same as dictionaryRepresentationWithKeys:nil.
- (NSDictionary *) dictionaryRepresentation;

/*With nil, returns all of the standard keys plus the auxiliary dictionary.
 *With non-nil, returns only the keys (from internal storage plus the auxiliary
 *	dictionary) that are in the set.
 *In other words, returns the intersection of the standard dictionary keys, the
 *	auxiliary dictionary, and the provided keys.
 */
- (NSDictionary *) dictionaryRepresentationWithKeys:(NSSet *)keys;

#pragma mark -

- (NSString *) name;
- (NSString *) applicationName;

- (NSString *) title;
- (NSAttributedString *) attributedTitle;

- (NSString *) notificationDescription;
- (NSAttributedString *) attributedDescription;

- (NSDictionary *) auxiliaryDictionary;
- (void) setAuxiliaryDictionary:(NSDictionary *)newAuxDict;

@end
