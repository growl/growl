//
//  GrowlTicketController.m
//  Growl
//
//  Created by Mac-arena the Bored Zo on 2005-06-08.
//  Copyright 2005 Mac-arena the Bored Zo. All rights reserved.
//

#import "GrowlTicketController.h"
#import "GrowlPathUtil.h"

static GrowlTicketController *singleton = nil;

@implementation GrowlTicketController

+ (id) sharedController {
	if (!singleton)
		singleton = [[GrowlTicketController alloc] init];
	return singleton;
}

- (id) init {
	if ((self = [super init])) {
		[self loadAllSavedTickets];
	}
	return self;
}
- (void) dealloc {
	[ticketsByApplicationName release];
	[super dealloc];
}

#pragma mark -
#pragma mark Private methods

- (void) loadTicketsFromDirectory:(NSString *)srcDir intoDictionary:(NSMutableDictionary *)dict clobbering:(BOOL)clobber {
	NSFileManager *mgr = [NSFileManager defaultManager];
	BOOL isDir;
	NSDirectoryEnumerator *ticketsEnum = [mgr enumeratorAtPath:srcDir];
	NSString *filename;

	while ((filename = [ticketsEnum nextObject])) {
		filename = [srcDir stringByAppendingPathComponent:filename];
		[mgr fileExistsAtPath:filename isDirectory:&isDir];

		if ((!isDir) && [[filename pathExtension] isEqualToString:GROWL_PATHEXTENSION_TICKET]) {
			GrowlApplicationTicket *newTicket = [[GrowlApplicationTicket alloc] initWithContentsOfFile:filename];
			if (newTicket) {
				NSString *applicationName = [newTicket applicationName];

				/*if we haven't already loaded a ticket for this application,
				 *	or if we're clobbering already-loaded tickets,
				 *	set this ticket in the dictionary.
				 */
				if (clobber || ![dict objectForKey:applicationName])
					[dict setObject:newTicket forKey:applicationName];

				[newTicket release];
			}
		}
	}
}
- (void) loadAllSavedTickets {
//	NSDate *start, *end; //TEMP
//	start = [NSDate date]; //TEMP

	//XXX use GrowlPathUtil here.
	NSArray *ticketDirs = [GrowlPathUtil searchPathForDirectory:GrowlTicketsDirectory inDomains:NSAllDomainsMask];
	NSEnumerator *ticketDirEnum = [ticketDirs objectEnumerator];
	NSString *ticketPath;
	ticketsByApplicationName = [[NSMutableDictionary alloc] init];

	while ((ticketPath = [ticketDirEnum nextObject])) {
		/*the search paths are returned in the order we should search in, so
		 *	earlier results should take priority. thus, clobbering:NO.
		 */
		[self loadTicketsFromDirectory:ticketPath
						intoDictionary:ticketsByApplicationName
							clobbering:NO];
	}

//	end = [NSDate date]; //TEMP
//	NSLog(@"Got all saved tickets in %f seconds", [end timeIntervalSinceDate:start]); //TEMP

	return ticketsByApplicationName;
}

#pragma mark -
#pragma mark Public methods

- (NSDictionary *) allSavedTickets {
	return [[ticketsByApplicationName copy] autorelease];
}

- (GrowlApplicationTicket *) ticketForApplicationName:(NSString *)appName {
	return [ticketsByApplicationName objectForKey:appName];
}
- (void) addTicket:(GrowlApplicationTicket *) newTicket {
	NSString *appName = [newTicket applicationName];
	if (!appName)
		NSLog(@"GrowlTicketController: cannot add ticket because it has no application name (description follows)\n%@", newTicket);
	else {
		[ticketsByApplicationName setObject:newTicket forKey:appName];
		//XXX this here is pretty barftastic. what about tickets that already have a path? should we clobber the existing path? create a copy? leave it alone, as now? --boredzo
		if (![newTicket path])
			[newTicket setPath:[GrowlPathUtil defaultSavePathForTicketWithApplicationName:appName]];
		[newTicket synchronize];
	}
}

@end
