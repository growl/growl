/*

BSD License

Copyright (c) 2004, Keith Anderson
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


#import "ImageTextCell.h"


@implementation ImageTextCell


-(id)initTextCell:(NSString *)string{
	self = [super initTextCell:string];
	if( self ){
		//KNDebug(@"ITCELL: initTextCell");
		image = nil;
		//tooltip = nil;
		//ownerView = nil;
	}
	return self;
}

-(void)dealloc{
	//KNDebug(@"ITCELL: dealloc");
	//if( ownerView ){
		//[self clearToolTipInView: ownerView];
	//}
	if( image ){ [image release]; }
	//if( tooltip ){ [tooltip release]; }
	[super dealloc];
}

-(id)copyWithZone:(NSZone *)zone{
	ImageTextCell *			cell = (ImageTextCell *)[super copyWithZone:zone];
	//KNDebug(@"ITCELL: copyWithZone");
	
	if( image ){
		cell->image = [image retain];
	}else{
		cell->image = nil;
	}
	
	return cell;
}

-(NSImage *)image{
	return image;
}

-(void)setImage:(NSImage *)anImage{
	if( anImage != image ){
		if( image ){ [image autorelease]; }
		if( anImage ){
			image = [anImage retain];
		}else{
			image = nil;
		}
	}
}

-(NSRect)imageFrameForCellFrame:(NSRect)cellFrame{
	NSRect					imageFrame = NSZeroRect;
	
	if( image != nil ){
		imageFrame.size = [image size];
		imageFrame.origin = cellFrame.origin;
		imageFrame.origin.x += 3;
		imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2 );
	}
	return imageFrame;
}

-(void)editWithFrame:(NSRect)aRect inView:(NSView *)view editor:(NSText *)editor delegate:(id)anObject event:(NSEvent *)event{
	NSRect					textFrame,imageFrame;
	
	//KNDebug(@"ITCELL: editWithFrame");
	NSDivideRect( aRect, &imageFrame, &textFrame, 5 + [image size].width, NSMinXEdge );
	[super editWithFrame: textFrame inView: view editor: editor delegate: anObject event: event];
}

-(void)selectWithFrame:(NSRect)aRect inView:(NSView *)view editor:(NSText *)editor delegate:(id)anObject start:(int)start length:(int)length{
	NSRect					textFrame,imageFrame;
	
	//KNDebug(@"ITCELL: selectWithFrame");
	NSDivideRect( aRect, &imageFrame, &textFrame, 5 + [image size].width, NSMinXEdge );
	[super selectWithFrame: textFrame inView: view editor: editor delegate: anObject start: start length: length];
}

-(void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)view{
	NSSize					imageSize;
	NSRect					imageFrame;
	
	if( image != nil ){
		//KNDebug(@"ITCELL: draw");
		imageSize = [image size];
		NSDivideRect( cellFrame, &imageFrame, &cellFrame, 5 + imageSize.width, NSMinXEdge);
		if( [self drawsBackground] ){
			[[self backgroundColor] set];
			NSRectFill(imageFrame);
		}
		imageFrame.origin.x += 3;
		imageFrame.size = imageSize;
		
		if( [view isFlipped] ){
			imageFrame.origin.y += ceil((cellFrame.size.height + imageFrame.size.height) / 2);
		}else{
			imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
		}
		[image compositeToPoint: imageFrame.origin operation:NSCompositeSourceOver];
	}
	[super drawWithFrame: cellFrame inView: view];
}

-(NSSize)cellSize{
	NSSize					cellSize = [super cellSize];
	
	cellSize.width += (image ? [image size].width : 0) + 5;
	return cellSize;
}

@end
