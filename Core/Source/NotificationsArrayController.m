//
//  NotificationsArrayController.m
//  Growl
//
//  Created by Evan Schoenberg on 12/24/05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "NotificationsArrayController.h"


@implementation NotificationsArrayController
- (NSArray *) arrangeObjects:(NSArray *)objects {
	return [super arrangeObjects:[objects sortedArrayUsingSelector:@selector(humanReadableNameCompare:)]];

}
@end
