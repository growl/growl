//
//  GrowlBoxcarPreferencePane.m
//  Boxcar
//
//  Created by Daniel Siemer on 3/19/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//
//  This class represents your plugin's preference pane.  There will be only one instance, but possibly many configurations
//  In order to access a configuration values, use the NSMutableDictionary *configuration for getting them. 
//  In order to change configuration values, use [self setConfigurationValue:forKey:]
//  This ensures that the configuration gets saved into the database properly.

#import "GrowlBoxcarPreferencePane.h"
#import "BoxcarDefines.h"

@interface GrowlBoxcarPreferencePane ()

@property (nonatomic, retain) NSMutableArray *connections;
@property (nonatomic, retain) NSString *testEmail;

@end

@implementation GrowlBoxcarPreferencePane

@synthesize errorMessage;
@synthesize validating;

@synthesize connections;
@synthesize testEmail;

-(id)initWithBundle:(NSBundle *)bundle {
	if((self = [super initWithBundle:bundle])){
		self.validating = NO;
		self.connections = [NSMutableArray array];
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
		keys = [[NSSet setWithObjects:@"emailAddress",
					@"prefixString",
					@"usePrefix",
					@"usePriority",
					@"minPriority",
					@"pushIdle", nil] retain];
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
	[self checkEmailAddress:[self emailAddress]];
}

-(void)checkEmailAddress:(NSString*)newAddress {
	if(!newAddress /*|| [[self emailAddress] isEqualToString:newAddress]*/ || [newAddress isEqualToString:@""]){
		return;
	}
	self.testEmail = newAddress;
	
	[self setConfigurationValue:newAddress forKey:BoxcarEmail];
	NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://boxcar.io/devices/providers/%@/notifications/subscribe", BoxcarProviderKey]];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:baseURL];
	NSString *email = [NSString stringWithFormat:@"email=%@", newAddress];
	NSData *data = [NSData dataWithBytes:[email UTF8String] length:[email lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:data];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];

	self.errorMessage = @"";
	self.validating = YES;
	
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request
																					  delegate:self
																			startImmediately:NO];
	[connections addObject:connection];
	[connection setDelegateQueue:[NSOperationQueue mainQueue]];
	[connection start];
	[connection release];
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

#pragma mark NSURLConnectionDelegate

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	if([response respondsToSelector:@selector(statusCode)]){
		NSInteger status = [(NSHTTPURLResponse*)response statusCode];
		switch (status) {
			case 200:
				//SUCCESS!
				self.errorMessage = NSLocalizedString(@"Registered!", @"Success adding boxcar");
				[self setConfigurationValue:self.testEmail forKey:BoxcarEmail];
				break;
			case 400:
				//Silly boxcar
				self.errorMessage = NSLocalizedString(@"Invalid Email", @"Failure adding email");
				[self willChangeValueForKey:@"emailAddress"];
				[self setConfigurationValue:nil forKey:BoxcarEmail];
				[self didChangeValueForKey:@"emailAddress"];
				NSLog(@"Boxcar no longer accepts hashes");
				break;
			case 401:
				//Already added!
				self.errorMessage = NSLocalizedString(@"Registered!", @"Success adding boxcar");
				break;
			case 404:
				//User unknown!
				self.errorMessage = NSLocalizedString(@"Unknown email", @"Failed adding boxcar, unknown email address");
				NSLog(@"User unknown, you will be contacted via email shortly");
				break;
			default:
				//Unknown response
				self.errorMessage = [NSString stringWithFormat:@"Error %lu", status];
				NSLog(@"Unknown response code from boxcar: %lu", status);
				break;
		}
	}else{
		NSLog(@"Error! Should be able to get a status code");
	}
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	NSLog(@"connection %@ failed with error %@", connection, error);
	[self willChangeValueForKey:@"emailAddress"];
	[self setConfigurationValue:nil forKey:BoxcarEmail];
	[self didChangeValueForKey:@"emailAddress"];
	[connections removeObject:connection];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
	self.validating = NO;
	self.testEmail = nil;
	[connections removeObject:connection];
}

@end
