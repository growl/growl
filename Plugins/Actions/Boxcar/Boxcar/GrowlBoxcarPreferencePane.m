//
//  GrowlBoxcarPreferencePane.m
//  Boxcar
//
//  Created by Daniel Siemer on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
//  This class represents your plugin's preference pane.  There will be only one instance, but possibly many configurations
//  In order to access a configuration values, use the NSMutableDictionary *configuration for getting them. 
//  In order to change configuration values, use [self setConfigurationValue:forKey:]
//  This ensures that the configuration gets saved into the database properly.

#import "GrowlBoxcarPreferencePane.h"
#import "BoxcarDefines.h"

@implementation GrowlBoxcarPreferencePane

-(NSString*)mainNibName {
	return @"BoxcarPrefPane";
}

/* This returns the set of keys the preference pane needs updated via bindings 
 * This is called by GrowlPluginPreferencePane when it has had its configuration swapped
 * Since we really only need a fixed set of keys updated, use dispatch_once to create the set
 */
- (NSSet*)bindingKeys {
	static NSSet *keys = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		keys = [[NSSet setWithObject:@"emailAddress"] retain];
	});
	return keys;
}

/* This method is called when our configuration values have been changed 
 * by switching to a new configuration.  This is where we would update certain things
 * that are unbindable.  Call the super version in order to ensure bindingKeys is also called and used.
 * Uncomment the method to use.
 */
/*
-(void)updateConfigurationValues {
	[super updateConfigurationValues];
}
*/

-(NSString*)emailAddress {
	return [self.configuration valueForKey:BoxcarEmail];
}
-(void)setEmailAddress:(NSString*)newAddress {
	if(!newAddress || [[self emailAddress] isEqualToString:newAddress] || [newAddress isEqualToString:@""]){
		return;
	}
	
	[self setConfigurationValue:newAddress forKey:BoxcarEmail];
	NSURL *baseURL = [NSURL URLWithString:@"http://boxcar.io/devices/providers/yw5gVPXug6ZwKGOMhCfu/notifications/subscribe"];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:baseURL];
	NSString *email = [NSString stringWithFormat:@"email=%@", newAddress];
	NSData *data = [NSData dataWithBytes:[email UTF8String] length:[email lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:data];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];

	[NSURLConnection sendAsynchronousRequest:request
												  queue:[NSOperationQueue mainQueue]
								  completionHandler:^(NSURLResponse *response, NSData *urlData, NSError *error) {
									  if([response respondsToSelector:@selector(statusCode)]){
										  NSInteger status = [(NSHTTPURLResponse*)response statusCode];
										  switch (status) {
											  case 200:
												  //SUCCESS!
												  NSLog(@"Success registering");
												  break;
											  case 400:
												  //Silly boxcar
												  break;
											  case 401:
												  //Already added!
												  NSLog(@"This user already setup Growl for boxcar");
												  break;
											  case 404:
												  //User unknown!
												  NSLog(@"User unknown, you will be contacted via email shortly");
												  break;
											  default:
												  //Unknown response
												  NSLog(@"Unknown response code from boxcar: %lu", status);
												  break;
										  }
									  }
								  }];
}

@end
