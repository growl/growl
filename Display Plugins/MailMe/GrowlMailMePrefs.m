//
//  GrowlMailMePrefs.m
//  Display Plugins
//
//  Copyright 2004 Mac-arena the Bored Zo. All rights reserved.
//

#import "GrowlMailMePrefs.h"
#import <GrowlDefinesInternal.h>

#define destAddressKey @"MailMe - Recipient address"

@implementation GrowlMailMePrefs

- (NSString *) mainNibName {
	return @"GrowlMailMePrefs";
}

- (void) mainViewDidLoad {
	NSString *destAddressPref = nil;
	READ_GROWL_PREF_VALUE(destAddressKey, @"com.Growl.MailMe", NSString *, &destAddressPref);
	if (!destAddressPref) {
		destAddressPref = @"";
	}
	destAddress = [[NSMutableString alloc] initWithString:destAddressPref];
	[self setDestAddress:destAddress];
}

- (void) dealloc {
	[destAddress release];
	[super dealloc];
}

- (void) didSelect {
	SYNCHRONIZE_GROWL_PREFS();
}

#pragma mark -

- (NSString *) getDestAddress {
	return [destAddress length] ? destAddress : nil;
}

- (void) setDestAddress:(NSString *)value {
	if (![destAddress isEqualToString:value]) {
		if (!value) {
			value = @"";
		}
		[destAddress setString:value];
		WRITE_GROWL_PREF_VALUE(destAddressKey, value, @"com.Growl.MailMe");
		UPDATE_GROWL_PREFS();
	}
}

@end
