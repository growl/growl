//
//  GrowlBezierPathAdditions.h
//  Display Plugins
//
//  Created by Ingmar Stein on 17.11.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSBezierPath(GrowlBezierPathAdditions)
+ (NSBezierPath *)bezierPathWithRoundedRect:(NSRect)rect radius:(float)radius;
@end
