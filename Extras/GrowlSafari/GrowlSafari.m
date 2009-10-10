/*
 Copyright (c) The Growl Project, 2004-2009
 All rights reserved.


 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:


 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 3. Neither the name of Growl nor the names of its contributors
 may be used to endorse or promote products derived from this software
 without specific prior written permission.


 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 */

//
//  GrowlSafari.m
//  GrowlSafari
//
//  Created by Kevin Ballard on 10/29/04.
//  Copyright 2004 Kevin Ballard. All rights reserved.
//

#import "GrowlSafari.h"
//#import "GSWebBookmark.h"
#import <Growl/Growl.h>
#import <objc/objc-runtime.h>
#include <dlfcn.h>

//Note: As of Safari 4.0.x, the build number comes across as four digits (in decimal). The last three are the actual build number; the first one is the minor version of the OS target of that build.
//Thus, Safari 4.0 for Tiger is 4530, and Safari 4.0 for Leopard is 5530. We check the components separately, so the value here is only the pure-build-number part of the number.
//(Note: Remember to abolish that if the real build number ever goes above 1000!)
#define SAFARI_VERSION_4_0 530

enum GrowlSafariTigerConstants {
	GrowlSafariTigerDownloadStageActive = 1,
	GrowlSafariTigerDownloadStageDecompressing = 2,
	GrowlSafariTigerDownloadStageDiskImagePreparing = 4,
	GrowlSafariTigerDownloadStageDiskImageVerifying = 7,
	GrowlSafariTigerDownloadStageDiskImageVerified = 8,
	GrowlSafariTigerDownloadStageDiskImageMounting = 9,
	GrowlSafariTigerDownloadStageDiskImageCleanup = 12,
	GrowlSafariTigerDownloadStageInactive = 15,
	GrowlSafariTigerDownloadStageFinished = 16
};
enum GrowlSafariLeopardConstants {
	GrowlSafariLeopardDownloadStageActive = 1,
	GrowlSafariLeopardDownloadStageDecompressing = 2,
	GrowlSafariLeopardDownloadStageDiskImagePreparing = 4,
	GrowlSafariLeopardDownloadStageDiskImageVerifying = 7,
	GrowlSafariLeopardDownloadStageDiskImageVerified = 8,
	GrowlSafariLeopardDownloadStageDiskImageMounting = 9,
	GrowlSafariLeopardDownloadStageDiskImageCleanup = 12,
	GrowlSafariLeopardDownloadStageInactive = 13,
	GrowlSafariLeopardDownloadStageFinished = 14
};

//These default to the Leopard constants, but we redefine them to the Tiger constants in +initialize if we're running on Tiger.
static int GrowlSafariDownloadStageActive = GrowlSafariLeopardDownloadStageActive;
static int GrowlSafariDownloadStageDecompressing = GrowlSafariLeopardDownloadStageDecompressing;
static int GrowlSafariDownloadStageDiskImagePreparing = GrowlSafariLeopardDownloadStageDiskImagePreparing;
static int GrowlSafariDownloadStageDiskImageVerifying = GrowlSafariLeopardDownloadStageDiskImageVerifying;
static int GrowlSafariDownloadStageDiskImageVerified = GrowlSafariLeopardDownloadStageDiskImageVerified;
static int GrowlSafariDownloadStageDiskImageMounting = GrowlSafariLeopardDownloadStageDiskImageMounting;
static int GrowlSafariDownloadStageDiskImageCleanup = GrowlSafariLeopardDownloadStageDiskImageCleanup;
static int GrowlSafariDownloadStageInactive = GrowlSafariLeopardDownloadStageInactive;
static int GrowlSafariDownloadStageFinished = GrowlSafariLeopardDownloadStageFinished;

// How long should we wait (in seconds) before it's a long download?
static double longDownload = 15.0;
static int safariVersion;
static NSMutableDictionary *dates = nil;

int writeWithFormatAndArgs(FILE *file, NSString *format, va_list args);
int writeWithFormat(FILE *file, NSString *format, ...);

int writeWithFormatAndArgs(FILE *file, NSString *format, va_list args) {
    return 0;
	return fprintf(file, "%s\n", [[[[NSString alloc] initWithFormat:format arguments:args] autorelease] UTF8String]);
}

int writeWithFormat(FILE *file, NSString *format, ...) {
    va_list args;
    va_start(args, format);
    int written = writeWithFormatAndArgs(file, format, args);
    va_end(args);
    return written;
}

// Using method swizzling as outlined here:
// http://www.cocoadev.com/index.pl?MethodSwizzling
// A couple of modifications made to support swizzling class methods

static BOOL PerformSwizzle(Class aClass, SEL orig_sel, SEL alt_sel, BOOL forInstance) {
    // First, make sure the class isn't nil
	if (aClass) {
		Method orig_method = nil, alt_method = nil;

		// Next, look for the methods
		if (forInstance) {
			orig_method = class_getInstanceMethod(aClass, orig_sel);
			alt_method = class_getInstanceMethod(aClass, alt_sel);
		} else {
			orig_method = class_getClassMethod(aClass, orig_sel);
			alt_method = class_getClassMethod(aClass, alt_sel);
		}

		// If both are found, swizzle them
		if (orig_method && alt_method) {
			method_exchangeImplementations(orig_method, alt_method);

			return YES;
		} else {
			// This bit stolen from SubEthaFari's source
			NSLog(@"GrowlSafari Error: Original (selector %s) %@, Alternate (selector %s) %@",
				  orig_sel,
				  orig_method ? @"was found" : @"not found",
				  alt_sel,
				  alt_method ? @"was found" : @"not found");
		}
	} else {
		NSLog(@"%@", @"GrowlSafari Error: No class to swizzle methods in");
	}

	return NO;
}

static void setDownloadStarted(id dl) {
	if (!dates)
		dates = [[NSMutableDictionary alloc] init];

	[dates setObject:[NSDate date] forKey:[dl identifier]];
}

static NSDate *dateStarted(id dl) {
	if (dates)
		return [dates objectForKey:[dl identifier]];

	return nil;
}

static BOOL isLongDownload(id dl) {
	NSDate *date = dateStarted(dl);
	return (date && -[date timeIntervalSinceNow] > longDownload);
}

static void setDownloadFinished(id dl) {
	[dates removeObjectForKey:[dl identifier]];
}

@implementation GrowlSafari
+ (NSBundle *) bundle {
	return [NSBundle bundleForClass:[GrowlSafari class]];
}

+ (NSString *) bundleVersion {
	return [[[GrowlSafari bundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
}

+ (void) load {
	FILE *logfile = nil;//fopen("/tmp/GrowlSafari.log", "w");
	writeWithFormat(logfile, @"%s", __PRETTY_FUNCTION__);
	
	NSString *growlPath = [[[[GrowlSafari bundle] privateFrameworksPath] stringByAppendingPathComponent:@"Growl.framework"] stringByAppendingPathComponent:@"Growl"];

	void *result = nil;
	result = dlopen([growlPath fileSystemRepresentation], RTLD_LAZY);
	writeWithFormat(logfile, @"%p %@", result, growlPath);
	if (result) {

		// Register ourselves as a Growl delegate
		[NSClassFromString(@"GrowlApplicationBridge") setGrowlDelegate:self];
		
		safariVersion = [[[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey] intValue];
		writeWithFormat(logfile, @"Safari Version: %d",safariVersion);
		
		if (safariVersion >= SAFARI_VERSION_4_0) {
			//	NSLog(@"Patching DownloadProgressEntry...");
			Class class = NSClassFromString(@"DownloadProgressEntry");
			writeWithFormat(logfile, @"setDownloadStage: %d", PerformSwizzle(class, @selector(setDownloadStage:), @selector(mySetDownloadStage:), YES));
					
			writeWithFormat(logfile, @"_updateDiskImageStatus: %d", PerformSwizzle(class, @selector(_updateDiskImageStatus:), @selector(myUpdateDiskImageStatus:), YES));
			
			writeWithFormat(logfile, @"initWithDownload:mayOpenWhenDone:allowOverwrite: %d", PerformSwizzle(class, @selector(initWithDownload:mayOpenWhenDone:allowOverwrite:),
						   @selector(myInitWithDownload:mayOpenWhenDone:allowOverwrite:),
						   YES));
			
			Class webBookmarkClass = NSClassFromString(@"WebBookmark");
			if (webBookmarkClass)
			{
				writeWithFormat(logfile, @"setUnreadRSSCount: %d", PerformSwizzle(webBookmarkClass, @selector(setUnreadRSSCount:), @selector(swizzled_setUnreadRSSCount:), YES));
			}
			//As explained above, safariVersion / 1000 = minor version of targeted Mac OS X version.
			int operatingSystemTargetOfSafari = (safariVersion / 1000);
			BOOL tigerVersionOfSafari = (operatingSystemTargetOfSafari == 4);
			if (tigerVersionOfSafari) {
				GrowlSafariDownloadStageActive = GrowlSafariTigerDownloadStageActive; 
				GrowlSafariDownloadStageDecompressing = GrowlSafariTigerDownloadStageDecompressing;
				GrowlSafariDownloadStageDiskImagePreparing = GrowlSafariTigerDownloadStageDiskImagePreparing;
				GrowlSafariDownloadStageDiskImageVerifying = GrowlSafariTigerDownloadStageDiskImageVerifying;
				GrowlSafariDownloadStageDiskImageVerified = GrowlSafariTigerDownloadStageDiskImageVerified;
				GrowlSafariDownloadStageDiskImageMounting = GrowlSafariTigerDownloadStageDiskImageMounting;
				GrowlSafariDownloadStageDiskImageCleanup = GrowlSafariTigerDownloadStageDiskImageCleanup;
				GrowlSafariDownloadStageInactive = GrowlSafariTigerDownloadStageInactive;
				GrowlSafariDownloadStageFinished = GrowlSafariTigerDownloadStageFinished;
			}

			NSDictionary *infoDictionary = [NSClassFromString(@"GrowlApplicationBridge") frameworkInfoDictionary];
			writeWithFormat(logfile, @"Loaded GrowlSafari %@", [GrowlSafari bundleVersion]);
			writeWithFormat(logfile, @"Using Growl.framework %@ (%@)",
				  [infoDictionary objectForKey:@"CFBundleShortVersionString"],
				  [infoDictionary objectForKey:(NSString *)kCFBundleVersionKey]);
		} else {
			writeWithFormat(logfile, @"Safari too old (4.0 required); GrowlSafari disabled.");
		}
	} else {
		writeWithFormat(logfile, @"Could not load Growl.framework, GrowlSafari disabled");
	}
	//fclose(logfile);	
}

#pragma mark GrowlApplicationBridge delegate methods

+ (NSString *) applicationNameForGrowl {
	return @"GrowlSafari";
}

+ (NSImage *) applicationIconForGrowl {
	return [NSImage imageNamed:@"NSApplicationIcon"];
}

+ (NSDictionary *) registrationDictionaryForGrowl {
	NSBundle *bundle = [GrowlSafari bundle];
	NSArray *array = [[NSArray alloc] initWithObjects:
		NSLocalizedStringFromTableInBundle(@"Short Download Complete", nil, bundle, @""),
		NSLocalizedStringFromTableInBundle(@"Download Complete", nil, bundle, @""),
		NSLocalizedStringFromTableInBundle(@"Disk Image Status", nil, bundle, @""),
		NSLocalizedStringFromTableInBundle(@"Compression Status", nil, bundle, @""),
		NSLocalizedStringFromTableInBundle(@"New feed entry", nil, bundle, @""),
		nil];
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
		array, GROWL_NOTIFICATIONS_DEFAULT,
		array, GROWL_NOTIFICATIONS_ALL,
		nil];
	[array release];

	return dict;
}

+ (void) growlNotificationWasClicked:(id)clickContext {
	NSURL *url = [[NSURL alloc] initWithString:clickContext];
	[[NSWorkspace sharedWorkspace] openURL:url];
	[url release];
}

+ (void) notifyRSSUpdate:(id)bookmark newEntries:(int)newEntries {
	NSBundle *bundle = [GrowlSafari bundle];
	NSMutableString	*description = [[NSMutableString alloc]
		initWithFormat:newEntries == 1 ? NSLocalizedStringFromTableInBundle(@"%d new entry", nil, bundle, @"") : NSLocalizedStringFromTableInBundle(@"%d new entries", nil, bundle, @""),
		newEntries,
		[bookmark unreadRSSCount]];
	if (newEntries != [bookmark unreadRSSCount])
		[description appendFormat:NSLocalizedStringFromTableInBundle(@" (%d unread)", nil, bundle, @""), [bookmark unreadRSSCount]];

	NSString *title = [bookmark title];
	[NSClassFromString(@"GrowlApplicationBridge") notifyWithTitle:(title ? title : [bookmark URLString])
								description:description
						   notificationName:NSLocalizedStringFromTableInBundle(@"New feed entry", nil, bundle, @"")
								   iconData:nil
								   priority:0
								   isSticky:NO
							   clickContext:[bookmark URLString]];
	[description release];
}
@end

@implementation NSObject (GrowlSafariPatch)

- (void) swizzled_setUnreadRSSCount:(int)newUnreadCount  {
	int oldRSSCount = [self unreadRSSCount];
	[self swizzled_setUnreadRSSCount:newUnreadCount];
	
	if ([self isRSSBookmark] && [[self URLString] hasPrefix:@"feed:"] && oldRSSCount < newUnreadCount) {
		[GrowlSafari notifyRSSUpdate:self newEntries:newUnreadCount - oldRSSCount];
	}
}

- (void) mySetDownloadStage:(int)stage {
	FILE *logfile = nil;//fopen("/tmp/GrowlSafari.log", "a");
	writeWithFormat(logfile, @"%s", __PRETTY_FUNCTION__);
	//int oldStage = [self downloadStage];
	//fclose(logfile);
	//NSLog(@"mySetDownloadStage:%d -> %d", oldStage, stage);
	[self mySetDownloadStage:stage];
	if (dateStarted(self)) {
		if ( stage == GrowlSafariDownloadStageDecompressing ) {
			NSBundle *bundle = [GrowlSafari bundle];
			NSString *description = [[NSString alloc] initWithFormat:
				NSLocalizedStringFromTableInBundle(@"%@", nil, bundle, @""),
				[[self gsDownloadPath] lastPathComponent]];
			[NSClassFromString(@"GrowlApplicationBridge") notifyWithTitle:NSLocalizedStringFromTableInBundle(@"Decompressing File", nil, bundle, @"")
										description:description
								   notificationName:NSLocalizedStringFromTableInBundle(@"Compression Status", nil, bundle, @"")
										   iconData:nil
										   priority:0
										   isSticky:NO
									   clickContext:nil];
			[description release];
		} else if ( stage == GrowlSafariDownloadStageDiskImageVerifying ) {
			NSBundle *bundle = [GrowlSafari bundle];
			NSString *description = [[NSString alloc] initWithFormat:
									 NSLocalizedStringFromTableInBundle(@"%@", nil, bundle, @""),
									 [[self gsDownloadPath] lastPathComponent]];
			[NSClassFromString(@"GrowlApplicationBridge") notifyWithTitle:NSLocalizedStringFromTableInBundle(@"Verifying Disk Image", nil, bundle, @"")
										description:description
								   notificationName:NSLocalizedStringFromTableInBundle(@"Disk Image Status", nil, bundle, @"")
										   iconData:nil
										   priority:0
										   isSticky:NO
									   clickContext:nil];
			[description release];
		} else if ( stage == GrowlSafariDownloadStageFinished ) {
			NSBundle *bundle = [GrowlSafari bundle];
			NSString *notificationName = isLongDownload(self) ? NSLocalizedStringFromTableInBundle(@"Download Complete", nil, bundle, @"") : NSLocalizedStringFromTableInBundle(@"Short Download Complete", nil, bundle, @"");
			setDownloadFinished(self);
			NSString *description = [[NSString alloc] initWithFormat:
				NSLocalizedStringFromTableInBundle(@"%@", nil, bundle, "Message shown when a download is complete, where %@ becomes the filename"),
				[self filename]];
			[NSClassFromString(@"GrowlApplicationBridge") notifyWithTitle:NSLocalizedStringFromTableInBundle(@"Download Complete", nil, bundle, @"")
										description:description
								   notificationName:notificationName
										   iconData:nil
										   priority:0
										   isSticky:NO
									   clickContext:nil];
			[description release];
		}
	} else if (stage == GrowlSafariDownloadStageActive) {
		setDownloadStarted(self);
	}
}

- (void) myUpdateDiskImageStatus:(NSDictionary *)status {
	FILE *logfile = nil;//fopen("/tmp/GrowlSafari.log", "a");
	writeWithFormat(logfile, @"%s", __PRETTY_FUNCTION__);
	//fclose(logfile);
	int oldStage = [self downloadStage];
	[self myUpdateDiskImageStatus:status];
	//NSLog(@"myUpdateDiskImageStatus:%@ stage=%d -> %d", status, oldStage, [self downloadStage]);

	if (dateStarted(self)
			&& oldStage == GrowlSafariDownloadStageDiskImageVerified
			&& [self downloadStage] == GrowlSafariDownloadStageDiskImageMounting
			&& [[status objectForKey:@"status-stage"] isEqualToString:@"attach"]) {
		NSBundle *bundle = [GrowlSafari bundle];
		NSString *description = [[NSString alloc] initWithFormat:
			NSLocalizedStringFromTableInBundle(@"%@", nil, bundle, @""),
			[[self gsDownloadPath] lastPathComponent]];
		[NSClassFromString(@"GrowlApplicationBridge") notifyWithTitle:NSLocalizedStringFromTableInBundle(@"Mounting Disk Image", nil, bundle, @"")
									description:description
							   notificationName:NSLocalizedStringFromTableInBundle(@"Disk Image Status", nil, bundle, @"")
									   iconData:nil
									   priority:0
									   isSticky:NO
								   clickContext:nil];
		[description release];
	}
}

// This is to make sure we're done with the pre-saved downloads
- (id) myInitWithDownload:(id)fp8 mayOpenWhenDone:(BOOL)fp12 allowOverwrite:(BOOL)fp16 {
	FILE *logfile = nil;//fopen("/tmp/GrowlSafari.log", "a");
	writeWithFormat(logfile, @"%s", __PRETTY_FUNCTION__);
	//fclose(logfile);
	id retval = [self myInitWithDownload:fp8 mayOpenWhenDone:fp12 allowOverwrite:fp16];
	setDownloadStarted(self);
	return retval;
}

- (NSString*) gsDownloadPath {
	return [self currentPath];
}

@end
