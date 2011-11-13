/*
 *  HelperMain.m
 *  Growl
 *
 *  Created by Karl Adam on Thu Apr 22 2004.
 *  Copyright (c) 2004 The Growl Project. All rights reserved.
 *
 */

#import "GrowlApplicationController.h"
#import "GrowlApplication.h"

int main(int argc, const char *argv[]) {
	int status;
    @autoreleasepool {
        NSApplication *app = [GrowlApplication sharedApplication];
        [app setDelegate:[GrowlApplicationController sharedController]];
        
        status = NSApplicationMain(argc, argv);
    }
	return status;
}


