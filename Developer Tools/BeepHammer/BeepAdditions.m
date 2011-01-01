//
//  BeepAdditions.m
//  Beep-Cocoa
//
//  Created by Peter Hosey on 2004-12-06.
//

#import "BeepAdditions.h"


@implementation NSDictionary(BeepAdditions)

- (int)stateForKey:(NSString *)key {
	static int states[] = { NSOffState, NSOnState };
	return states[[[self objectForKey:key] boolValue] != NO];
}

@end
