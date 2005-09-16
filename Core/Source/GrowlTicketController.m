//
//  GrowlTicketController.m
//  Growl
//
//  Created by Mac-arena the Bored Zo on 2005-06-08.
//  Copyright 2005 Mac-arena the Bored Zo. All rights reserved.
//

#import "GrowlTicketController.h"
#import "GrowlPathUtilities.h"
#include "CFDictionaryAdditions.h"
#include "CFMutableDictionaryAdditions.h"

@implementation GrowlTicketController

+ (id) sharedController {
	return [self sharedInstance];
}

- (id) initSingleton {
	if ((self = [super initSingleton])) {
		ticketsByApplicationName = [[NSMutableDictionary alloc] init];
		[self loadAllSavedTickets];
	}
	return self;
}
- (void) destroy {
	[ticketsByApplicationName release];
	[super destroy];
}

#pragma mark -
#pragma mark Private methods

- (void) loadTicketsFromDirectory:(NSString *)srcDir clobbering:(BOOL)clobber {
	NSFileManager *mgr = [NSFileManager defaultManager];
	BOOL isDir;
	NSDirectoryEnumerator *ticketsEnum = [mgr enumeratorAtPath:srcDir];
	NSString *filename;

	while ((filename = [ticketsEnum nextObject])) {
		filename = [srcDir stringByAppendingPathComponent:filename];
		[mgr fileExistsAtPath:filename isDirectory:&isDir];

		if ((!isDir) && [[filename pathExtension] isEqualToString:GROWL_PATHEXTENSION_TICKET]) {
			GrowlApplicationTicket *newTicket = [[GrowlApplicationTicket alloc] initTicketFromPath:filename];
			if (newTicket) {
				NSString *applicationName = [newTicket applicationName];

				/*if we haven't already loaded a ticket for this application,
				 *	or if we're clobbering already-loaded tickets,
				 *	set this ticket in the dictionary.
				 */
				if (clobber || ![ticketsByApplicationName objectForKey:applicationName])
					[ticketsByApplicationName setObject:newTicket forKey:applicationName];

				[newTicket release];
			}
		}
	}
}

- (void) loadAllSavedTickets {
//	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent(); //TEMP

	// XXX: should use GrowlPathUtilities here
	NSArray *libraryDirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, /*expandTilde*/ YES);
	NSEnumerator *libraryDirEnum = [libraryDirs objectEnumerator];
	NSString *libraryPath, *growlSupportPath;
	[ticketsByApplicationName removeAllObjects];

	while ((libraryPath = [libraryDirEnum nextObject])) {
		growlSupportPath = [libraryPath      stringByAppendingPathComponent:@"Application Support"];
		growlSupportPath = [growlSupportPath stringByAppendingPathComponent:@"Growl"];
		growlSupportPath = [growlSupportPath stringByAppendingPathComponent:@"Tickets"];
		/*the search paths are returned in the order we should search in, so
		 *	earlier results should take priority. thus, clobbering:NO.
		 */
		[self loadTicketsFromDirectory:growlSupportPath clobbering:NO];
	}

//	NSLog(@"Got all saved tickets in %f seconds", CFAbsoluteTimeGetCurrent() - start); //TEMP
}

#pragma mark -
#pragma mark Public methods

- (NSDictionary *) allSavedTickets {
	return [[ticketsByApplicationName copy] autorelease];
}

- (GrowlApplicationTicket *) ticketForApplicationName:(NSString *)appName {
	return getObjectForKey(ticketsByApplicationName, appName);
}
- (void) addTicket:(GrowlApplicationTicket *) newTicket {
	NSString *appName = [newTicket applicationName];
	if (!appName)
		NSLog(@"GrowlTicketController: cannot add ticket because it has no application name (description follows)\n%@", newTicket);
	else {
		setObjectForKey(ticketsByApplicationName, appName, newTicket);
		//XXX this here is pretty barftastic. what about tickets that already have a path? should we clobber the existing path? create a copy? leave it alone, as now? --boredzo
		//if (![newTicket path])
		//	[newTicket setPath:GrowlPathUtilities_defaultSavePathForTicketWithApplicationName(appName)];
		//Don't synchronize here to avoid an infinite loop in -[GrowlApplicationController preferencesChanged]
		//[newTicket synchronize];
	}
}

- (void) removeTicketForApplicationName:(NSString *)appName {
	[ticketsByApplicationName removeObjectForKey:appName];
}

@end
