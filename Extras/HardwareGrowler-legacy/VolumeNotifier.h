//
//  VolumeNotifier.h
//  HardwareGrowler
//
//  Created by Diggory Laycock on 10/02/2005.
//  Copyright 2005 The Growl Project. All rights reserved.
//

void VolumeNotifier_init(void);
void VolumeNotifier_dealloc(void);

#ifdef __OBJC__

#import <Cocoa/Cocoa.h>

@interface VolumeInfo : NSObject {
	NSData *iconData;
	NSString *name;
	NSString *path;
}

+ (VolumeInfo *) volumeInfoForMountWithPath:(NSString *)aPath;
+ (VolumeInfo *) volumeInfoForUnmountWithPath:(NSString *)aPath;

- (id) initForMountWithPath:(NSString *)aPath;
- (id) initForUnmountWithPath:(NSString *)aPath;
- (id) initWithPath:(NSString *)aPath;

- (NSData *) iconData;
- (NSString *) name;
- (NSString *) path;

@end

#endif
