//
//  GrowlPathUtil.m
//  Growl
//
//  Created by Ingmar Stein on 17.04.05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "GrowlPathUtilities.h"
#import "GrowlDefinesInternal.h"

#define NAME_OF_TICKETS_DIRECTORY               @"Tickets"
#define NAME_OF_PLUGINS_DIRECTORY               @"Plugins"

@implementation GrowlPathUtilities

#pragma mark Bundles

//Searches the process list (as yielded by GetNextProcess) for a process with the given bundle identifier.
//Returns the oldest matching process.
+ (NSBundle *) bundleForProcessWithBundleIdentifier:(NSString *)identifier
{
   NSArray *possibilities = [NSRunningApplication runningApplicationsWithBundleIdentifier:identifier];
   if([possibilities count] > 0){
      //NSLog(@"Found %lu applications for identifier %@", [possibilities count], identifier);
      NSRunningApplication *oldest = nil;
      for(NSRunningApplication *app in possibilities){
         if(!oldest || [[oldest launchDate] compare:[app launchDate]] == NSOrderedDescending)
            oldest = app;
      }
      if(oldest)
         return [NSBundle bundleWithURL:[oldest bundleURL]];
   }
   return nil;
}

//Obtains the bundle for the active GrowlHelperApp process. Returns nil if there is no such process.
+ (NSBundle *) runningHelperAppBundle {
	return [self bundleForProcessWithBundleIdentifier:GROWL_HELPERAPP_BUNDLE_IDENTIFIER];
}

#pragma mark -
#pragma mark Directories

+ (NSArray *) searchPathForDirectory:(GrowlSearchPathDirectory) directory inDomains:(GrowlSearchPathDomainMask) domainMask mustBeWritable:(BOOL)flag {
	if (directory < GrowlSupportDirectory) {
		NSArray *searchPath = NSSearchPathForDirectoriesInDomains(directory, domainMask, /*expandTilde*/ YES);
		if (!flag)
			return searchPath;
		else {
			//flag is not NO: exclude non-writable directories.
			NSMutableArray *result = [NSMutableArray arrayWithCapacity:[searchPath count]];
			NSFileManager *mgr = [NSFileManager defaultManager];

			for (NSString *dir in searchPath) {
				if ([mgr isWritableFileAtPath:dir])
					[result addObject:dir];
			}

			return result;
		}
	} else {
		//determine what to append to each Application Support folder.
		NSString *subpath = nil;
		switch (directory) {
			case GrowlSupportDirectory:
				//do nothing.
				break;
				
			case GrowlTicketsDirectory:
				subpath = NAME_OF_TICKETS_DIRECTORY;
				break;

			case GrowlPluginsDirectory:
				subpath = NAME_OF_PLUGINS_DIRECTORY;
				break;

			default:
				NSLog(@"ERROR: GrowlPathUtil was asked for directory 0x%x, but it doesn't know what directory that is. Please tell the Growl developers.", directory);
				return nil;
		}
		if (subpath)
			subpath = [@"Application Support/Growl" stringByAppendingPathComponent:subpath];
		else
			subpath =  @"Application Support/Growl";

		/*get the search path, and append the subpath to all the items therein.
		 *exclude results that don't exist.
		 */
		NSFileManager *mgr = [NSFileManager defaultManager];
		BOOL isDir = NO;

		NSArray *searchPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, domainMask, /*expandTilde*/ YES);
		NSMutableArray *mSearchPath = [NSMutableArray arrayWithCapacity:[searchPath count]];
		for (NSString *path in searchPath) {
			path = [path stringByAppendingPathComponent:subpath];
			if ([mgr fileExistsAtPath:path isDirectory:&isDir] && isDir)
				[mSearchPath addObject:path];
		}

		return mSearchPath;
	}
}

+ (NSArray *) searchPathForDirectory:(GrowlSearchPathDirectory) directory inDomains:(GrowlSearchPathDomainMask) domainMask {
	//NO to emulate the default NSSearchPathForDirectoriesInDomains behaviour.
	return [self searchPathForDirectory:directory inDomains:domainMask mustBeWritable:NO];
}

+ (NSString *) growlSupportDirectory {
	NSArray *searchPath = [self searchPathForDirectory:GrowlSupportDirectory inDomains:NSUserDomainMask mustBeWritable:YES];
	if ([searchPath count])
		return [searchPath objectAtIndex:0U];
	else {
		NSString *path = nil;

		//if this doesn't return any writable directories, path will still be nil.
		searchPath = [self searchPathForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask mustBeWritable:YES];
		if ([searchPath count]) {
			path = [[searchPath objectAtIndex:0U] stringByAppendingPathComponent:@"Application Support/Growl"];
			//try to create it. if that doesn't work, don't return it. return nil instead.
			if (![[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil])
				path = nil;
		}

		return path;
	}
}

+ (NSString *) ticketsDirectory {
	NSArray *searchPath = [self searchPathForDirectory:GrowlTicketsDirectory inDomains:NSUserDomainMask mustBeWritable:YES];
	if ([searchPath count])
		return [searchPath objectAtIndex:0U];
	else {
		NSString *path = nil;

		//if this doesn't return any writable directories, path will still be nil.
		path = [self growlSupportDirectory];
		if (path) {
			path = [path stringByAppendingPathComponent:NAME_OF_TICKETS_DIRECTORY];
			//try to create it. if that doesn't work, don't return it. return nil instead.
			if (![[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil])
				path = nil;
		}

		return path;
	}
}

#pragma mark -
#pragma mark Tickets

+ (NSString *) defaultSavePathForTicketWithApplicationName:(NSString *) appName {
	return [[self ticketsDirectory] stringByAppendingPathComponent:[appName stringByAppendingPathExtension:GROWL_PATHEXTENSION_TICKET]];
}

@end
