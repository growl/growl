//
//  DictmenuService_main.m
//  dictmenu
//
//  Created by don smith on Tue Jun 08 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#include <Foundation/Foundation.h>
#include <GrowlAppBridge/GrowlApplicationBridge.h>
#include "ServiceAction.h"
#include <Cocoa/Cocoa.h>
#include "GrowlDefines.h"
#define GROWL_NOTIFICATION_DEFAULT @"NotificationDefault"


int main (int argc, const char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    ServiceAction *serviceProvider = [[ServiceAction alloc] init];
	NSArray * objects=[[[NSArray alloc] initWithObjects: @"Dictmenu-Definition", nil] autorelease];
    NSRegisterServicesProvider(serviceProvider, @"SimpleService");
	
//	[GrowlAppBridge launchGrowlIfInstalledNotifyingTarget:self selector:@selector(growlDidLaunch:) context:nil];
	
        //Register us with Growl
        
        NSDictionary * growlReg = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                        @"Dictmenu", GROWL_APP_NAME,
                                                                        objects, GROWL_NOTIFICATIONS_ALL,
                                                                        objects, GROWL_NOTIFICATIONS_DEFAULT,
                                                                        nil];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_APP_REGISTRATION object:nil userInfo:growlReg];

																 
    NS_DURING
       [[NSRunLoop currentRunLoop] configureAsServer];
        [[NSRunLoop currentRunLoop] run];
		NSLog([[NSRunLoop currentRunLoop] currentMode]);
    NS_HANDLER
        NSLog(@"%@", localException);
    NS_ENDHANDLER

    [serviceProvider release];
    [pool release];
 
    exit(0);       // insure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec.
}
