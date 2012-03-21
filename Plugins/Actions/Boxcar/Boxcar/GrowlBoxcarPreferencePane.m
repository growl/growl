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

@synthesize errorMessage;
@synthesize validating;

-(id)initWithBundle:(NSBundle *)bundle {
	if((self = [super initWithBundle:bundle])){
		self.validating = NO;
	}
	return self;
}

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
		keys = [[NSSet setWithObjects:@"emailAddress" @"pushIdle", nil] retain];
	});
	return keys;
}

/* This method is called when our configuration values have been changed 
 * by switching to a new configuration.  This is where we would update certain things
 * that are unbindable.  Call the super version in order to ensure bindingKeys is also called and used.
 * Uncomment the method to use.
 */

-(void)updateConfigurationValues {
	[super updateConfigurationValues];
	//[self checkEmailAddress:[self emailAddress]];
}

-(void)checkEmailAddress:(NSString*)newAddress {
	if(!newAddress || [[self emailAddress] isEqualToString:newAddress] || [newAddress isEqualToString:@""]){
		return;
	}
	
	[self setConfigurationValue:newAddress forKey:BoxcarEmail];
	NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://boxcar.io/devices/providers/%@/notifications/subscribe", BoxcarProviderKey]];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:baseURL];
	NSString *email = [NSString stringWithFormat:@"email=%@", newAddress];
	NSData *data = [NSData dataWithBytes:[email UTF8String] length:[email lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:data];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];

	__block GrowlBoxcarPreferencePane *blockSelf = self;
	self.errorMessage = @"";
	self.validating = YES;
	[NSURLConnection sendAsynchronousRequest:request
												  queue:[NSOperationQueue mainQueue]
								  completionHandler:^(NSURLResponse *response, NSData *urlData, NSError *error) {
									  blockSelf.validating = NO;
									  if([response respondsToSelector:@selector(statusCode)]){
										  NSInteger status = [(NSHTTPURLResponse*)response statusCode];
										  switch (status) {
											  case 200:
												  //SUCCESS!
												  blockSelf.errorMessage = NSLocalizedString(@"Registered!", @"Success adding boxcar");
												  [self setConfigurationValue:newAddress forKey:BoxcarEmail];
												  break;
											  case 400:
												  //Silly boxcar
												  blockSelf.errorMessage = NSLocalizedString(@"Invalid Email", @"Failure adding email");
												  NSLog(@"Boxcar no longer accepts hashes");
												  break;
											  case 401:
												  //Already added!
												  blockSelf.errorMessage = NSLocalizedString(@"Registered!", @"Success adding boxcar");
												  break;
											  case 404:
												  //User unknown!
												  blockSelf.errorMessage = NSLocalizedString(@"Unknown email", @"Failed adding boxcar, unknown email address");
												  NSLog(@"User unknown, you will be contacted via email shortly");
												  break;
											  default:
												  //Unknown response
												  blockSelf.errorMessage = [NSString stringWithFormat:@"Error %lu", status];
												  NSLog(@"Unknown response code from boxcar: %lu", status);
												  break;
										  }
									  }
								  }];
}

-(NSString*)emailAddress {
	return [self.configuration valueForKey:BoxcarEmail];
}
-(void)setEmailAddress:(NSString*)newAddress {
	[self checkEmailAddress:newAddress];
	[self setConfigurationValue:newAddress forKey:BoxcarEmail];
}

-(NSString*)prefixString {
	return [self.configuration valueForKey:BoxcarPrefixString];
}
-(void)setPrefixString:(NSString *)newPrefix {
	[self setConfigurationValue:newPrefix forKey:BoxcarPrefixString];
}

-(BOOL)usePrefix {
	BOOL value = BoxcarUsePrefixDefault;
	if([self.configuration valueForKey:BoxcarUsePrefix]){
		value = [[self.configuration valueForKey:BoxcarUsePrefix] boolValue];
	}
	return value;
}
-(void)setUsePrefix:(BOOL)prefix {
	[self setConfigurationValue:[NSNumber numberWithBool:prefix] forKey:BoxcarUsePrefix];
}

-(BOOL)pushIdle{
	BOOL value = BoxcarUseIdleDefault;
	if([self.configuration valueForKey:BoxcarPushIdle]){
		value = [[self.configuration valueForKey:BoxcarPushIdle] boolValue];
	}
	return value;
}
-(void)setPushIdle:(BOOL)push {
	[self setConfigurationValue:[NSNumber numberWithBool:push] forKey:BoxcarPushIdle];
}

-(BOOL)usePriority{
	BOOL value = BoxcarUsePriorityDefault;
	if([self.configuration valueForKey:BoxcarUsePriority]){
		value = [[self.configuration valueForKey:BoxcarUsePriority] boolValue];
	}
	return value;
}
-(void)setUsePriority:(BOOL)use {
	[self setConfigurationValue:[NSNumber numberWithBool:use] forKey:BoxcarUsePriority];
}

-(int)minPriority {
	int value = BoxcarMinPriorityDefault;
	if([self.configuration valueForKey:BoxcarMinPriority]){
		value = [[self.configuration valueForKey:BoxcarMinPriority] intValue];
	}
	return value;
}
-(void)setMinPriority:(int)min {
	[self setConfigurationValue:[NSNumber numberWithInt:min] forKey:BoxcarMinPriority];
}

@end
