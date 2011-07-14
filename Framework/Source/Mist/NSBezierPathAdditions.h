//
//  NSBezierPathAdditions.h
//  Trillian
//
//  Created by Rachel Blackman on 10/8/07.
//  Copyright 2007 Cerulean Studios. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSBezierPath (RoundedRect)
+ (NSBezierPath *)bezierPathWithRoundedRect:(NSRect)rect cornerRadius:(float)radius;
- (void)appendBezierPathWithRoundedRect:(NSRect)rect cornerRadius:(float)radius;
@end
