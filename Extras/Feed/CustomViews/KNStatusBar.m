//
//  KNStatusBar.m
//  Feed
//
//  Created by Keith on 2/4/06.
//  Copyright 2006 Keith Anderson. All rights reserved.
//

#import "KNStatusBar.h"


@implementation KNStatusBar

static void linearGradientBackgroundShadingValues(void *info, const float *in, float *out);
static void linearGradientBackgroundShadingValues(void *info, const float *in, float *out){
	float *colors = (float *)info;
	
	register float a = in[0];
	register float a_coeff = 1.0f - a;
	
	out[0] = a_coeff * colors[4] + a * colors[0];
	out[1] = a_coeff * colors[5] + a * colors[1];
	out[2] = a_coeff * colors[6] + a * colors[2];
	out[3] = a_coeff * colors[7] + a * colors[3];
}


- (void)drawRect:(NSRect)dirtyRect {
#pragma unused( dirtyRect )
	NSRect								rect = [self bounds];
    CGContextRef						context = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];
	CGRect								bounds = CGRectMake( rect.origin.x, rect.origin.y, rect.size.width, rect.size.height );
		
	CGContextSaveGState( context );
	
	CGContextAddRect( context, bounds );
	CGContextClip( context );
	
	CGColorSpaceRef						colorspace = CGColorSpaceCreateDeviceRGB();
	
	// These points define a vertical, upward gradient
	CGPoint								endPoint = CGPointMake(CGRectGetMinX(bounds), CGRectGetMaxY(bounds));
	CGPoint								startPoint = CGPointMake(CGRectGetMinX(bounds), CGRectGetMinY(bounds));
	static float						colors[8];
	
	[[[NSColor controlHighlightColor] colorUsingColorSpaceName: NSCalibratedRGBColorSpace]
		getRed:&colors[0] green: &colors[1] blue: &colors[2] alpha: &colors[3]
	];
	[[[NSColor headerColor] colorUsingColorSpaceName: NSCalibratedRGBColorSpace]
		getRed:&colors[4] green: &colors[5] blue: &colors[6] alpha: &colors[7]
	];
	
	static const CGFunctionCallbacks	callbacks = {0U, linearGradientBackgroundShadingValues, NULL };
	CGFunctionRef						function = CGFunctionCreate( (void *)colors, 1U, NULL, 4U, NULL, &callbacks );
	CGShadingRef						shader = CGShadingCreateAxial( colorspace, startPoint, endPoint, function, false, false );
	
	CGContextDrawShading( context, shader );
	
	CGShadingRelease( shader );
	CGColorSpaceRelease( colorspace );
	CGFunctionRelease( function );
	
	CGContextRestoreGState( context );
	
	// Draw the borders
	//[[NSColor windowFrameColor] set];
	//[[NSColor blackColor] set];
	//NSRectFill( NSMakeRect( rect.origin.x, rect.origin.y, rect.size.width, 1.0f ) );
	//NSRectFill( NSMakeRect( rect.origin.x, rect.origin.y + (rect.size.height + 1.0), rect.size.width, 1.0f ) );
}

@end
