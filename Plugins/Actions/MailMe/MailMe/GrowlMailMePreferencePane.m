//
//  GrowlMailMePreferencePane.m
//  MailMe
//
//  Created by Daniel Siemer on 4/12/12.
//
//  This class represents your plugin's preference pane.  There will be only one instance, but possibly many configurations
//  In order to access a configuration values, use the NSMutableDictionary *configuration for getting them. 
//  In order to change configuration values, use [self setConfigurationValue:forKey:]
//  This ensures that the configuration gets saved into the database properly.

#import "GrowlMailMePreferencePane.h"
#import "SMTPClient.h"
#import <GrowlPlugins/GrowlKeychainUtilities.h>

@interface GrowlMailMePreferencePane ()

@property (nonatomic, retain) NSString *serverAddress;
@property (nonatomic, retain) NSString *serverPorts;
@property (nonatomic) NSInteger serverTlsMode;
@property (nonatomic) BOOL serverAuthFlag;
@property (nonatomic, retain) NSString *serverAuthUsername;
@property (nonatomic, retain) NSString *serverAuthPassword;
@property (nonatomic, retain) NSString *messageFrom;
@property (nonatomic, retain) NSString *messageTo;
@property (nonatomic, retain) NSString *messageSubject;

@end

@implementation GrowlMailMePreferencePane

@synthesize serverAddress;
@synthesize serverPorts;
@synthesize serverTlsMode;
@synthesize serverAuthFlag;
@synthesize serverAuthUsername;
@synthesize serverAuthPassword;
@synthesize messageFrom;
@synthesize messageTo;
@synthesize messageSubject;

-(NSString*)mainNibName {
	return @"MailMePrefPane";
}

/* This returns the set of keys the preference pane needs updated via bindings 
 * This is called by GrowlPluginPreferencePane when it has had its configuration swapped
 * Since we really only need a fixed set of keys updated, use dispatch_once to create the set
 */
- (NSSet*)bindingKeys {
	static NSSet *keys = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		keys = [[NSSet setWithObjects:@"serverAddress",
					@"serverPorts",
					@"serverTlsMode",
					@"serverAuthFlag",
					@"serverAuthUsername",
					@"serverAuthPassword",
					@"messageFrom",
					@"messageTo",
					@"messageSubject", nil] retain];
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

-(NSString*)serverAddress {
	return [self.configuration valueForKey:SMTPServerAddressKey];
}
-(void)setServerAddress:(NSString*)value {
	if(value.length == 0)
		value = nil;
	[self setConfigurationValue:value forKey:SMTPServerAddressKey];
}

-(NSString*)serverPorts {
	return [self.configuration valueForKey:SMTPServerPortsKey];
}
-(void)setServerPorts:(NSString*)value {
	if(value.length == 0)
		value = nil;
	[self setConfigurationValue:value forKey:SMTPServerPortsKey];
}

-(NSInteger)serverTlsMode {
	NSInteger value = SMTPClientTLSModeTLSIfPossible;
	if([self.configuration valueForKey:SMTPServerTLSModeKey])
		value = [[self.configuration valueForKey:SMTPServerTLSModeKey] integerValue];
	return value;
}
-(void)setServerTlsMode:(NSInteger)value {
	[self setConfigurationValue:[NSNumber numberWithInteger:value] forKey:SMTPServerTLSModeKey];
}

-(BOOL)serverAuthFlag {
	BOOL value = NO;
	if([self.configuration valueForKey:SMTPServerAuthFlagKey])
		value = [[self.configuration valueForKey:SMTPServerAuthFlagKey] boolValue];
	return value;
}
-(void)setServerAuthFlag:(BOOL)value {
	[self setConfigurationValue:[NSNumber numberWithBool:value] forKey:SMTPServerAuthFlagKey];
}

-(NSString*)serverAuthUsername {
	return [self.configuration valueForKey:SMTPServerAuthUsernameKey];
}
-(void)setServerAuthUsername:(NSString*)value {
	if(value.length == 0)
		value = nil;
	[self setConfigurationValue:value forKey:SMTPServerAuthUsernameKey];
}

-(NSString*)serverAuthPassword {
	return [GrowlKeychainUtilities passwordForServiceName:@"Growl-MailMe" accountName:[self configurationID]];
}
-(void)setServerAuthPassword:(NSString*)value {
	[GrowlKeychainUtilities setPassword:value forService:@"Growl-MailMe" accountName:[self configurationID]];
}

-(NSString*)messageFrom {
	return [self.configuration valueForKey:SMTPFromKey];
}
-(void)setMessageFrom:(NSString*)value {
	if(value.length == 0)
		value = nil;
	[self setConfigurationValue:value forKey:SMTPFromKey];
}

-(NSString*)messageTo {
	return [self.configuration valueForKey:SMTPToKey];
}
-(void)setMessageTo:(NSString*)value {
	if(value.length == 0)
		value = nil;
	[self setConfigurationValue:value forKey:SMTPToKey];
}

-(NSString*)messageSubject {
	return [self.configuration valueForKey:SMTPSubjectKey];
}
-(void)setMessageSubject:(NSString*)value {
	if(value.length == 0)
		value = nil;
	[self setConfigurationValue:value forKey:SMTPSubjectKey];
}

@end
