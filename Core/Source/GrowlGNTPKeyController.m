//
//  GrowlGNTPKeyController.m
//  Growl
//
//  Created by Rudy Richter on 10/10/09.
//  Copyright 2009 The Growl Project. All rights reserved.
//

#import "GrowlGNTPKeyController.h"
#import "GNTPKey.h"

@implementation GrowlGNTPKeyController

- (id) initSingleton {
	if ((self = [super initSingleton])) 
	{
		_storage = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)setKey:(GNTPKey*)key forUUID:(NSString*)uuid
{
	[_storage setValue:key forKey:uuid];
}

- (GNTPKey*)keyForUUID:(NSString*)uuid
{
	return [_storage valueForKey:uuid];
}

@end
