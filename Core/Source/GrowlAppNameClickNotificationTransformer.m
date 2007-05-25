//
//  GrowlAppNameClickNotificationTransformer.m
//  Growl
//
//  Created by Evan Schoenberg on 5/25/07.
//

#import "GrowlAppNameClickNotificationTransformer.h"


@implementation GrowlAppNameClickNotificationTransformer
+ (void)load
{
	if (self == [GrowlAppNameClickNotificationTransformer class]) {
		[self setValueTransformer:[[[self alloc] init] autorelease]
						  forName:@"GrowlAppNameClickNotificationTransformer"];
	}
}

+ (Class)transformedValueClass 
{ 
	return [NSString class];
}
+ (BOOL)allowsReverseTransformation
{
	return NO;
}
- (id)transformedValue:(id)value
{
	return (value ? [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Inform %@ when a notification is clicked", nil, [NSBundle bundleForClass:[self class]], nil), value] : nil);
}
@end
