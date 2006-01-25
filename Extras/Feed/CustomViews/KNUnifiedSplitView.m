/*

BSD License

Copyright (c) 2006, Keith Anderson
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

*	Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.
*	Redistributions in binary form must reproduce the above copyright notice,
	this list of conditions and the following disclaimer in the documentation
	and/or other materials provided with the distribution.
*	Neither the name of keeto.net or Keith Anderson nor the names of its
	contributors may be used to endorse or promote products derived
	from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


*/

#import "KNUnifiedSplitView.h"

#define UNIFIED_SPLIT_VIEW_DIVIDER_THICKNESS 9.0f
#define UNIFIED_SPLIT_VIEW_THUMB_WIDTH 5.0f

@implementation KNUnifiedSplitView

-(float)dividerThickness{
	return UNIFIED_SPLIT_VIEW_DIVIDER_THICKNESS;
}

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
-(void)drawDividerInRect:(NSRect)aRect{
	CGContextRef						context = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];
	CGRect								bounds = CGRectMake( aRect.origin.x, aRect.origin.y, aRect.size.width, aRect.size.height );
	
	CGContextAddRect( context, bounds );
	CGContextSaveGState( context );
	CGContextClip( context );
	
	CGColorSpaceRef						colorspace = CGColorSpaceCreateDeviceRGB();
	
	// These points define a vertical, upward gradient
	CGPoint								endPoint = CGPointMake(CGRectGetMinX(bounds), CGRectGetMaxY(bounds));
	CGPoint								startPoint = CGPointMake(CGRectGetMinX(bounds), CGRectGetMinY(bounds));
	static float						colors[8];
	
	[[[NSColor headerColor] colorUsingColorSpaceName: NSCalibratedRGBColorSpace]
		getRed:&colors[0] green: &colors[1] blue: &colors[2] alpha: &colors[3]
	];
	[[[NSColor controlLightHighlightColor] colorUsingColorSpaceName: NSCalibratedRGBColorSpace]
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
	[[NSColor windowFrameColor] set];
	NSRectFill( NSMakeRect( aRect.origin.x, aRect.origin.y, aRect.size.width, 1.0f ) );
	NSRectFill( NSMakeRect( aRect.origin.x, aRect.origin.y + aRect.size.height - 1, aRect.size.width, 1.0f ) );
	
	// Draw the thumb
	//[[NSColor blackColor] set];
	NSRectFill( 
		NSMakeRect( aRect.origin.x + ((aRect.size.width - UNIFIED_SPLIT_VIEW_THUMB_WIDTH) / 2.0),
					aRect.origin.y + ceil(((aRect.size.height - 2.0) / 3)),
					UNIFIED_SPLIT_VIEW_THUMB_WIDTH,
					1.0f
		)
	);
	NSRectFill(
		NSMakeRect( aRect.origin.x + ((aRect.size.width - UNIFIED_SPLIT_VIEW_THUMB_WIDTH) / 2.0),
					aRect.origin.y + ceil((2.0 * ((aRect.size.height - 2.0) / 3))),
					UNIFIED_SPLIT_VIEW_THUMB_WIDTH,
					1.0f
		)
	);
}


@end
