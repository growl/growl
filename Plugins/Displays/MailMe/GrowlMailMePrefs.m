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
      self.recipientLabel = NSLocalizedString(@"Recipient:", @"Who the email of the notification should be sent to");
   }
   return self;
}

- (void)dealloc {
   [recipientLabel release];
   [super dealloc];
}

- (void)awakeFromNib {
   [[emailField cell] setPlaceholderString:NSLocalizedString(@"Your email here", @"Placeholder string in the recipient field")];
}

- (NSString *) mainNibName {
	return @"GrowlMailMePrefs";
}

- (void) didSelect {
	SYNCHRONIZE_GROWL_PREFS();
}

#pragma mark -

- (NSString *) getDestAddress {
	NSString *value = nil;
	READ_GROWL_PREF_VALUE(destAddressKey, @"com.Growl.MailMe", NSString *, &value);
	if(value) {
		CFMakeCollectable(value);
	}
	return [value autorelease];
}

- (void) setDestAddress:(NSString *)value {
	if (!value) {
		value = @"";
	}
	WRITE_GROWL_PREF_VALUE(destAddressKey, value, @"com.Growl.MailMe");
	UPDATE_GROWL_PREFS();
}

@end
