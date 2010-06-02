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
	
	NSString				*_name;
	NSString				*_uuid;
	BOOL					_use;
	BOOL					_active;
	
	NSString				*password;
	BOOL					didPasswordLookup;
	GrowlPreferencePane		*owner;
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

- (NSMutableDictionary *) properties;

- (void) setOwner:(GrowlPreferencePane *)pref;

@property (retain) NSString *uuid;
@property (retain) NSString *computerName;
@property (assign) BOOL use;
@property (assign) BOOL active;
@end
