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
//  ServiceAction.m
//  GrowlDict
//
//  Created by don smith on Tue Jun 08 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "ServiceAction.h"
#import "GrowlDefines.h"
#define GROWL_NOTIFICATION_DEFAULT @"NotificationDefault"


@implementation ServiceAction
- (void)doLookupWordService:(NSPasteboard *)pboard
				   userData:(NSString *)data
					  error:(NSString **)error
{ 
	NSString *pboardString;
	NSArray *types;
	NSTask *curlTask;
	NSArray *args;
	NSPipe *pipe;
	NSPipe *pipe2;  //This is so std error doesn't go to the log, tried using the curl --stderr but i think it messed up the pipe
	NSFileHandle *file;
	NSData *curlData;
	NSString *curlResult;
	
	types = [pboard types];
	
	
	if (![types containsObject:NSStringPboardType] || !(pboardString = [pboard stringForType:NSStringPboardType])) {
	    *error = NSLocalizedString(@"Error: Pasteboard doesn't contain a string.",
								   @"Pasteboard couldn't give string.");
	    return;
	}
	// Setup NSTask to call curl and put the result in a NSString
	curlTask = [[NSTask alloc] init];
	[curlTask setLaunchPath:@"/usr/bin/curl"];
	args = [NSArray arrayWithObject: [@"dict://dict.org/d:" stringByAppendingString: pboardString]];
	[curlTask setArguments:args];
	pipe = [NSPipe pipe];
	pipe2 = [NSPipe pipe];
	[curlTask setStandardOutput: pipe];
	[curlTask setStandardError: pipe2];
	file = [pipe fileHandleForReading];
	[curlTask launch]; 
	curlData = [file readDataToEndOfFile];
	curlResult = [[[NSString alloc] initWithData: curlData encoding: NSUTF8StringEncoding] autorelease];
	[file closeFile];
	
	//Cleanup the string so it's just the first definition
	NSRange toprange = [curlResult rangeOfString: @"151 "];
	curlResult = [curlResult substringFromIndex: toprange.location];
	NSNumber *defaultValue = [NSNumber numberWithBool:YES];
	toprange = [curlResult rangeOfString: @"\n"];
	curlResult = [curlResult substringFromIndex: toprange.location+1];
	NSRange bottomrange = [curlResult rangeOfString: @"\n250"];
	curlResult = [curlResult substringToIndex: bottomrange.location-3];
	bottomrange = [curlResult rangeOfString: @"151 "];
	if (bottomrange.location != NSNotFound){
		curlResult = [curlResult substringToIndex: bottomrange.location-4];
	}
	
	//Throw it in a dictionary and send it to growl
	NSDictionary *growlEvent = [NSDictionary dictionaryWithObjectsAndKeys:
		@"GrowlDict-Definition", GROWL_NOTIFICATION_NAME,
		pboardString, GROWL_NOTIFICATION_TITLE,
		curlResult, GROWL_NOTIFICATION_DESCRIPTION,
		@"GrowlDict", GROWL_APP_NAME,
		defaultValue, GROWL_NOTIFICATION_DEFAULT,
		nil, GROWL_NOTIFICATION_ICON,
		nil];
	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION object:nil userInfo:growlEvent];
	
	[curlTask release];	
	
	return;
}

@end
