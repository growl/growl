//
//  VolumeNotifier.h
//  HardwareGrowler
//
//  Created by Diggory Laycock on 10/02/2005.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <DiskArbitration/DiskArbitration.h>

@interface VolumeNotifier : NSObject {
	DASessionRef session;
}

- (id) initWithDelegate:(id)delegate;

@end

@interface NSObject(VolumeNotifierDelegate)
- (void) volumeDidMount:(NSString *)name atPath:(NSString *)path;
- (void) volumeDidUnmount:(NSString *)name;
@end
