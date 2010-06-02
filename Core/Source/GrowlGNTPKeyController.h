//
//  GrowlGNTPKeyController.h
//  Growl
//
//  Created by Rudy Richter on 10/10/09.
//  Copyright 2009 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GNTPKey.h"

@interface GrowlGNTPKeyController : GrowlAbstractSingletonObject
{
	NSMutableDictionary *_storage;
}

- (void)setKey:(GNTPKey*)key forUUID:(NSString*)uuid;
- (GNTPKey*)keyForUUID:(NSString*)uuid;

@end
