//
//  VolumeNotifier.c
//  HardwareGrowler
//
//  Created by Diggory Laycock on 10/02/2005.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "VolumeNotifier.h"
#import "AppController.h"
//#include "CFGrowlAdditions.h"

// wait 10 minutes for a corresponding did unmount notification
#define VolumeNotifierUnmountWaitSeconds	600.0
#define VolumeEjectCacheInfoIndex			0
#define VolumeEjectCacheTimerIndex			1

static NSMutableDictionary *ejectCache = nil;

#pragma mark Icons

static NSImage *ejectIconImage(void)
{
	//Named with an underscore to prevent name conflict with the function. Be aware of which one you use here.
	static NSImage *_ejectIconImage = nil;
	
	if (!_ejectIconImage) {
		_ejectIconImage = [[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kEjectMediaIcon)] retain];
	}
	
	return _ejectIconImage;
}

static NSData *mountIconData(void)
{
	//Named with an underscore to prevent name conflict with the function. Be aware of which one you use here.
	static NSData *_mountIconData = nil;
	
	if (!_mountIconData) {
		_mountIconData = [[[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericRemovableMediaIcon)] TIFFRepresentation] retain];
	}
	
	return _mountIconData;
}

@implementation VolumeInfo

+ (VolumeInfo *) volumeInfoForMountWithPath:(NSString *)aPath {
	return [[[VolumeInfo alloc] initForMountWithPath:aPath] autorelease];
}

+ (VolumeInfo *) volumeInfoForUnmountWithPath:(NSString *)aPath {
	return [[[VolumeInfo alloc] initForUnmountWithPath:aPath] autorelease];
}

- (id) initForMountWithPath:(NSString *)aPath {
	if ((self = [self initWithPath:aPath])) {
		if (path) {
			iconData = [[[[NSWorkspace sharedWorkspace] iconForFile:path] TIFFRepresentation] retain];
		} else {
			iconData = [mountIconData() retain];
		}
	}
	
	return self;
}

- (id) initForUnmountWithPath:(NSString *)aPath {
	if ((self = [self initWithPath:aPath])) {
		if (path) {
			//Get the icon for the volume.
			NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
			NSSize iconSize = [icon size];
			//Also get the standard Eject icon.
			NSImage *ejectIcon = ejectIconImage();
			[ejectIcon setScalesWhenResized:NO]; //Use the high-res rep instead.
			NSSize ejectIconSize = [ejectIcon size];
			
			//Badge the volume icon with the Eject icon. This is what we'll pass off te Growl.
			//The badge's width and height are 2/3 of the overall icon's width and height. If they were 1/2, it would look small (so I found in testing —boredzo). This looks pretty good.
			[icon lockFocus];
			
			[ejectIcon drawInRect:NSMakeRect( /*origin.x*/ iconSize.width * (1.0f / 3.0f), /*origin.y*/ 0.0f, /*width*/ iconSize.width * (2.0f / 3.0f), /*height*/ iconSize.height * (2.0f / 3.0f) )
						 fromRect:(NSRect){ NSZeroPoint, ejectIconSize }
						operation:NSCompositeSourceOver
						 fraction:1.0f];
			
			//For some reason, passing [icon TIFFRepresentation] only passes the unbadged volume icon to Growl, even though writing the same TIFF data out to a file and opening it in Preview does show the badge. If anybody can figure that out, you're welcome to do so. Until then:
			//We get a NSBIR for the current focused view (the image), and make PNG data from it. (There is no reason why this could not be TIFF if we wanted it to be. I just generally prefer PNG. —boredzo)
			NSBitmapImageRep *imageRep = [[[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){ NSZeroPoint, iconSize }] autorelease];
			iconData = [[imageRep representationUsingType:NSPNGFileType properties:nil] retain];
			
			[icon unlockFocus];
		} else {
			iconData = [[ejectIconImage() TIFFRepresentation] retain];
		}
	}
	
	return self;
}

- (id) initWithPath:(NSString *)aPath {
	if ((self = [super init])) {
		if (aPath) {
			path = [aPath retain];
			name = [[[NSFileManager defaultManager] displayNameAtPath:path] retain];
		}
	}
	
	return self;
}

- (void) dealloc {
	[path release];
	path = nil;
	
	[name release];
	name = nil;
	
	[iconData release];
	iconData = nil;
	
	[super dealloc];
}

- (NSString *) description {
	NSMutableDictionary *desc = [NSMutableDictionary dictionary];

	if (name)
		[desc setObject:name forKey:@"name"];
	if (path)
		[desc setObject:path forKey:@"path"];
	if (iconData)
		[desc setObject:@"<yes>" forKey:@"iconData"];
	
	return [desc description];
}

- (NSData *) iconData {
	return iconData;
}

- (NSString *) name {
	return name;
}

- (NSString *) path {
	return path;
}

@end

@interface VolumeNotifier : NSObject {
}

+ (void) staleEjectItemTimerFired:(NSTimer *)theTimer;
+ (void) volumeDidMount:(NSNotification *)aNotification;
+ (void) volumeWillUnmount:(NSNotification *)aNotification;
+ (void) volumeDidUnmount:(NSNotification *)aNotification;

@end

@implementation VolumeNotifier

+ (void) staleEjectItemTimerFired:(NSTimer *)theTimer {
	VolumeInfo *info = [theTimer userInfo];
	
	[ejectCache removeObjectForKey:[info path]];
}

+ (void) volumeDidMount:(NSNotification *)aNotification {
	AppController_volumeDidMount([VolumeInfo volumeInfoForMountWithPath:[[aNotification userInfo] objectForKey:@"NSDevicePath"]]);
}

+ (void) volumeWillUnmount:(NSNotification *)aNotification {
	NSString *path = [[aNotification userInfo] objectForKey:@"NSDevicePath"];

	if (path) {
		VolumeInfo *info = [VolumeInfo volumeInfoForUnmountWithPath:path];
		NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:VolumeNotifierUnmountWaitSeconds
														  target:[VolumeNotifier class]
														selector:@selector(staleEjectItemTimerFired:)
														userInfo:info
														 repeats:NO];
		
		// need to invalidate the timer for a previous item if it exists
		NSArray *cacheItem = [ejectCache objectForKey:path];
		if (cacheItem)
			[[cacheItem objectAtIndex:VolumeEjectCacheTimerIndex] invalidate];
		
		[ejectCache setObject:[NSArray arrayWithObjects:info, timer, nil] forKey:path];
	}
}

+ (void) volumeDidUnmount:(NSNotification *)aNotification {
	VolumeInfo *info = nil;
	NSString *path = [[aNotification userInfo] objectForKey:@"NSDevicePath"];
	NSArray *cacheItem = path ? [ejectCache objectForKey:path] : nil;

	if (cacheItem)
		info = [cacheItem objectAtIndex:VolumeEjectCacheInfoIndex];
	else
		info = [VolumeInfo volumeInfoForUnmountWithPath:path];

	AppController_volumeDidUnmount(info);

	if (cacheItem) {
		[[cacheItem objectAtIndex:VolumeEjectCacheTimerIndex] invalidate];
		// we need to remove the item from the cache AFTER calling volumeDidUnmount so that "info" stays
		// retained long enough to be useful. After this next call, "info" is no longer valid.
		[ejectCache removeObjectForKey:path];
		info = nil;
	}
}

@end

void VolumeNotifier_init(void) {
	if (!ejectCache)
		ejectCache = [[NSMutableDictionary alloc] init];
	
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	NSNotificationCenter *center = [workspace notificationCenter];
	
	[center addObserver:[VolumeNotifier class] selector:@selector(volumeDidMount:) name:NSWorkspaceDidMountNotification object:nil];
	//Note that we must use both WILL and DID unmount, so we can only get the volume's icon before the volume has finished unmounting.
	//The icon and data is stored during WILL unmount, and then displayed during DID unmount.
	[center addObserver:[VolumeNotifier class] selector:@selector(volumeDidUnmount:) name:NSWorkspaceDidUnmountNotification object:nil];
	[center addObserver:[VolumeNotifier class] selector:@selector(volumeWillUnmount:) name:NSWorkspaceWillUnmountNotification object:nil];

	Boolean keyExistsAndHasValidFormat;
	if (CFPreferencesGetAppBooleanValue(CFSTR("ShowExisting"), CFSTR("com.growl.hardwaregrowler"), &keyExistsAndHasValidFormat)) {
		NSArray *paths = [workspace mountedLocalVolumePaths];
		unsigned int i;
		
		for (i = 0; i < [paths count]; ++i)
			AppController_volumeDidMount([VolumeInfo volumeInfoForMountWithPath:[paths objectAtIndex:i]]);
	}
}

void VolumeNotifier_dealloc(void) {
	NSNotificationCenter *center = [[NSWorkspace sharedWorkspace] notificationCenter];
	
	[center removeObserver:[VolumeNotifier class] name:NSWorkspaceWillUnmountNotification object:nil];
	[center removeObserver:[VolumeNotifier class] name:NSWorkspaceDidUnmountNotification object:nil];
	[center removeObserver:[VolumeNotifier class] name:NSWorkspaceDidMountNotification object:nil];

	// loop through the eject cache and invalidate all the timers
	NSEnumerator *cacheItemEnum = [ejectCache objectEnumerator];
	for (NSArray *cacheItem = [cacheItemEnum nextObject]; cacheItem != nil; cacheItem = [cacheItemEnum nextObject])
		[[cacheItem objectAtIndex:VolumeEjectCacheTimerIndex] invalidate];
	
	[ejectCache release];
	ejectCache = nil;
}

