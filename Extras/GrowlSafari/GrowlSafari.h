//
//  GrowlSafari.h
//  GrowlSafari
//
//  Created by Peter Hosey on 2008-05-12.
//  Copyright 2008 The Growl Project. All rights reserved.
//

#import <Growl/Growl.h>

@interface GrowlSafari : NSObject <GrowlApplicationBridgeDelegate> {
	NSFileHandle *logFile;
}

@end
