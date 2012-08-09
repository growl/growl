//
//  GrowlBrowserEntry.h
//  Growl
//
//  Created by Ingmar Stein on 16.04.05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GNTPForwarder, GNTPKey;

@interface GrowlBrowserEntry : NSObject {
	
	NSString				*_name;
	NSString          *_domain;
   NSString				*_uuid;
	BOOL					_use;
	BOOL					_active;
   BOOL              _manualEntry;
	
	NSString				*password;
   GNTPKey           *_key;
	BOOL					didPasswordLookup;
	GNTPForwarder		*owner;
   
   NSData            *_lastKnownAddress;
}
- (id) initWithDictionary:(NSDictionary *)dict;
- (id) initWithComputerName:(NSString *)name;

- (void)updateKey;
- (NSString *) password;
- (void) setPassword:(NSString *)password;

- (NSMutableDictionary *) properties;

- (void) setOwner:(GNTPForwarder *)pref;

@property (retain) NSString *uuid;
@property (nonatomic, retain) NSString *computerName;
@property (nonatomic, assign) BOOL use;
@property (nonatomic, assign) BOOL active;
@property (assign) BOOL manualEntry;
@property (retain) NSString *domain;
@property (retain) GNTPKey *key;
@property (nonatomic, retain) NSData *lastKnownAddress;
@end
