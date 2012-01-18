//
//  GrowlNotificationSettingsRowView.m
//  Growl
//
//  Created by Daniel Siemer on 1/18/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlNotificationSettingsRowView.h"

@implementation GrowlNotificationSettingsRowView

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

/*-(void)drawBackgroundInRect:(NSRect)dirtyRect
{
}*/

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
   [path release];
}

-(void)drawSeparatorInRect:(NSRect)dirtyRect
{
   if (dirtyRect.origin.x > 10.0f) {
      return;
   }
   if(!self.selected){
      [[NSColor grayColor] drawSwatchInRect:CGRectMake(dirtyRect.origin.x + 5.0f, dirtyRect.origin.y, 1.0f, dirtyRect.size.height)];
      [[NSColor grayColor] drawSwatchInRect:CGRectMake(dirtyRect.size.width - 21.0f, dirtyRect.origin.y, 1.0f, dirtyRect.size.height)];
   }
   [[NSColor grayColor] drawSwatchInRect:CGRectMake(dirtyRect.origin.x + 5.0f, NSMaxY(dirtyRect) - 1.0f, dirtyRect.size.width - 28.0f, 1.0f)];
}

@end
