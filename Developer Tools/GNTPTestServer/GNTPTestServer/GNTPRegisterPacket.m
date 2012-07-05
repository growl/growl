//
//  GNTPRegisterPacket.m
//  GNTPTestServer
//
//  Created by Daniel Siemer on 7/4/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "GNTPRegisterPacket.h"

@interface GNTPRegisterPacket ()

@property (nonatomic, assign) NSUInteger totalNotifications;
@property (nonatomic, assign) NSUInteger readNotifications;

@end

@implementation GNTPRegisterPacket

@synthesize totalNotifications = _totalNotifications;
@synthesize readNotifications = _readNotifications;
@synthesize notificationDicts = _notificationDicts;

-(id)init {
	if((self = [super init])){
		_totalNotifications = 0;
		_readNotifications = 0;
		_notificationDicts = [[NSMutableArray alloc] init];
	}
	return self;
}

-(BOOL)validate {
	return [super validate];
}

-(BOOL)validateNoteDictionary:(NSDictionary*)noteDict {
	
	return YES;
}

-(void)receivedResourceDataBlock:(NSData *)data forIdentifier:(NSString *)identifier {
	[self.notificationDicts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		//check the icon, its the main thing that will need replacing
	}];
	//pass it back up to super in case there are things that need replacing up there
	[super receivedResourceDataBlock:data forIdentifier:identifier];
}

-(void)parseHeaderKey:(NSString *)headerKey value:(NSString *)stringValue
{
	if([headerKey caseInsensitiveCompare:GrowlGNTPNotificationCountHeader] == NSOrderedSame){
		self.totalNotifications = [stringValue integerValue];
		NSLog(@"Total notifications: %ld", self.totalNotifications);
		if(self.totalNotifications == 0)
			NSLog(@"Error parsing %@ as an integer for a number of notifications", stringValue);
	}else{
		[super parseHeaderKey:headerKey value:stringValue];
	}
}

-(NSInteger)parseDataBlock:(NSData *)data
{
	NSInteger result = 0;
	switch (self.state) {
		case 101:
		{
			//Reading in notifications
			//break it down
			NSString *noteHeaderBlock = [NSString stringWithUTF8String:[data bytes]];
			NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
			[GNTPPacket enumerateHeaders:noteHeaderBlock
									 withBlock:^BOOL(NSString *headerKey, NSString *headerValue) {
										 NSRange resourceRange = [headerValue rangeOfString:@"x-growl-resource://"];
										 if(resourceRange.location != NSNotFound && resourceRange.location == 0){
											 //This is a resource ID; add the ID to the array of waiting IDs
											 NSString *dataBlockID = [headerValue substringFromIndex:resourceRange.location + resourceRange.length];
											 [self.dataBlockIdentifiers addObject:dataBlockID];
										 }
										 [dictionary setObject:headerValue forKey:headerKey];
										 return NO;
									 }];
			//validate
			if(![self validateNoteDictionary:dictionary]){
				NSLog(@"Unable to validate notification %@ in registration packet", dictionary);
			}else{
				[self.notificationDicts addObject:dictionary];
			}
			[dictionary release];
			//Even if we can't validate it, we did read it, skip it and move on
			self.readNotifications++;
			NSLog(@"Remaining notifications: %ld", self.totalNotifications - self.readNotifications);
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

@end
