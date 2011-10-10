//
//  GrowlMenuImageView.m
//  Growl
//
//  Created by Daniel Siemer on 10/10/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlMenuImageView.h"
#import "GrowlMenu.h"

@implementation GrowlMenuImageView

@synthesize menuItem;
@synthesize mainImage;
@synthesize alternateImage;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
       menuItem = nil;
       mainImage = nil;
       alternateImage = nil;
       mouseDown = NO;
    }
    
    return self;
}

-(void)dealloc
{
   [alternateImage release];
   [mainImage release];
   [super dealloc];
}

-(void)drawRect:(NSRect)dirtyRect
{
   [[menuItem statusItem] drawStatusBarBackgroundInRect:[self frame] withHighlight:mouseDown];
   [super drawRect:dirtyRect];
}

-(void)mouseDown:(NSEvent *)theEvent
{
   mouseDown = YES;
   if(alternateImage)
      [self setImage:alternateImage];
   
   [self display];
   
   [[menuItem statusItem] popUpStatusItemMenu:[menuItem menu]];
   
   if(alternateImage)
      [self setImage:mainImage];
   
   mouseDown = NO;
   [self setNeedsDisplay];
}

-(void)setMainImage:(NSImage *)newImage
{
   [mainImage release];
   mainImage = [newImage retain];
   
   if (!mouseDown) {
		[self setImage:mainImage];
		[self setNeedsDisplay:YES];
	}
}

-(void)setAlternateImage:(NSImage *)newImage
{
   [alternateImage release];
   alternateImage = [newImage retain];
   
   if (mouseDown) {
		[self setImage:alternateImage];
		[self setNeedsDisplay:YES];
	}
}

@end
