//
//  GrowlMailMePrefs.m
//  Display Plugins
//
//  Copyright 2004 Mac-arena the Bored Zo. All rights reserved.
//

#import "GrowlMailMePrefs.h"

static NSString *destAddressKey = @"MailMe - Recipient address";

@implementation GrowlMailMePrefs

- (NSString *) mainNibName {
	return @"GrowlMailMePrefs";
}

- (void) mainViewDidLoad {
	NSString *destAddress = nil;
	
	READ_GROWL_PREF_VALUE(destAddressKey, @"com.Growl.MailMe", NSString *, &destAddress);

	if (destAddress) {
		[destAddressField setStringValue:destAddress];
	}
}

- (void) didSelect {
	SYNCHRONIZE_GROWL_PREFS();
}

- (IBAction) preferenceChanged:(id)sender {
	// NSLog(@"preferenceChanged:%p called; destAddressField is %p", sender, destAddressField);
	WRITE_GROWL_PREF_VALUE(destAddressKey, [destAddressField stringValue], @"com.Growl.MailMe");

	UPDATE_GROWL_PREFS();
}

@end
