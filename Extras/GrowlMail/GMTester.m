//
//  GMTester.m
//  GrowlMail
//
//  Created by rudy on 8/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "GMTester.h"


@implementation GMTester

- (id)init
{
	if((self = [super init]))
	{
		NSBundle *main = [NSBundle mainBundle];
		NSString *path = [[main builtInPlugInsPath] stringByAppendingPathComponent:@"GrowlMail.mailbundle"];
		NSBundle *bundle = [NSBundle bundleWithPath:path];
		NSError *error = nil;
		[bundle loadAndReturnError:&error];
		NSLog(@"error: %@", error);
	}
	return self;
}

@end
