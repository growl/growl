//
//  BZIsNotZeroValueTransformer.m
//  Growl Registration Dictionary Editor
//
//  Created by Peter Hosey on 2006-04-15.
//  Copyright 2006 Peter Hosey. All rights reserved.
//

#import "BZIsNotZeroValueTransformer.h"

static BZIsNotZeroValueTransformer *singleton = nil;

@implementation BZIsNotZeroValueTransformer

+ (void)load {
	singleton = [[BZIsNotZeroValueTransformer alloc] init];
	[self setValueTransformer:singleton forName:@"BZIsNotZeroValueTransformer"];
}

- transformedValue:num {
	if(![num respondsToSelector:@selector(intValue)])
		return [NSNumber numberWithBool:YES]; //Not a number? Must not be zero, then.
	return [NSNumber numberWithBool:[num intValue] != 0];
}

@end
