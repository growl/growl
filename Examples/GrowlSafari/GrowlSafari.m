//
//  GrowlSafari.m
//  GrowlSafari
//
//  Created by Kevin Ballard on 10/29/04.
//  Copyright 2004 Kevin Ballard. All rights reserved.
//

#import "GrowlSafari.h"
#import "GrowlDefines.h"
#import <objc/objc-runtime.h>

// Using method swizzling as outlined here:
// http://www.cocoadev.com/index.pl?MethodSwizzling
// A couple of modifications made to support swizzling class methods

void PerformSwizzle(Class aClass, SEL orig_sel, SEL alt_sel, BOOL forInstance)
{
    // First, make sure the class isn't nil
	if (aClass != nil) {
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
		if ((orig_method != nil) && (alt_method != nil)) {
			IMP temp;
			
			temp = orig_method->method_imp;
			orig_method->method_imp = alt_method->method_imp;
			alt_method->method_imp = temp;
		} else {
			// This bit stolen from SubEthaFari's source
			NSLog(@"SafariSource Error: Original %@, Alternate %@",(orig_method == nil)?@" not found":@" found",(alt_method == nil)?@" not found":@" found");
		}
	} else {
		NSLog(@"SafariSource Error: Class not found");
	}
}

void MethodSwizzle(Class aClass, SEL orig_sel, SEL alt_sel)
{
	PerformSwizzle(aClass, orig_sel, alt_sel, YES);
}

void ClassMethodSwizzle(Class aClass, SEL orig_sel, SEL alt_sel)
{
	PerformSwizzle(aClass, orig_sel, alt_sel, NO);
}

@implementation GrowlSafari
+ (void) initialize {
	NSLog(@"Patching DownloadProgressEntry...");
	MethodSwizzle(NSClassFromString(@"DownloadProgressEntry"), @selector(setDownloadStage:), @selector(mySetDownloadStage:));
	MethodSwizzle(NSClassFromString(@"DownloadProgressEntry"), @selector(updateDiskImageStatus:), @selector(myUpdateDiskImageStatus:));
	NSArray *array = [NSArray arrayWithObjects:@"Download Complete", @"Disk Image Status", @"Compression Status", nil];
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
		@"GrowlSafari", GROWL_APP_NAME,
		[[NSImage imageNamed:@"NSApplicationIcon"] TIFFRepresentation], GROWL_APP_ICON,
		array, GROWL_NOTIFICATIONS_DEFAULT,
		array, GROWL_NOTIFICATIONS_ALL,
		nil];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_APP_REGISTRATION
																	object:nil userInfo:dict];
	[super initialize];
}
@end

@implementation NSObject (GrowlSafariPatch)
- (void) mySetDownloadStage:(int)stage {
	int oldStage = (int)[self performSelector:@selector(downloadStage)];
	[self mySetDownloadStage:stage];
	NSDistributedNotificationCenter *nc = [NSDistributedNotificationCenter defaultCenter];
	if (stage == 2) {
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
			@"GrowlSafari", GROWL_APP_NAME,
			@"Compression Status", GROWL_NOTIFICATION_NAME,
			@"Decompressing File", GROWL_NOTIFICATION_TITLE,
			[NSString stringWithFormat:@"%@ decompression started",
					[[self performSelector:@selector(downloadPath)] lastPathComponent]],
				GROWL_NOTIFICATION_DESCRIPTION,
			nil];
		[nc postNotificationName:GROWL_NOTIFICATION	object:nil userInfo:dict];
	} else if (stage == 9 && oldStage != 9) {
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
			@"GrowlSafari", GROWL_APP_NAME,
			@"Disk Image Status", GROWL_NOTIFICATION_NAME,
			@"Copying Disk Image", GROWL_NOTIFICATION_TITLE,
			[NSString stringWithFormat:@"Copying application from %@",
					[[self performSelector:@selector(downloadPath)] lastPathComponent]],
				GROWL_NOTIFICATION_DESCRIPTION,
			nil];
		[nc postNotificationName:GROWL_NOTIFICATION object:nil userInfo:dict];
	} else if (stage == 13) {
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
			@"GrowlSafari", GROWL_APP_NAME,
			@"Download Complete", GROWL_NOTIFICATION_NAME,
			@"Download Complete", GROWL_NOTIFICATION_TITLE,
			[NSString stringWithFormat:@"%@ download complete", 
					[self performSelector:@selector(filename)]],
				GROWL_NOTIFICATION_DESCRIPTION,
			nil];
		[nc postNotificationName:GROWL_NOTIFICATION object:nil userInfo:dict];
	}
}

- (void)myUpdateDiskImageStatus:(id)fp8 {
	[self myUpdateDiskImageStatus:fp8];
	if ([[fp8 objectForKey:@"status-stage"] isEqual:@"initialize"]) {
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
			@"GrowlSafari", GROWL_APP_NAME,
			@"Disk Image Status", GROWL_NOTIFICATION_NAME,
			@"Mounting Disk Image", GROWL_NOTIFICATION_TITLE,
			[NSString stringWithFormat:@"Mounting %@",
				[[self performSelector:@selector(downloadPath)] lastPathComponent]],
			GROWL_NOTIFICATION_DESCRIPTION,
			nil];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION
																	   object:nil
																	 userInfo:dict];
	}
}
@end
