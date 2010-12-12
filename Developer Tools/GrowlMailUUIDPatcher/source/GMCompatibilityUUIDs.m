//
//  GMCompatibilityUUIDs.m
//  GrowlMailUUIDPatcher
//
//  Created by Peter Hosey on 2010-11-12.
//  Copyright 2010 The Growl Project. All rights reserved.
//

#import "GMCompatibilityUUIDs.h"

static NSString *GMPluginCompatibilityUUIDForBundle(NSBundle *bundle) {
	return [bundle objectForInfoDictionaryKey:@"PluginCompatibilityUUID"];
}

NSString *GMCurrentMailCompatibilityUUID(void) {
	static NSString *mailUUID = nil;
	if (!mailUUID)
		mailUUID = [GMPluginCompatibilityUUIDForBundle([NSBundle bundleWithURL:[NSURL fileURLWithPath:@"/Applications/Mail.app"]]) copy];
	return mailUUID;
}
NSString *GMCurrentMessageFrameworkCompatibilityUUID(void) {
	static NSString *messageFrameworkUUID = nil;
	if (!messageFrameworkUUID)
		messageFrameworkUUID = [GMPluginCompatibilityUUIDForBundle([NSBundle bundleWithURL:[NSURL fileURLWithPath:@"/System/Library/Frameworks/Message.framework"]]) copy];
	return messageFrameworkUUID;
}
