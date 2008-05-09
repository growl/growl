//
//  GrowlPathway.m
//  Growl
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "GrowlPathway.h"
#import "GrowlApplicationController.h"
#import "GrowlPathUtilities.h"

static NSString *lastSavedNotificationsSubdirectoryName = nil;
static unsigned long long notificationCounter = 0U;

@implementation GrowlPathway

static GrowlApplicationController *applicationController = nil;

- (id) init {
	if ((self = [super init])) {
		if (!applicationController)
			applicationController = [GrowlApplicationController sharedInstance];
	}
	return self;
}

#pragma mark Recording notifications

+ (void) recordNotificationWithDictionary:(NSDictionary *)dict {
	NSFileManager *mgr = [NSFileManager defaultManager];

	NSString *directory = nil;
	NSArray *searchPath = [GrowlPathUtilities searchPathForDirectory: GrowlSavedNotificationsDirectory
														   inDomains: NSAllDomainsMask
													  mustBeWritable: YES];
	if (searchPath && [searchPath count])
		directory = [searchPath objectAtIndex:0U];
	else {
		directory = [GrowlPathUtilities growlSupportDirectory];
		if (directory) {
#warning XXX We really should make GrowlPathUtilities able to create the subdirectories for us. That would clean up several of its own methods, too.
			directory = [directory stringByAppendingPathComponent:@"Saved Notifications"];
			[mgr createDirectoryAtPath:directory attributes:nil];
		}
	}

	//Go through the search-path method again in order to benefit again from its permissions checks.
	searchPath = [GrowlPathUtilities searchPathForDirectory: GrowlSavedNotificationsDirectory
												  inDomains: NSAllDomainsMask
											 mustBeWritable: YES];
	if (searchPath && [searchPath count])
		directory = [searchPath objectAtIndex:0U];
	else {
		NSLog(@"Could not create directory: %@", directory);
		directory = nil;
	}

	if (directory) {
		//The Saved Notifications directory's contents are subdirectories, named by date (YYYY-MM-DD).
		NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
		[formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
		[formatter setDateFormat:@"yyyy-MM-dd"];

		NSString *subdirectoryName = [formatter stringFromDate:[NSDate date]];
		directory = [directory stringByAppendingPathComponent:subdirectoryName];

		/*If lastSavedNotificationsSubdirectoryName is nil, then this is the first notification that this GHA process has received, so we have not yet set that variable.
		 *If the two names are not equal, then the date has rolled over. In that case, this subdirectory doesn't exist yet, so we must create it.
		 *Following De Morgan's Law: If lastSavedEtc is not nil, and is equal to the current subdirectory name, then this is not the first notification and the date has not rolled over, so we don't need to create the subdirectory or set lastSavedEtc.
		 *If, on the other hand, that proposition is false, then we do need to create the subdirectory or set lastSavedEtc (or both).
		 *In any case, when we *do* do those things, we also reset the notification counter, because it's a new day.
		 */
		if (!(lastSavedNotificationsSubdirectoryName && [lastSavedNotificationsSubdirectoryName isEqualToString:subdirectoryName])) {
			[lastSavedNotificationsSubdirectoryName release];
			lastSavedNotificationsSubdirectoryName = [subdirectoryName retain];

			[mgr createDirectoryAtPath:directory attributes:nil];

			notificationCounter = 0U;
		}

		NSString *path;
		//If the user *re*started Growl, blindly using this value of notificationCounter could result in overwriting already-recorded notifications from earlier today.
		//So, we loop until either we find a filename that doesn't already exist or we run out of numbers.
		while ((path = [directory stringByAppendingPathComponent:[[NSString stringWithFormat:@"Growl saved notification #%llu", notificationCounter] stringByAppendingPathExtension:@"plist"]])) {
			//If the file doesn't already exist, then we have found what we're looking for.
			if (![mgr fileExistsAtPath:path])
				break;

			//If it does already exist, and the next number is 0, then we have run out of numbers.
			if (++notificationCounter == 0U) {
				NSLog(@"%s: Ran out of notification numbers! Can't record this notification.", __PRETTY_FUNCTION__);
				return;
			}
		}

		NSError *error = nil;
		NSString *errorString = nil;

		//OK. We have a filename for a file that doesn't already exist. Now, finally, we write the dictionary to the file.
		NSData *data = [NSPropertyListSerialization dataFromPropertyList:dict
																  format:NSPropertyListXMLFormat_v1_0
														errorDescription:&errorString];
		if ([data writeToFile:path options:0 error:&error])
			NSLog(@"Wrote notification to file: %@", path);
		else
			NSLog(@"Could not write notification to file %@ because %@", path, error ? (id)error : (id)errorString);
	}
}

//This method is a trampoline. We only have it because NSObject doesn't have performSelectorOnMainThread: as a class method, only as an instance method.
- (void) recordNotificationWithDictionary:(NSDictionary *)dict {
	[[self class] recordNotificationWithDictionary:dict];
}

#pragma mark Notification-receptor methods

- (void) registerApplicationWithDictionary:(NSDictionary *)dict {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[applicationController performSelectorOnMainThread:@selector(registerApplicationWithDictionary:)
											withObject:dict
										 waitUntilDone:NO];
	[pool release];
}

- (void) postNotificationWithDictionary:(NSDictionary *)dict {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[applicationController performSelectorOnMainThread:@selector(dispatchNotificationWithDictionary:)
											withObject:dict
										 waitUntilDone:NO];
	[self performSelectorOnMainThread:@selector(recordNotificationWithDictionary:)
						   withObject:dict
						waitUntilDone:NO];
	[pool release];
}

- (NSString *) growlVersion {
	return [GrowlApplicationController growlVersion];
}
@end
