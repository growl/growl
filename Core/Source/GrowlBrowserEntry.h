//
//  GrowlBrowserEntry.h
//  Growl
//
//  Created by Ingmar Stein on 16.04.05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GrowlPreferencePane;

@interface GrowlBrowserEntry : NSObject {
	CFMutableDictionaryRef properties;
	NSString			   *password;
	BOOL				   didPasswordLookup;
	GrowlPreferencePane    *owner;
}
- (id) initWithDictionary:(NSDictionary *)dict;
- (id) initWithComputerName:(NSString *)name;

- (BOOL) use;
- (void) setUse:(BOOL)flag;

- (BOOL) active;
- (void) setActive:(BOOL)flag;

- (NSString *) computerName;
- (void) setComputerName:(NSString *)name;

- (NSString *) password;
- (void) setPassword:(NSString *)password;

- (NSDictionary *) properties;

- (void) setOwner:(GrowlPreferencePane *)pref;

@end
