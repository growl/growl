//
//  NSAdditions.m
//  Growl
//
//  Created by Karl Adam on Fri May 28 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "NSGrowlAdditions.h"


@implementation NSWorkspace (GrowlAdditions)
- (NSImage *) iconForApplication:(NSString *) inName {
	NSString *path = [self fullPathForApplication:inName];
	NSLog(@"Pulled icon for %@ from path: %@",inName,path);
	return [self iconForFile:path];
}
@end

