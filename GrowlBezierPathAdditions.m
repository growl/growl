//
//  GrowlBezierPathAdditions.m
//  Display Plugins
//
//  Created by Ingmar Stein on 17.11.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlBezierPathAdditions.h"

@implementation NSBezierPath(GrowlBezierPathAdditions)
+ (NSBezierPath *)roundedRectPath:(NSRect)rect radius:(float)radius lineWidth:(float)lineWidth
{
	float inset = radius + lineWidth;
	NSRect irect = NSInsetRect( rect, inset, inset );
	float minX = NSMinX( irect );
	float minY = NSMinY( irect );
	float maxX = NSMaxX( irect );
	float maxY = NSMaxY( irect );

	NSBezierPath *path = [NSBezierPath bezierPath];
	[path setLineWidth:lineWidth];

	[path appendBezierPathWithArcWithCenter:NSMakePoint( minX, minY )
									 radius:radius 
								 startAngle:180.f
								   endAngle:270.f];

	[path appendBezierPathWithArcWithCenter:NSMakePoint( maxX, minY ) 
									 radius:radius 
								 startAngle:270.f
								   endAngle:360.f];

	[path appendBezierPathWithArcWithCenter:NSMakePoint( maxX, maxY )
									 radius:radius 
								 startAngle:0.f
								   endAngle:90.f];

	[path appendBezierPathWithArcWithCenter:NSMakePoint( minX, maxY )
									 radius:radius 
								 startAngle:90.f
								   endAngle:180.f];

	[path closePath];

	return( path );
}

@end
