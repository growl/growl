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

static void PerformSwizzle(Class aClass, SEL orig_sel, SEL alt_sel, BOOL forInstance)
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
			NSLog(@"GrowlSafari Error: Original %@, Alternate %@",
				  (orig_method == nil) ? @" not found" : @" found",
				  (alt_method == nil) ? @" not found" : @" found");
		}
	} else {
		NSLog(@"GrowlSafari Error: Class not found");
	}
}

@implementation GrowlSafari
+ (NSBundle *)bundle
{
	return( [NSBundle bundleForClass:self] );
}

+ (void)initialize
{
	//NSLog(@"Patching DownloadProgressEntry...");
	Class class = NSClassFromString( @"DownloadProgressEntry" );
	PerformSwizzle( class, @selector(setDownloadStage:), @selector(mySetDownloadStage:), YES );
	PerformSwizzle( class, @selector(updateDiskImageStatus:), @selector(myUpdateDiskImageStatus:), YES );
	NSBundle *bundle = [GrowlSafari bundle];
	NSArray *array = [NSArray arrayWithObjects:
		NSLocalizedStringFromTableInBundle(@"Download Complete", nil, bundle, @""),
		NSLocalizedStringFromTableInBundle(@"Disk Image Status", nil, bundle, @""),
		NSLocalizedStringFromTableInBundle(@"Compression Status", nil, bundle, @""),
		nil];
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
- (void) mySetDownloadStage:(int)stage
{
	int oldStage = (int)[self performSelector:@selector(downloadStage)];
	[self mySetDownloadStage:stage];
	if (stage == 2) {
		NSDistributedNotificationCenter *nc = [NSDistributedNotificationCenter defaultCenter];
		NSBundle *bundle = [GrowlSafari bundle];
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
			@"GrowlSafari", GROWL_APP_NAME,
			NSLocalizedStringFromTableInBundle(@"Compression Status", nil, bundle, @""), GROWL_NOTIFICATION_NAME,
			NSLocalizedStringFromTableInBundle(@"Decompressing File", nil, bundle, @""), GROWL_NOTIFICATION_TITLE,
			[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ decompression started", nil, bundle, @""),
					[[self performSelector:@selector(downloadPath)] lastPathComponent]],
				GROWL_NOTIFICATION_DESCRIPTION,
			nil];
		[nc postNotificationName:GROWL_NOTIFICATION	object:nil userInfo:dict];
	} else if (stage == 9 && oldStage != 9) {
		NSDistributedNotificationCenter *nc = [NSDistributedNotificationCenter defaultCenter];
		NSBundle *bundle = [GrowlSafari bundle];
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
			@"GrowlSafari", GROWL_APP_NAME,
			NSLocalizedStringFromTableInBundle(@"Disk Image Status", nil, bundle, @""), GROWL_NOTIFICATION_NAME,
			NSLocalizedStringFromTableInBundle(@"Copying Disk Image", nil, bundle, @""), GROWL_NOTIFICATION_TITLE,
			[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Copying application from %@", nil, bundle, @""),
					[[self performSelector:@selector(downloadPath)] lastPathComponent]],
				GROWL_NOTIFICATION_DESCRIPTION,
			nil];
		[nc postNotificationName:GROWL_NOTIFICATION object:nil userInfo:dict];
	} else if (stage == 13) {
		NSDistributedNotificationCenter *nc = [NSDistributedNotificationCenter defaultCenter];
		NSBundle *bundle = [GrowlSafari bundle];
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
			@"GrowlSafari", GROWL_APP_NAME,
			NSLocalizedStringFromTableInBundle(@"Download Complete", nil, bundle, @""), GROWL_NOTIFICATION_NAME,
			NSLocalizedStringFromTableInBundle(@"Download Complete", nil, bundle, @""), GROWL_NOTIFICATION_TITLE,
			[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ download complete", nil, bundle, @""),
					[self performSelector:@selector(filename)]],
				GROWL_NOTIFICATION_DESCRIPTION,
			nil];
		[nc postNotificationName:GROWL_NOTIFICATION object:nil userInfo:dict];
	}
}

- (void)myUpdateDiskImageStatus:(NSDictionary *)status
{
	[self myUpdateDiskImageStatus:status];

	if( [[status objectForKey:@"status-stage"] isEqual:@"initialize"] ) {
		NSBundle *bundle = [GrowlSafari bundle];
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
			@"GrowlSafari", GROWL_APP_NAME,
			NSLocalizedStringFromTableInBundle(@"Disk Image Status", nil, bundle, @""), GROWL_NOTIFICATION_NAME,
			NSLocalizedStringFromTableInBundle(@"Mounting Disk Image", nil, bundle, @""), GROWL_NOTIFICATION_TITLE,
			[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Mounting %@", nil, bundle, @""),
				[[self performSelector:@selector(downloadPath)] lastPathComponent]],
			GROWL_NOTIFICATION_DESCRIPTION,
			nil];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION
																	   object:nil
																	 userInfo:dict];
	}
}
@end
