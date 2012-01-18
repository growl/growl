//
//  GrowlNotificationSettingsTableView.m
//  Growl
//
//  Created by Daniel Siemer on 1/18/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlNotificationSettingsTableView.h"

@implementation GrowlNotificationSettingsTableView

- (CGFloat)yPositionPastLastRow {
   // Only draw the grid past the last visible row
   NSInteger numberOfRows = self.numberOfRows;
   CGFloat yStart = 0;
   if (numberOfRows > 0) {
      yStart = NSMaxY([self rectOfRow:numberOfRows - 1]);
   }
   return yStart;
}

- (void)drawBackgroundInClipRect:(NSRect)clipRect {
   [[NSColor whiteColor] drawSwatchInRect:CGRectMake(clipRect.origin.x + 5.0f, clipRect.origin.y, clipRect.size.width - 28.0f, clipRect.size.height)];
}

- (void)drawGridInClipRect:(NSRect)clipRect {
   if(clipRect.origin.x > 3.0f)
      return;
   // Only draw the grid past the last visible row
   CGFloat yStart = [self yPositionPastLastRow];
   
   // One thing to do is smarter clip testing to see if we actually need to draw!
   NSRect boundsToDraw = clipRect;
   NSRect separatorRect = boundsToDraw;
   separatorRect.size.height = self.rowHeight;
   while (yStart < NSMaxY(boundsToDraw)) {
      separatorRect.origin.y = yStart;
      [[NSColor grayColor] drawSwatchInRect:CGRectMake(separatorRect.origin.x + 5.0f, NSMaxY(separatorRect) - 1.0f, separatorRect.size.width - 28.0f, 1.0f)];
      [[NSColor grayColor] drawSwatchInRect:CGRectMake(separatorRect.origin.x + 5.0f, separatorRect.origin.y, 1.0f, separatorRect.size.height)];
      [[NSColor grayColor] drawSwatchInRect:CGRectMake(separatorRect.size.width - 21.0f, separatorRect.origin.y, 1.0f, separatorRect.size.height)];
      yStart += self.rowHeight;
   }
}

@end
