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
	NSString                *_domain;
    NSString				*_uuid;
	BOOL					_use;
	BOOL					_active;
    BOOL                    _manualEntry;
	
	NSString				*password;
	BOOL					didPasswordLookup;
	GrowlPreferencePane		*owner;
}
- (id) initWithDictionary:(NSDictionary *)dict;
- (id) initWithComputerName:(NSString *)name;

- (NSString *) password;
- (void) setPassword:(NSString *)password;

- (NSMutableDictionary *) properties;

- (void) setOwner:(GrowlPreferencePane *)pref;

@property (retain) NSString *uuid;
@property (retain) NSString *computerName;
@property (assign) BOOL use;
@property (assign) BOOL active;
@property (assign) BOOL manualEntry;
@property (retain) NSString *domain;
@end
