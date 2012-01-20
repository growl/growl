//
//  GrowlNotificationSettingsRowView.m
//  Growl
//
//  Created by Daniel Siemer on 1/18/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlNotificationSettingsRowView.h"

@implementation GrowlNotificationSettingsRowView

@synthesize selectionLayer;

-(id)initWithFrame:(NSRect)frameRect {
   if((self = [super initWithFrame:frameRect])){
   }
   return self;
}

-(NSBackgroundStyle)interiorBackgroundStyle{
   if(self.selected)
      return NSBackgroundStyleDark;
   return NSBackgroundStyleLight;
}

-(NSGradient*)lightGradient{
   return [[[NSGradient alloc] initWithColors:[NSArray arrayWithObjects:[NSColor lightGrayColor],
                                                                        [NSColor grayColor], nil]] autorelease];
}

-(NSGradient*)darkGradient{
   return [[[NSGradient alloc] initWithColors:[NSArray arrayWithObjects:[NSColor grayColor], 
                                                                        [NSColor darkGrayColor], nil]] autorelease];
}

-(void)drawBackgroundInRect:(NSRect)dirtyRect
{
   if(![[self superview] isKindOfClass:[NSTableView class]])
      return;
   
   [[NSColor colorWithDeviceWhite:.895f alpha:1.0] setFill];
   [[NSBezierPath bezierPathWithRect:[self bounds]] fill];
   NSArray *colors = [NSColor controlAlternatingRowBackgroundColors];
   [[colors objectAtIndex:[(NSTableView*)[self superview] rowForView:self] % [colors count]] setFill];
   [[NSColor gridColor] setStroke];
   CGRect box = [self bounds];
   NSBezierPath *path = [NSBezierPath bezierPathWithRect:CGRectMake(box.origin.x + 8.0f, box.origin.y, box.size.width - 31.0f, box.size.height)];
   [path fill];
}

-(void)drawSelectionInRect:(NSRect)dirtyRect
{
   CGFloat triangleEdge = self.bounds.size.width - 22.0f;
   CGFloat triangleCenter = (self.bounds.size.height - 1.0f) / 2.0f;
   NSBezierPath *path = [[NSBezierPath alloc] init];
   [path moveToPoint:CGPointMake(dirtyRect.origin.x + 5.0f, 0.0f)];
   [path lineToPoint:CGPointMake(triangleEdge, 0.0f)];
   [path lineToPoint:CGPointMake(self.frame.size.width, triangleCenter)];
   [path lineToPoint:CGPointMake(triangleEdge, self.frame.size.height - 1.0f)];
   [path lineToPoint:CGPointMake(dirtyRect.origin.x + 5.0f, self.frame.size.height - 1.0f)];
   [path appendBezierPathWithArcFromPoint:CGPointMake(dirtyRect.origin.x, triangleCenter) toPoint:CGPointMake(dirtyRect.origin.x + 5.0f, 0.0f) radius:40];
   [path closePath];
   
   NSGradient *gradient = self.emphasized ? [self darkGradient] : [self lightGradient];
   [gradient drawInBezierPath:path angle:90.0f];
   if(self.emphasized)
      [[NSColor darkGrayColor] setStroke];
   else
      [[NSColor grayColor] setStroke];
   [path stroke];
   [path release];
}

-(void)drawSeparatorInRect:(NSRect)dirtyRect
{
   if(!self.selected){
//      [[NSColor grayColor] drawSwatchInRect:CGRectMake(dirtyRect.origin.x + 5.0f, dirtyRect.origin.y, 1.0f, dirtyRect.size.height)];
//      [[NSColor grayColor] drawSwatchInRect:CGRectMake(dirtyRect.size.width - 21.0f, dirtyRect.origin.y, 1.0f, dirtyRect.size.height)];
   }
//   [[NSColor grayColor] drawSwatchInRect:CGRectMake(dirtyRect.origin.x + 5.0f, dirtyRect.origin.y + [self frame].size.height - 1.0f, dirtyRect.size.width - 28.0f, 1.0f)];
}

@end
