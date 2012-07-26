//
//  GrowlBoxcarAction.m
//  Boxcar
//
//  Created by Daniel Siemer on 3/19/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//
//  This class is where the main logic of dispatching a notification via your plugin goes.
//  There will be only one instance of this class, so use the configuration dictionary for figuring out settings.
//  Be aware that action plugins will be dispatched on the default priority background concurrent queue.
//  

#import "GrowlBoxcarAction.h"
#import "GrowlBoxcarPreferencePane.h"
#import "BoxcarDefines.h"
#import <GrowlPlugins/GrowlDefines.h>
#import <GrowlPlugins/GrowlIdleStatusObserver.h>
#import <GrowlPlugins/GrowlKeychainUtilities.h>
#import <GrowlPlugins/NSURL+StringEncoding.h>

@interface GrowlBoxcarAction ()

@property (nonatomic, retain) NSMutableArray *connections;

@end

@implementation GrowlBoxcarAction

@synthesize connections;

-(id)init{
	if((self = [super init])){
		self.prefDomain = BoxcarPrefDomain;
		self.connections = [NSMutableArray array];
	}
	return self;
}

-(NSDictionary*)upgradeConfigDict:(NSDictionary *)original toConfigID:(NSString *)configID {
	NSString *email = [original valueForKey:BoxcarEmail];
	if(email && ![email isEqualToString:@""])
		[GrowlKeychainUtilities removePasswordForService:@"BoxcarGrowl" accountName:email];
	return original;
}

/* Dispatch a notification with a configuration, called on the default priority background concurrent queue
 * Unless you need to use UI, do not send something to the main thread/queue.
 * If you have a requirement to be serialized, make a custom serial queue for your own use. 
 */
-(void)dispatchNotification:(NSDictionary *)notification withConfiguration:(NSDictionary *)configuration {
	NSString *email = [configuration valueForKey:BoxcarEmail];
	if(!email || [email isEqualToString:@""])
		return;
	
	if([configuration valueForKey:BoxcarPushIdle] && 
		[[configuration valueForKey:BoxcarPushIdle] boolValue] && 
		[[GrowlIdleStatusObserver sharedObserver] isIdle])
	{
		//NSLog(@"Not pushing because not idle");
		return;
	}
	
	NSInteger priority = [[notification valueForKey:GROWL_NOTIFICATION_PRIORITY] intValue];
	if([configuration valueForKey:BoxcarUsePriority] && [[configuration valueForKey:BoxcarUsePriority] boolValue]){
		NSInteger minPriority = [configuration valueForKey:BoxcarMinPriority] ? [[configuration valueForKey:BoxcarMinPriority] integerValue] : BoxcarMinPriorityDefault;
		if (priority < minPriority) {
			//NSLog(@"Not pushing because priority too low");
			return;
		}
	}
	
	NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://boxcar.io/devices/providers/%@/notifications", BoxcarProviderKey]];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:baseURL 
																			 cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData 
																		timeoutInterval:100];
	
	NSString *message = [NSString stringWithFormat:@"%@ - %@", [notification objectForKey:GROWL_NOTIFICATION_TITLE], [notification objectForKey:GROWL_NOTIFICATION_DESCRIPTION]];
	NSString *prefix = [configuration valueForKey:BoxcarPrefixString];
	if([configuration valueForKey:BoxcarUsePrefix] && [[configuration valueForKey:BoxcarUsePrefix] boolValue]){
		if(prefix && ![prefix isEqualToString:@""])
			message = [NSString stringWithFormat:@"[%@] %@", prefix, message];
	}
	message = [NSURL encodedStringByAddingPercentEscapesToString:message];
	
	NSString *app = [NSURL encodedStringByAddingPercentEscapesToString:[notification valueForKey:GROWL_APP_NAME]];
	
	NSMutableString *dataString = [NSMutableString stringWithFormat:@"email=%@", email];
	[dataString appendFormat:@"&notification[from_screen_name]=%@", app];
	[dataString	appendFormat:@"&notification[message]=%@", message];
	[dataString appendFormat:@"&notification[priority]=%ld", priority];
	NSData *data = [NSData dataWithBytes:[dataString UTF8String] length:[dataString lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:data];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
	
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request
																					  delegate:self
																			startImmediately:NO];
	[connections addObject:connection];
	[connection setDelegateQueue:[NSOperationQueue mainQueue]];
	[connection start];
	[connection release];
}

#pragma mark NSURLConnectionDelegate

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	if([response respondsToSelector:@selector(statusCode)]){
		NSInteger status = [(NSHTTPURLResponse*)response statusCode];
		switch (status) {
			case 200:
				//SUCCESS!
				//NSLog(@"Success notifiying");
				break;
			case 400:
				//Silly boxcar
				break;
			case 401:
				//Not added!
				NSLog(@"This email has not added growl!");
				break;
			case 404:
				//User unknown!
				NSLog(@"This email is unknown to boxcar!");
				break;
			default:
				//Unknown response
				NSLog(@"Unknown response code from boxcar: %lu", status);
				break;
		}
	}else{
		NSLog(@"Error! Should be able to get a status code");
	}
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	NSLog(@"connection %@ failed with error %@", connection, error);
	[connections removeObject:connection];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[connections removeObject:connection];
}

#pragma mark -

/* Auto generated method returning our PreferencePane, do not touch */
- (GrowlPluginPreferencePane *) preferencePane {
	if (!preferencePane)
		preferencePane = [[GrowlBoxcarPreferencePane alloc] initWithBundle:[NSBundle bundleWithIdentifier:@"com.Growl.Boxcar"]];
	
	return preferencePane;
}

@end
