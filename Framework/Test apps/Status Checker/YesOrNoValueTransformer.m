//
//  YesOrNoValueTransformer.m
//  Status Checker
//
//  Created by Peter Hosey on 2009-08-07.
//  Copyright 2009 Peter Hosey. All rights reserved.
//

#import "YesOrNoValueTransformer.h"

@implementation YesOrNoValueTransformer

+ (Class) transformedValueClass {
	return [NSObject class];
}
+ (BOOL) allowsReverseTransformation {
	return YES;
}

- (id)transformedValue:(id)value {
	NSNumber *boolNum = value;
	return [boolNum boolValue] ? self.yesObject : self.noObject;
}
- (id)reverseTransformedValue:(id)value {
	if (value == self.yesObject)
		return [NSNumber numberWithBool:YES];
	else if (value == self.noObject)
		return [NSNumber numberWithBool:NO];
	else
		return nil;
}

@synthesize yesObject;
@synthesize noObject;

@end
