/*
 Copyright (c) The Growl Project, 2004 
 All rights reserved.
 
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 
 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 3. Neither the name of Growl nor the names of its contributors
 may be used to endorse or promote products derived from this software
 without specific prior written permission.
 
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
*/
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
