//
//  GrowlApplication.h
//  Growl
//
//  Created by Evan Schoenberg on 5/10/07.
//  Copyright 2007 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GrowlApplication : NSApplication {
	NSTimer *autoreleasePoolRefreshTimer;
}

@end
