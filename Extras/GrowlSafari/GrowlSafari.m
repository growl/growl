//
//  GrowlSafari.m
//  GrowlSafari
//
//  Created by Peter Hosey on 2008-05-12.
//  Copyright 2008 The Growl Project. All rights reserved.
//

#import "GrowlSafari.h"

@implementation GrowlSafari

- (void)webPlugInInitialize {
	[GrowlApplicationBridge setGrowlDelegate:self];
	
	NSLog(@"In A.D. 2101, war was beginning.");
}

- (void)webPlugInStart {
	//TEMP: Sign up for any notification, so that we can find out what NSNotifications we need to observe for and notify about.
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(anyNotificationPosted:)
												 name:nil
											   object:nil];

	NSString *logFilePath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, /*expandTilde*/ YES) objectAtIndex:0U] stringByAppendingPathComponent:@"Safari_notifications.log"];
	//Create the file, if it doesn't already exist.
	[[NSFileManager defaultManager] createFileAtPath:logFilePath contents:[NSData data] attributes:nil];
	logFile = [[NSFileHandle fileHandleForUpdatingAtPath:logFilePath] retain];
	[logFile seekToEndOfFile];

	NSLog(@"GrowlSafari started, for great justice");
}

- (void)webPlugInStop {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	NSLog(@"GrowlSafari stopped. What you say!!");
}

#pragma mark NSNotification handlers

//TEMP: Log all notifications, so that we can find out what NSNotifications we need to observe for and notify about.
- (void) anyNotificationPosted:(NSNotification *)notification {
	FILE *logFileStream = fdopen([logFile fileDescriptor], "a");
	fputs("--------------------------------------------------------------------------------\n", logFileStream);
	fprintf(logFileStream, "Date: %s\n", [[[NSDate date] descriptionInStringsFileFormat] UTF8String]);
	fprintf(logFileStream, "Name: %s\n", [[notification name] UTF8String]);
	fprintf(logFileStream, "Object: %s\n", [[[notification object] description] UTF8String]);
	fprintf(logFileStream, "User-info: %s\n", [[[notification userInfo] description] UTF8String]);
	fclose(logFileStream);
}

#pragma mark Growl delegate conformance

- (NSDictionary *) registrationDictionaryForGrowl {
	return [NSDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"GrowlSafari" ofType:@"growlRegDict"]];
}

- (void) growlNotificationWasClicked:(id)clickContext {
	if (clickContext && [clickContext isKindOfClass:[NSString class]]) {
		NSString *string = clickContext;
		if ([[NSFileManager defaultManager] fileExistsAtPath:string]) {
			NSString *path = string;
			[[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:[path stringByDeletingLastPathComponent]];
		}
	}
}

@end
