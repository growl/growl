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

-(NSInteger)parseDataBlock:(NSData *)data 
{
	NSInteger result = 0;
	switch (self.state) {
		case 0:
			result = [super parseDataBlock:data];
			if(self.totalNotifications == 0)
				result = -1;
			else
				result += self.totalNotifications;
			self.state = 101;
			break;
		case 101:
		{
			//Reading in notifications
			//break it down
			NSString *noteHeaderBlock = [NSString stringWithUTF8String:[data bytes]];
			NSArray *noteHeaders = [noteHeaderBlock componentsSeparatedByString:@"\r\n"];
			NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
			[noteHeaders enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				if(!obj || [obj isEqualToString:@""] || [obj isEqualToString:@"\r\n"])
					return;
				
				NSString *headerKey = nil;
				NSString *headerValue = nil;
				[GNTPPacket headerKey:&headerKey value:&headerValue forHeaderLine:obj];
				if(headerKey && headerValue){
					[dictionary setObject:headerValue forKey:headerKey];
				}else{
					NSLog(@"Unable to find ': ' that seperates key and value in %@", obj);
				}
			}];
			//validate
			if(![self validateNoteDictionary:dictionary]){
				NSLog(@"Unable to validate notification %@ in registration packet", dictionary);
			}else{
				[self.notificationDicts addObject:dictionary];
			}
			//Even if we can't validate it, we did read it, skip it and move on
			self.readNotifications++;
			result = self.totalNotifications - self.readNotifications + [self.dataBlockIdentifiers count];
			if(self.totalNotifications == self.readNotifications && [self.dataBlockIdentifiers count] > 0){
				self.state = 2; //Notifications
			}else if(self.totalNotifications == self.readNotifications && [self.dataBlockIdentifiers count] == 0){
				self.state = 999;
			}else if(self.totalNotifications > self.readNotifications) {
				self.state = 101;
			}
			break;
		}
		default:
			break;
	}
	return result;
}

@end
