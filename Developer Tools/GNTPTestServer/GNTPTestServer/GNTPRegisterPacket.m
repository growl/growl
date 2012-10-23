//
//  GNTPRegisterPacket.m
//  GNTPTestServer
//
//  Created by Daniel Siemer on 7/4/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "GNTPRegisterPacket.h"
#import "GrowlDefines.h"
#import "GrowlDefinesInternal.h"
#import "GrowlImageAdditions.h"

@interface GNTPRegisterPacket ()

@property (nonatomic, assign) NSUInteger totalNotifications;
@property (nonatomic, assign) NSUInteger readNotifications;

@end

@implementation GNTPRegisterPacket

@synthesize totalNotifications = _totalNotifications;
@synthesize readNotifications = _readNotifications;
@synthesize notificationDicts = _notificationDicts;

+(NSMutableDictionary*)gntpDictFromGrowlDict:(NSDictionary *)dict {
	NSMutableDictionary *converted = [super gntpDictFromGrowlDict:dict];
	NSArray *allNotes = [dict valueForKey:GROWL_NOTIFICATIONS_ALL];
	NSArray *defaultNotes = [dict valueForKey:GROWL_NOTIFICATIONS_DEFAULT];
	BOOL useNumberDefaults = [defaultNotes count] > 0 ? [[defaultNotes objectAtIndex:0] isKindOfClass:[NSNumber class]] : NO; //If count is 0, doesn't really matter
	NSDictionary *noteIcons = [dict valueForKey:GROWL_NOTIFICATIONS_ICONS];
	NSDictionary *humanReadableNames = [dict valueForKey:GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES];
	NSDictionary *descriptions = [dict valueForKey:GROWL_NOTIFICATIONS_DESCRIPTIONS];
	
	NSMutableArray *convertedNotes = [NSMutableArray arrayWithCapacity:[allNotes count]];
	[allNotes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSMutableDictionary *noteDict = [NSMutableDictionary dictionary];
		[noteDict setObject:obj forKey:GrowlGNTPNotificationName];
		
		id defaultObj = useNumberDefaults ? [NSNumber numberWithUnsignedInteger:idx] : obj;
		if([defaultNotes containsObject:defaultObj]){
			[noteDict setObject:@"Yes" forKey:GrowlGNTPNotificationEnabled];
		}else{
			[noteDict setObject:@"No" forKey:GrowlGNTPNotificationEnabled];
		}
		
		id iconObject = [noteIcons objectForKey:obj];
		if(iconObject){
			if([iconObject isKindOfClass:[NSImage class]])
				iconObject = [iconObject PNGRepresentation];
			//Add to the data blocks
			NSString *dataIdentifier = [GNTPPacket identifierForBinaryData:iconObject];
			NSMutableDictionary *dataDict = [converted objectForKey:@"GNTPDATABLOCKS"];
			if(!dataDict){
				dataDict = [NSMutableDictionary dictionary];
				[converted setObject:dataDict forKey:@"GNTPDATABLOCKS"];
			}
			[dataDict setObject:iconObject forKey:dataIdentifier];
			[noteDict setObject:[NSString stringWithFormat:@"x-growl-resource://%@", dataIdentifier] forKey:GrowlGNTPNotificationIcon];
		}
		if([humanReadableNames objectForKey:obj])
			[noteDict setObject:[humanReadableNames objectForKey:obj] forKey:GrowlGNTPNotificationDisplayName];
		if([descriptions objectForKey:obj])
			[noteDict setObject:[descriptions objectForKey:obj] forKey:@"X-Notification-Description"];
		
		[convertedNotes addObject:noteDict];
	 }];
	[converted setObject:[NSString stringWithFormat:@"%lu", [allNotes count]] forKey:GrowlGNTPNotificationCountHeader];
	[converted setObject:convertedNotes	forKey:GROWL_NOTIFICATIONS_ALL];
	return converted;
}

+(NSString*)headersForGNTPDictionary:(NSDictionary *)dict {
	NSMutableString *headers = [[[super headersForGNTPDictionary:dict] mutableCopy] autorelease];
	NSArray *allNotes = [dict objectForKey:GROWL_NOTIFICATIONS_ALL];
	[allNotes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		//Seperate our the notes from each other
		[headers appendString:@"\r\n"];
		[obj enumerateKeysAndObjectsUsingBlock:^(id key, id innerObj, BOOL *innerStop) {
			[headers appendFormat:@"%@: %@\r\n", key, innerObj];
		}];
	}];
	return [[headers copy] autorelease];
}

-(id)init {
	if((self = [super init])){
		_totalNotifications = 0;
		_readNotifications = 0;
		_notificationDicts = [[NSMutableArray alloc] init];
	}
	return self;
}

-(BOOL)validateNoteDictionary:(NSDictionary*)noteDict {
	return [noteDict valueForKey:GrowlGNTPNotificationName] != nil;
}

-(NSInteger)parseDataBlock:(NSData *)data
{
	NSInteger result = 0;
	switch (self.state) {
		case 101:
		{
			//Reading in notifications
			//break it down
			//No need to handle the extra CLRF's after the last line
			NSString *noteHeaderBlock = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
			
			NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
			[GNTPPacket enumerateHeaders:noteHeaderBlock
									 withBlock:^BOOL(NSString *headerKey, NSString *headerValue) {
										 if([headerValue isKindOfClass:[NSString class]]) {
											 NSRange resourceRange = [headerValue rangeOfString:@"x-growl-resource://"];
											 if(resourceRange.location != NSNotFound && resourceRange.location == 0){
												 //This is a resource ID; add the ID to the array of waiting IDs
												 NSString *dataBlockID = [headerValue substringFromIndex:resourceRange.location + resourceRange.length];
												 [self.dataBlockIdentifiers addObject:dataBlockID];
											 }
										 }
										 [dictionary setObject:headerValue forKey:headerKey];
										 return NO;
									 }];
			//validate
			if(![self validateNoteDictionary:dictionary]){
				if([[dictionary allValues] count] > 0)
					NSLog(@"Unable to validate notification %@ in registration packet", dictionary);
				else
					NSLog(@"Empty note dict misread?");
			}else{
				[self.notificationDicts addObject:dictionary];
			}
			[dictionary release];
			//Even if we can't validate it, we did read it, skip it and move on
			self.readNotifications++;
			
			if(self.totalNotifications - self.readNotifications == 0) {
				if([self.dataBlockIdentifiers count] > 0)
					self.state = 1;
				else{
					self.state = 999;
				}
			}
			break;
		}
		default:
			[super parseDataBlock:data];
			break;
	}
	if(self.totalNotifications == 0)
		result = -1;
	else
		result = (self.totalNotifications - self.readNotifications) + [self.dataBlockIdentifiers count];
	
	if(self.totalNotifications - self.readNotifications > 0) {
		self.state = 101; //More notifications to read, read them, otherwise state is controlled by the call to super parseDataBlock
	}
	
	return result;
}

-(void)parseHeaderKey:(NSString *)headerKey value:(NSString *)stringValue
{
	if([headerKey caseInsensitiveCompare:GrowlGNTPNotificationCountHeader] == NSOrderedSame){
		self.totalNotifications = [stringValue integerValue];
		if(self.totalNotifications == 0)
			NSLog(@"Error parsing %@ as an integer for a number of notifications", stringValue);
	}else{
		[super parseHeaderKey:headerKey value:stringValue];
	}
}

-(void)receivedResourceDataBlock:(NSData *)data forIdentifier:(NSString *)identifier {
	[self.notificationDicts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		//check the icon, its the main thing that will need replacing
		id icon = [obj objectForKey:GrowlGNTPNotificationIcon];
		if([icon isKindOfClass:[NSString class]] && [icon rangeOfString:identifier].location != NSNotFound){
			//Found an icon that matches the ID
			[obj setObject:data forKey:identifier];
		}
	}];
	//pass it back up to super in case there are things that need replacing up there
	[super receivedResourceDataBlock:data forIdentifier:identifier];
}

-(BOOL)validate {
	return [super validate] && self.totalNotifications == [self.notificationDicts count];
}

-(NSDictionary*)convertedGrowlDict {
	NSMutableDictionary *convertedDict = [[super convertedGrowlDict] retain];
	NSMutableArray *notificationNames = [NSMutableArray arrayWithCapacity:[self.notificationDicts count]];
	NSMutableDictionary *displayNames = [NSMutableDictionary dictionary];
	//2.0 framework should be upgraded to include descriptions
	NSMutableDictionary *notificationDescriptions = [NSMutableDictionary dictionary];
	NSMutableArray *enabledNotes = [NSMutableArray array];
	//Should really upgrade 2.0 to support note icons during registration;
	NSMutableDictionary *noteIcons = [NSMutableDictionary dictionary];
	[self.notificationDicts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSString *notificationName = [obj objectForKey:GrowlGNTPNotificationName];
		if(notificationName){
			[notificationNames addObject:notificationName];
			
			NSString *displayName = [obj objectForKey:GrowlGNTPNotificationDisplayName];
			NSString *enabledString = [obj objectForKey:GrowlGNTPNotificationEnabled];
			NSString *description = [obj objectForKey:@"X-Notification-Description"];
			id icon = [obj objectForKey:GrowlGNTPNotificationIcon];
			NSData *iconData = nil;
			if(icon)
				iconData = [GNTPPacket convertedDataForIconObject:icon];
						
			if(displayName)
				[displayNames setObject:displayName forKey:notificationName];
			if(description)
				[notificationDescriptions setObject:description forKey:notificationName];
			if(enabledString && 
				([enabledString caseInsensitiveCompare:@"Yes"] == NSOrderedSame || 
				[enabledString caseInsensitiveCompare:@"True"] == NSOrderedSame))
			{
				[enabledNotes addObject:notificationName];
			}
			if(iconData)
				[noteIcons setObject:iconData forKey:notificationName];
		}else{
			NSLog(@"Unable to process note without name!");
		}
	}];
	
   if(![convertedDict objectForKey:GROWL_APP_ICON_DATA]){
      [convertedDict setObject:[[NSImage imageNamed:NSImageNameNetwork] TIFFRepresentation] forKey:GROWL_APP_ICON_DATA];
   }
   
	[convertedDict setObject:notificationNames forKey:GROWL_NOTIFICATIONS_ALL];
	if([enabledNotes count] > 0)
		[convertedDict setObject:enabledNotes forKey:GROWL_NOTIFICATIONS_DEFAULT];
	if([[displayNames allValues] count] > 0)
		[convertedDict setObject:displayNames forKey:GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES];
	if([[notificationDescriptions allValues] count] > 0)
		[convertedDict setObject:notificationDescriptions forKey:GROWL_NOTIFICATIONS_DESCRIPTIONS];
	if([[noteIcons allValues] count] > 0)
		[convertedDict setObject:noteIcons forKey:GROWL_NOTIFICATIONS_ICONS];
	return [convertedDict autorelease];
}

@end
