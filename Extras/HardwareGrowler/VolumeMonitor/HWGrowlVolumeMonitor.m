//
//  HWGrowlVolumeMonitor.m
//  HardwareGrowler
//
//  Created by Daniel Siemer on 5/3/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "HWGrowlVolumeMonitor.h"

#define VolumeNotifierUnmountWaitSeconds	600.0
#define VolumeEjectCacheInfoIndex			0
#define VolumeEjectCacheTimerIndex			1

@implementation VolumeInfo

@synthesize iconData;
@synthesize path;
@synthesize name;

+ (NSImage*)ejectIconImage {
	static NSImage *_ejectIconImage = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_ejectIconImage = [[NSImage imageNamed:@"DisksVolumes-Eject"] retain];
	});
	return _ejectIconImage;
}

+ (NSData*)mountIconData {
	static NSData *_mountIconData = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_mountIconData = [[[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericRemovableMediaIcon)] TIFFRepresentation] retain];
	});
	return _mountIconData;
}

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
			self.iconData = [VolumeInfo mountIconData];
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
			NSImage *ejectIcon = [VolumeInfo ejectIconImage];
			[ejectIcon setScalesWhenResized:NO]; //Use the high-res rep instead.
			NSSize ejectIconSize = [ejectIcon size];
			
			//Badge the volume icon with the Eject icon. This is what we'll pass off te Growl.
			//The badge's width and height are 2/3 of the overall icon's width and height. If they were 1/2, it would look small (so I found in testing —boredzo). This looks pretty good.
			[icon lockFocus];
			
			[ejectIcon drawInRect:CGRectMake(0.0f, 0.0f, iconSize.width, iconSize.width)
							 fromRect:(NSRect){ NSZeroPoint, ejectIconSize }
							operation:NSCompositeSourceOver
							 fraction:1.0f];
			
			//For some reason, passing [icon TIFFRepresentation] only passes the unbadged volume icon to Growl, even though writing the same TIFF data out to a file and opening it in Preview does show the badge. If anybody can figure that out, you're welcome to do so. Until then:
			//We get a NSBIR for the current focused view (the image), and make PNG data from it. (There is no reason why this could not be TIFF if we wanted it to be. I just generally prefer PNG. —boredzo)
			NSBitmapImageRep *imageRep = [[[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){ NSZeroPoint, iconSize }] autorelease];
			iconData = [[imageRep representationUsingType:NSPNGFileType properties:nil] retain];
			
			[icon unlockFocus];
		} else {
			iconData = [[[VolumeInfo ejectIconImage] TIFFRepresentation] retain];
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

@end

@interface HWGrowlVolumeMonitor ()

@property (nonatomic, assign) id<HWGrowlPluginControllerProtocol> delegate;
@property (nonatomic, retain) NSMutableDictionary *ejectCache;
@property (nonatomic, retain) NSString *ignoredVolumeColumnTitle;

@property (nonatomic, assign) IBOutlet NSArrayController *arrayController;
@property (nonatomic, assign) IBOutlet NSTableView *tableView;

@end

@implementation HWGrowlVolumeMonitor

@synthesize delegate;
@synthesize ejectCache;

@synthesize prefsView;
@synthesize arrayController;
@synthesize tableView;

-(id)init {
	if((self = [super init])){
		self.ejectCache = [NSMutableDictionary dictionary];
		
		NSNotificationCenter *center = [[NSWorkspace sharedWorkspace] notificationCenter];
		
		[center addObserver:self selector:@selector(volumeDidMount:) name:NSWorkspaceDidMountNotification object:nil];
		//Note that we must use both WILL and DID unmount, so we can only get the volume's icon before the volume has finished unmounting.
		//The icon and data is stored during WILL unmount, and then displayed during DID unmount.
		[center addObserver:self selector:@selector(volumeDidUnmount:) name:NSWorkspaceDidUnmountNotification object:nil];
		[center addObserver:self selector:@selector(volumeWillUnmount:) name:NSWorkspaceWillUnmountNotification object:nil];
		
		self.ignoredVolumeColumnTitle = NSLocalizedString(@"Ignored Drives:", @"Title for colum in table of ignored volumes");
	}
	return self;
}

- (void)dealloc {
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	
	[ejectCache enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		[[obj objectAtIndex:VolumeEjectCacheTimerIndex] invalidate];
	}];		
	
	[ejectCache release];
	ejectCache = nil;
	
	self.ignoredVolumeColumnTitle = nil;
	[super dealloc];
}

- (void) sendMountNotificationForVolume:(VolumeInfo*)volume mounted:(BOOL)mounted {
	NSArray *exceptions = [[NSUserDefaults standardUserDefaults] objectForKey:@"HWGVolumeMonitorExceptions"];
	__block BOOL found = NO;
	[exceptions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSString *justAString = [obj valueForKey:@"justastring"];
		if([justAString caseInsensitiveCompare:[volume path]] == NSOrderedSame ||
			[justAString caseInsensitiveCompare:[volume name]] == NSOrderedSame)
		{
			found = YES;
			*stop = YES;
		}
	}];
	if(found)
		return;
	
	NSString *context = mounted ? [volume path] : nil;
	NSString *type = mounted ? @"VolumeMounted" : @"VolumeUnmounted";
	NSString *title = [NSString stringWithFormat:@"%@ %@", [volume name], mounted ? NSLocalizedString(@"Mounted", @"") : NSLocalizedString(@"Unmounted", @"")];
	[delegate notifyWithName:type
							 title:title
					 description:mounted ? NSLocalizedString(@"Click to open", @"Message body on a volume mount notification, clicking it opens the drive in finder") : nil
							  icon:[volume iconData]
			  identifierString:[volume path]
				  contextString:context 
							plugin:self];
}

- (void) staleEjectItemTimerFired:(NSTimer *)theTimer {
	VolumeInfo *info = [theTimer userInfo];
	
	[ejectCache removeObjectForKey:[info path]];
}

- (void) volumeDidMount:(NSNotification *)aNotification {
	//send notification
	VolumeInfo *volume = [VolumeInfo volumeInfoForMountWithPath:[[aNotification userInfo] objectForKey:@"NSDevicePath"]];
	[self sendMountNotificationForVolume:volume mounted:YES];
}

- (void) volumeWillUnmount:(NSNotification *)aNotification {
	NSString *path = [[aNotification userInfo] objectForKey:@"NSDevicePath"];
	
	if (path) {
		VolumeInfo *info = [VolumeInfo volumeInfoForUnmountWithPath:path];
		NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:VolumeNotifierUnmountWaitSeconds
																		  target:self
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

- (void) volumeDidUnmount:(NSNotification *)aNotification {
	VolumeInfo *info = nil;
	NSString *path = [[aNotification userInfo] objectForKey:@"NSDevicePath"];
	NSArray *cacheItem = path ? [ejectCache objectForKey:path] : nil;
	
	if (cacheItem)
		info = [cacheItem objectAtIndex:VolumeEjectCacheInfoIndex];
	else
		info = [VolumeInfo volumeInfoForUnmountWithPath:path];
	
	//Send notification
	[self sendMountNotificationForVolume:info mounted:NO];
	
	if (cacheItem) {
		[[cacheItem objectAtIndex:VolumeEjectCacheTimerIndex] invalidate];
		// we need to remove the item from the cache AFTER calling volumeDidUnmount so that "info" stays
		// retained long enough to be useful. After this next call, "info" is no longer valid.
		[ejectCache removeObjectForKey:path];
		info = nil;
	}
}

#pragma mark UI

-(void)tableViewSelectionDidChange:(NSNotification *)notification {
   NSArray *arranged = [arrayController arrangedObjects];
   NSUInteger selection = [arrayController selectionIndex];
   if(selection < [arranged count] && [arranged count]){
      NSString *justastring = [[arranged objectAtIndex:selection] valueForKey:@"justastring"];
      if(!justastring || [justastring isEqualToString:@""])
         [self.tableView editColumn:0 row:selection withEvent:nil select:YES];
   }
}

-(IBAction)addVolumeEntry:(id)sender {
   NSMutableDictionary *dict = [NSMutableDictionary dictionary];
   [self.arrayController addObject:dict];
   [self.arrayController setSelectedObjects:[NSArray arrayWithObject:dict]];
}
#pragma mark HWGrowlPluginProtocol

-(void)setDelegate:(id<HWGrowlPluginControllerProtocol>)aDelegate{
	delegate = aDelegate;
}
-(id<HWGrowlPluginControllerProtocol>)delegate {
	return delegate;
}
-(NSString*)pluginDisplayName{
	return NSLocalizedString(@"Volume Monitor", @"");
}
-(NSImage*)preferenceIcon {
	static NSImage *_icon = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_icon = [[NSImage imageNamed:@"HWGPrefsDrivesVolumes"] retain];
	});
	return _icon;
}
-(NSView*)preferencePane {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		[NSBundle loadNibNamed:@"VolumeMonitorPrefs" owner:self];
	});
	return prefsView;
}

#pragma mark HWGrowlPluginNotifierProtocol

-(NSArray*)noteNames {
	return [NSArray arrayWithObjects:@"VolumeMounted", @"VolumeUnmounted", nil];
}
-(NSDictionary*)localizedNames {
	return [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Volume Mounted", @""), @"VolumeMounted",
			  NSLocalizedString(@"Volume Unmounted", @""), @"VolumeUnmounted", nil];
}
-(NSDictionary*)noteDescriptions {
	return [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Sent when a volume is mounted", @""), @"VolumeMounted",
			  NSLocalizedString(@"Sent when a volume is unmounted", @""), @"VolumeUnmounted", nil];
}
-(NSArray*)defaultNotifications {
	return [NSArray arrayWithObjects:@"VolumeMounted", @"VolumeUnmounted", nil];
}

-(void)fireOnLaunchNotes{
	NSArray *paths = [[NSWorkspace sharedWorkspace] mountedLocalVolumePaths];
	__block HWGrowlVolumeMonitor *blockSelf = self;
	[paths enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		[blockSelf sendMountNotificationForVolume:[VolumeInfo volumeInfoForMountWithPath:obj] mounted:YES];
	}];
}
-(void)noteClosed:(NSString*)contextString byClick:(BOOL)clicked {
	if(clicked)
		[[NSWorkspace sharedWorkspace] openFile:contextString];
}

@end
