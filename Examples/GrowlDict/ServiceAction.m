//
//  ServiceAction.m
//  dictmenu
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
    curlTask=[[NSTask alloc] init];
    [curlTask setLaunchPath:@"/usr/bin/curl"];    
	args=[NSArray arrayWithObjects: [@"dict://dict.org/d:" stringByAppendingString: pboardString], nil];
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
	NSRange toprange =[curlResult rangeOfString: @"151 "];
	curlResult = [curlResult substringFromIndex: toprange.location];
	NSNumber *defaultValue = [NSNumber numberWithBool:YES];
	toprange =[curlResult rangeOfString: @"\n"];
	curlResult = [curlResult substringFromIndex: toprange.location+1];
	NSRange bottomrange =[curlResult rangeOfString: @"\n250"];
	curlResult = [curlResult substringToIndex: bottomrange.location-3];
	bottomrange =[curlResult rangeOfString: @"151 "];
    if (bottomrange.location !=NSNotFound){
		curlResult = [curlResult substringToIndex: bottomrange.location-4];
	}
	
	//Throw it in a dictionary and send it to growl
	NSDictionary *growlEvent = [NSDictionary dictionaryWithObjectsAndKeys:
		@"Dictmenu-Definition", GROWL_NOTIFICATION_NAME,
		pboardString, GROWL_NOTIFICATION_TITLE,
		curlResult, GROWL_NOTIFICATION_DESCRIPTION,
		@"Dictmenu", GROWL_APP_NAME,
		defaultValue, GROWL_NOTIFICATION_DEFAULT,
		nil, GROWL_NOTIFICATION_ICON,
		nil];
	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION object:nil userInfo:growlEvent];
	
	[curlTask release];	
	
    return;
}

@end
