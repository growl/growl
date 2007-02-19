//
//  BZIsLessThanOrEqualToOneValueTransformer.m
//  Growl Registration Dictionary Editor
//
//  Created by Peter Hosey on 2006-04-15.
//  Copyright 2006 Peter Hosey. All rights reserved.
//

#import "BZIsLessThanOrEqualToOneValueTransformer.h"

static BZIsLessThanOrEqualToOneValueTransformer *singleton = nil;

@implementation BZIsLessThanOrEqualToOneValueTransformer

+ (void)load {
	singleton = [[BZIsLessThanOrEqualToOneValueTransformer alloc] init];
	[self setValueTransformer:singleton forName:@"BZIsLessThanOrEqualToOneValueTransformer"];
}

- transformedValue:num {
	if(![num respondsToSelector:@selector(intValue)])
		return [NSNumber numberWithBool:NO]; //Not a number? Doesn't compare to 1.
	return [NSNumber numberWithBool:[num intValue] <= 1];
}

@end
