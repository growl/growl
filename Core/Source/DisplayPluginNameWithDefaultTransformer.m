//
//  DisplayPluginNameWithDefaultTransformer.m
//  Growl
//
//  Created by Evan Schoenberg on 8/18/07.
//

#import "DisplayPluginNameWithDefaultTransformer.h"


@implementation DisplayPluginNameWithDefaultTransformer
+ (void)load
{
	if (self == [DisplayPluginNameWithDefaultTransformer class]) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[self setValueTransformer:[[[DisplayPluginNameWithDefaultTransformer alloc] init] autorelease]
						  forName:@"DisplayPluginNameWithDefaultTransformer"];
		[pool release];
	}
}

+ (Class)transformedValueClass
{ 
	return [NSArray class];
}

+ (BOOL)allowsReverseTransformation
{
	return YES;
}

- (id)transformedValue:(id)value
{
	if ([value isKindOfClass:[NSArray class]]) {
		NSMutableArray *transformedArray = [[value mutableCopy] autorelease];
		[transformedArray replaceObjectAtIndex:[transformedArray indexOfObject:[NSNull null]]
									withObject:NSLocalizedString(@"Default", nil)];
		
		return transformedArray;

	} else if (!value ||
			   [value isKindOfClass:[NSNull class]]) {
		//A nil or NSNull value is the default itself
		return NSLocalizedString(@"Default", nil);

	} else {
		return value;
	}
}

- (id)reverseTransformedValue:(id)value
{	
	if ([value isKindOfClass:[NSString class]]) {
		return ([value isEqualToString:NSLocalizedString(@"Default", nil)] ? nil : value);
	} else {
		//We don't need to reverse transform the array
		return value;
	}
}

@end
