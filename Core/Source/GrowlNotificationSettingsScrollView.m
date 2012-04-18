//
//  GrowlNotificationSettingsScrollView.m
//  Growl
//
//  Created by Daniel Siemer on 1/18/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlNotificationSettingsScrollView.h"

#define FADE_HEIGHT 20.0f

@implementation GrowlNotificationTableFadeView
@synthesize gradient;
@synthesize angle;

-(id)initWithFrame:(NSRect)frameRect {
   if((self = [super initWithFrame:frameRect])){
   }
   return self;
}

-(void)drawRect:(NSRect)dirtyRect {
   [gradient drawInRect:[self bounds] angle:angle];
}

@end

@implementation GrowlNotificationSettingsScrollView
@synthesize top;
@synthesize bottom;

-(void)awakeFromNib {
   [self setScrollerStyle:NSScrollerStyleOverlay];
}

-(void)dealloc {
   [top release];
   [bottom release];
   [super dealloc];
}

-(void)tile {
   [super tile];
   static NSGradient *_gradient;
   if(!top){
      _gradient = [[NSGradient alloc] initWithColors:[NSArray arrayWithObjects:[NSColor blackColor],
                                                                               [[NSColor blackColor] colorWithAlphaComponent:.25],
                                                                               [[NSColor blackColor] colorWithAlphaComponent:0.0], nil]];
      top = [[GrowlNotificationTableFadeView alloc] initWithFrame:CGRectMake(8.0f, 0.0f, self.contentView.frame.size.width - 31.0f, FADE_HEIGHT)];
      [top setAngle:[top isFlipped] ? 90.0f : -90.0f];
      [top setGradient:_gradient];
   }
   if(!bottom){
      bottom = [[GrowlNotificationTableFadeView alloc] initWithFrame:CGRectMake(8.0f, self.contentView.frame.size.height - FADE_HEIGHT, self.contentView.frame.size.width - 31.0f, FADE_HEIGHT)];
      [bottom setAngle:[bottom isFlipped] ? -90.0f : 90.0f];
      [bottom setGradient:_gradient];
   }
   
   [top removeFromSuperviewWithoutNeedingDisplay];
   [bottom removeFromSuperviewWithoutNeedingDisplay];
   //[self addSubview:top positioned:NSWindowAbove relativeTo:[self contentView]];
   //[self addSubview:bottom positioned:NSWindowAbove relativeTo:[self contentView]];
   
   [[self verticalScroller] setScrollerStyle:NSScrollerStyleOverlay];
   CGPoint origin = [[self verticalScroller] frame].origin;
   origin.x -= 24.0f;
   [[self verticalScroller] setFrameOrigin:origin];
}

@end
