//
//  GrowlMailMePrefs.m
//  Display Plugins
//
//  Copyright 2004 Peter Hosey. All rights reserved.
//

#import "GrowlMailMePrefs.h"
#import "GrowlDefinesInternal.h"

#define destAddressKey @"MailMe - Recipient address"

@implementation GrowlMailMePrefs

@synthesize recipientLabel;
@synthesize emailField;

- (id)initWithBundle:(NSBundle *)bundle {
   if((self = [super initWithBundle:bundle])){
      self.recipientLabel = NSLocalizedStringFromTableInBundle(@"Recipient:", @"Localizable", bundle, @"Who the email of the notification should be sent to");
   }
   return self;
}

- (void)dealloc {
   [recipientLabel release];
   [super dealloc];
}

- (void)awakeFromNib {
   [[emailField cell] setPlaceholderString:NSLocalizedStringFromTableInBundle(@"Your email here", @"Localizable", [NSBundle bundleForClass:[self class]], @"Placeholder string in the recipient field")];
}

- (NSString *) mainNibName {
	return @"GrowlMailMePrefs";
}

- (NSSet*)bindingKeys {
	return [NSSet setWithObject:@"destAddress"];
}

#pragma mark -

- (NSString *) getDestAddress {
	return [self.configuration valueForKey:destAddressKey];
}

- (void) setDestAddress:(NSString *)value {
	if (!value) {
		value = @"";
	}
	[self setConfigurationValue:value forKey:destAddressKey];
}

@end
