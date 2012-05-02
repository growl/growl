//
//  GrowlPositionColumn.m
//  PositionController
//
//  Created by Daniel Siemer on 3/26/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "GrowlPositionColumn.h"

@implementation GrowlPositionColumn

@synthesize xOrigin;
@synthesize width;
@synthesize rects;

-(void)dealloc {
	[rects release];
	[super dealloc];
}

-(void)addWidth:(CGFloat)newWidth {
	NSNumber *number = [NSNumber numberWithFloat:newWidth];
	if(!rects)
		self.rects = [NSMutableArray array];
	[rects addObject:number];
}

-(void)removeWidth:(CGFloat)oldWidth {
	NSNumber *number = [NSNumber numberWithFloat:oldWidth];
	NSUInteger result = [rects indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
		if([number isEqualToNumber:obj])
			return YES;
		return NO;
	}];
	if(result != NSNotFound)
		[rects removeObjectAtIndex:result];
}

-(CGFloat)minWidth {
	__block CGFloat result = 0.0f;
	[rects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if([obj floatValue] > result)
			result = [obj floatValue];
	}];
	if(result > 0.0f)
		result += 2.0f;
	return result;
}

@end
