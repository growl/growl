//
//  GrowlBezierPathAdditions.c
//  Display Plugins
//
//  Created by Ingmar Stein on 17.11.04.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#include "GrowlBezierPathAdditions.h"

void addRoundedRectToPath(CGContextRef context, CGRect rect, float radius) {
	float minX = CGRectGetMinX(rect);
	float minY = CGRectGetMinY(rect);
	float maxX = CGRectGetMaxX(rect);
	float maxY = CGRectGetMaxY(rect);
	float midX = CGRectGetMidX(rect);
	float midY = CGRectGetMidY(rect);

	CGContextBeginPath(context);
	CGContextMoveToPoint(context, maxX, midY);
	CGContextAddArcToPoint(context, maxX, maxY, midX, maxY, radius);
	CGContextAddArcToPoint(context, minX, maxY, minX, midY, radius);
	CGContextAddArcToPoint(context, minX, minY, midX, minY, radius);
	CGContextAddArcToPoint(context, maxX, minY, maxX, midY, radius);
	CGContextClosePath(context);
}
