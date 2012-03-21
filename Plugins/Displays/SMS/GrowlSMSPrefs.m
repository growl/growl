//
//  GrowlSMSPrefs.m
//  Display Plugins
//
//  Created by Diggory Laycock
//  Copyright 2005–2011 The Growl Project All rights reserved.
//

#import "GrowlSMSPrefs.h"
#import "GrowlSMSDisplay.h"
#import "GrowlDefinesInternal.h"
#import "NSStringAdditions.h"
#import <GrowlPlugins/GrowlKeychainUtilities.h>

@implementation GrowlSMSPrefs

@synthesize smsNotifications;
@synthesize accountRequiredLabel;
@synthesize instructions;
@synthesize accountLabel;
@synthesize passwordLabel;
@synthesize apiIDLabel;
@synthesize destinationLabel;

- (id)initWithBundle:(NSBundle *)bundle {
   if((self = [super initWithBundle:bundle])){
      self.smsNotifications = NSLocalizedString(@"SMS Notifications", @"Title for SMS plugin");
      self.accountRequiredLabel = NSLocalizedString(@"(Clickatell.com account required.)", @"Warning that a clickatell.com account is required");
      self.instructions = NSLocalizedString(@"To register:\nhttp://www.clickatell.com/brochure/products/api_xml.php\n\nFor rates see:\nhttp://www.clickatell.com/brochure/pricing.php", @"Instructions for clickatell");
      self.accountLabel = NSLocalizedString(@"Account:", @"Label for account field");
      self.passwordLabel = NSLocalizedString(@"Password:", @"Label for password field");
      self.apiIDLabel = NSLocalizedString(@"API ID:", @"label for API ID field");
      self.destinationLabel = NSLocalizedString(@"Destination Number:", @"label for destination number field");
   }
   return self;
}

- (void)dealloc {
   [smsNotifications release];
   [accountRequiredLabel release];
   [instructions release];
   [accountLabel release];
   [passwordLabel release];
   [apiIDLabel release];
   [destinationLabel release];
   [super dealloc];
}

- (NSString *) mainNibName {
	return @"GrowlSMSPrefs";
}

- (NSSet*)bindingKeys {
	static NSSet *keys = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		keys = [[NSSet setWithObjects:@"accountName",
				  @"accountAPIID",
				  @"destinationNumber",
				  @"accountPassword", nil] retain];
	});
	return keys;
}

#pragma mark -

- (NSString *) getAccountName {
	return [self.configuration valueForKey:accountNameKey];
}

- (void) setAccountName:(NSString *)value {
	if (!value)
		value = @"";
	[self setConfigurationValue:value forKey:accountNameKey];
}


- (NSString *) getAccountAPIID {
	return [self.configuration valueForKey:accountAPIIDKey];
}

- (void) setAccountAPIID:(NSString *)value {
	if (!value)
		value = @"";
	[self setConfigurationValue:value forKey:accountAPIIDKey];
}


- (NSString *) getDestinationNumber {
	return [self.configuration valueForKey:destinationNumberKey];
}

- (void) setDestinationNumber:(NSString *)value {
	if (!value)
		value = @"";
	[self setConfigurationValue:value forKey:destinationNumberKey];
}


- (NSString *) accountPassword {
	return [GrowlKeychainUtilities passwordForServiceName:keychainServiceName accountName:self.configurationID];
}

- (void) setAccountPassword:(NSString *)value {
	[GrowlKeychainUtilities setPassword:value forService:keychainServiceName accountName:self.configurationID];
}

@end
