//
//  PriorityTransformer.m
//  Growl
//
//  Created by Evan Schoenberg on 6/21/07.
//

#import "PriorityTransformer.h"
#import "GrowlNotificationTicket.h"

@implementation PriorityTransformer
+ (void)load
{
	if (self == [PriorityTransformer class]) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[self setValueTransformer:[[[PriorityTransformer alloc] init] autorelease]
						  forName:@"PriorityTransformer"];
		[pool release];
	}
}

+ (Class)transformedValueClass
{ 
	return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation
{
	return YES;
}

- (id)transformedValue:(id)value
{
    if ([value isKindOfClass:[NSNumber class]] && ([value intValue] == GrowlPriorityUnset))
		value = [NSNumber numberWithInt:GrowlPriorityNormal];
	
	return value;
}

@end
