//
//  VolumeNotifier.h
//  HardwareGrowler
//
//  Created by Diggory Laycock on 10/02/2005.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface VolumeNotifier : NSObject {
	id delegate;
}

- (id)initWithDelegate:(id)object;

@end
