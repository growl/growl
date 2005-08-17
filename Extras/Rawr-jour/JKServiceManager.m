//
//  JKServiceManager.m
//  Rawr-endezvous
//
//  Created by Jeremy Knope on 9/17/04.
//  Copyright 2004 Jeremy Knope. All rights reserved.
//

#import "JKServiceManager.h"
#import "JKPreferencesController.h"
#import <Growl/Growl.h>
//#import <GrowlAppBridge/GrowlApplicationBridge.h>

@implementation JKServiceManager
/*
+ (JKServiceManager *)serviceManagerForProtocols:(NSArray *)protos {
	return [[[JKServiceManager alloc] initWithProtocols:protos] autorelease];
}
*/
+ (JKServiceManager *)serviceManagerForPreferences:(JKPreferencesController *)newPrefs {
    return [[[JKServiceManager alloc] initWithPreferences:newPrefs] autorelease];
}
- (id)initWithPreferences:(JKPreferencesController *)newPrefs {
    [super init];
    if (self) {
        prefs = [newPrefs retain];
        serviceBrowserLinks = [[[NSMutableDictionary alloc] init] retain];
        foundServices = [[[NSMutableDictionary alloc] init] retain];
        [self setProtocols:[prefs getServices]];
    }
    return self;
}
/*
- (id)initWithProtocols:(NSArray *)protos {
	[super init];
	serviceBrowserLinks = [[[NSMutableDictionary alloc] init] retain];
	foundServices = [[[NSMutableDictionary alloc] init] retain];
	[self setProtocols:protos];
	
	return self;
}
*/
- (id)init {
	[super init];
	protocolNames = nil;
	serviceBrowserLinks = [[[NSMutableDictionary alloc] init] retain];
	foundServices = [[NSMutableDictionary dictionaryWithCapacity:1] retain];
	return self;
}

- (void)dealloc {
	if(protocolNames)
		[protocolNames release];
	[serviceBrowserLinks release];
	[foundServices release];
	[super dealloc];
}

- (void)setProtocols:(NSArray *)protos {
	if(protocolNames)
		[protocolNames release];
	protocolNames = [protos retain];
	[self refreshServices];
}

- (NSDictionary *)getProtocolNames {
	NSMutableDictionary *temp;
	id aProtocol;
	NSEnumerator *en = [[prefs getServices] objectEnumerator];
	temp = [NSMutableDictionary dictionaryWithCapacity:1];
	while(aProtocol = [en nextObject]) {
		[temp setObject:aProtocol forKey:[aProtocol objectForKey:@"service"]];
	}
	return temp;
}

- (void)refreshServices {
	id aProtocol;
	//id aBrowser;
	NSNetServiceBrowser *newBrowser;
	
	//[browsers makeObjectsPerformSelector:@selector(stop)];
	//[browsers removeAllObjects];
	//NSEnumerator * enumerator = [protocolNames objectEnumerator];
    NSEnumerator * enumerator = [[prefs getServices] objectEnumerator];
    
    while(aProtocol = [enumerator nextObject]) {
		if([serviceBrowserLinks objectForKey:[aProtocol objectForKey:@"service"]] == nil) {
			newBrowser = [[NSNetServiceBrowser alloc] init];
			[newBrowser setDelegate:self];
			[newBrowser searchForServicesOfType:[aProtocol objectForKey:@"service"] inDomain:@""];
			[serviceBrowserLinks setObject:newBrowser forKey:[aProtocol objectForKey:@"service"]];
			[browsers addObject:newBrowser];
		} // else already have a browser for that service... 
	}
	// find removed services
	NSEnumerator *en = [serviceBrowserLinks keyEnumerator];
	id aKey;
	int i;
	BOOL foundKey;

	while(aKey = [en nextObject]) { // for every key, a service type...
		foundKey = NO;
		// every damn protcol name...
		//NSLog(@"Going thru names comparing");
		for(i = 0; (i < [[prefs getServices] count]) && !foundKey; i++) {
            //NSLog(@"Comparing %@ with %@",aKey,[[[prefs getServices] objectAtIndex:i] objectForKey:@"service"]);
			if([aKey isEqualToString:[[[prefs getServices] objectAtIndex:i] objectForKey:@"service"]]) {
				foundKey = YES;
				//break;
			}
		}
		if(!foundKey) {
			[(NSNetServiceBrowser *)[serviceBrowserLinks objectForKey:aKey] stop];
			[serviceBrowserLinks removeObjectForKey:aKey];
			// we need to loop thru and send out removals for each service of said type
			for(i = 0; i < [[foundServices objectForKey:aKey] count]; i++) {
				//NSLog(@"Notifying of gone service: %@",[[[foundServices objectForKey:aKey] objectAtIndex:i] name]);
				[[NSNotificationCenter defaultCenter] postNotificationName:@"RawrEndezvousRemoveService" object:[[foundServices objectForKey:aKey] objectAtIndex:i]];
			}
			[foundServices removeObjectForKey:aKey];
		}
	}
}

// This object is the delegate of its NSNetServiceBrowser object. We're only interested in services-related methods, so that's what we'll call.
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    if(DEBUG)
        NSLog(@"JKServiceManager:: Found service: %@ of type: %@",[aNetService name],[aNetService type]);
    // ** notify!
	//NSLog(@"Checking foundServices for type");
	//if(foundServices == nil)
	//	NSLog(@"Found services is nil, WTF");
	
	if([foundServices objectForKey:[aNetService type]] == nil) {
		//NSLog(@"appears to be nil, adding array");
		[foundServices setObject:[NSMutableArray arrayWithCapacity:1] forKey:[aNetService type]];
	}
	
	//NSLog(@"Adding to array, expecting one there");
	[[foundServices objectForKey:[aNetService type]] addObject:aNetService];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"RawrEndezvousNewService" object:aNetService];
}


- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    // This case is slightly more complicated. We need to find the object in the list and remove it.
    //NSLog(@"JKServiceManager:: Removing service: %@",[aNetService name]);
	if([foundServices objectForKey:[aNetService type]] != nil)
		[[foundServices objectForKey:[aNetService type]] removeObject:aNetService];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"RawrEndezvousRemoveService" object:aNetService];
	/*
	NSEnumerator * enumerator = [services objectEnumerator];
    NSNetService * currentNetService;

    while(currentNetService = [enumerator nextObject]) {
        if ([currentNetService isEqual:aNetService]) {
            [services removeObject:currentNetService];
            break;
        }
    }
    // ** notify app of gone service
	
	//[theMain removeService:aNetService];
    
    if (serviceBeingResolved && [serviceBeingResolved isEqual:aNetService]) {
        [serviceBeingResolved stop];
        [serviceBeingResolved release];
        serviceBeingResolved = nil;
    }
	*/
    /*if(!moreComing) {
        [pictureServiceList reloadData];        
    }*/
}

@end
