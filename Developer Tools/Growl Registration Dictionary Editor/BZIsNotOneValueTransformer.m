//
//  BZIsNotOneValueTransformer.m
//  Growl Registration Dictionary Editor
//
//  Created by Peter Hosey on 2006-04-15.
//  Copyright 2006 Peter Hosey. All rights reserved.
//

#import "BZIsNotOneValueTransformer.h"

static BZIsNotOneValueTransformer *singleton = nil;

@implementation BZIsNotOneValueTransformer

+ (void)load {
	singleton = [[BZIsNotOneValueTransformer alloc] init];
	[self setValueTransformer:singleton forName:@"BZIsNotOneValueTransformer"];
}

- transformedValue:num {
	if(![num respondsToSelector:@selector(intValue)])
		return [NSNumber numberWithBool:YES]; //Not a number? Must not be one, then.
	return [NSNumber numberWithBool:[num intValue] != 1];
}

@end
