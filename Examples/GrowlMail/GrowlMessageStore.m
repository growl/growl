//
//  GrowlMailStore.m
//  GrowlMail
//
//  Created by Ingmar Stein on 27.10.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlMessageStore.h"
#import "Message+GrowlMail.h"

@implementation GrowlMessageStore
+ (void)load
{
    [GrowlMessageStore poseAsClass:[MessageStore class]];
}

- (id)finishRoutingMessages:(NSArray *)messages routed:(NSArray *)routed
{	
	Message *message;
	Class tocClass = [TOCMessage class];
	NSEnumerator *e = [messages objectEnumerator];
	while( (message = [e nextObject]) ) {
//		NSLog( @"Message class: %@", [message className] );
		if( ![message isKindOfClass: tocClass] ) {
			[message showNotification];
		}
	}

	return [super finishRoutingMessages: messages routed: routed];
}

@end
