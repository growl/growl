//
//  GrowlHistoryWindowNotificationCell.m
//  Growl
//
//  Created by Daniel Siemer on 5/7/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlHistoryWindowNotificationCell.h"
#import "GrowlHistoryNotification.h"
#import "GrowlImageCache.h"

@implementation GrowlHistoryWindowNotificationCell

@synthesize note;

-(id)init
{
   if((self = [super init])){
      
   }
   return self;
}

-(id)initTextCell:(NSString *)aString
{
   if((self = [super initTextCell:aString])){
      
   }
   return self;
}

-(id)initImageCell:(NSImage *)image
{
   if((self = [super initImageCell:image])){
      
   }
   return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
   if((self = [super initWithCoder:aDecoder])){

   }
   return self;
}

- (id) copyWithZone:(NSZone *)zone {
	GrowlHistoryWindowNotificationCell *cell = (GrowlHistoryWindowNotificationCell *)[super copyWithZone:zone];
   cell->note = [note retain];
   cell->applicationLine = nil;
   cell->descriptionLine = nil;
   cell->tooltipString = nil;
	return cell;
}

-(void)setNote:(GrowlHistoryNotification *)newNote
{
   if(note)
      [note release];
   [self willChangeValueForKey:@"note"];
   note = [newNote retain];
   [self didChangeValueForKey:@"note"];
   [applicationLine release]; applicationLine = nil;
   [descriptionLine release]; descriptionLine = nil;
   [tooltipString release]; tooltipString = nil;
}

-(void)dealloc
{
   [note release]; note = nil;
   [applicationLine release]; applicationLine = nil;
   [descriptionLine release]; descriptionLine = nil;
   [tooltipString release]; tooltipString = nil;
   [super dealloc];
}

- (NSRect) imageFrameForCellFrame:(NSRect)cellFrame {
	NSRect retRect;
   NSImage *image = [[note Image] Thumbnail];
	if (image) {
		retRect.size = [image size];
		retRect.origin.x = cellFrame.origin.x + 3.0;
		retRect.origin.y = cellFrame.origin.y
      + GrowlCGFloatCeiling((cellFrame.size.height - retRect.size.height) * 0.5);
	} else {
		retRect = NSZeroRect;
	}
   
	return retRect;
}

-(NSAttributedString*)tooltipString
{
   if(tooltipString)
      return tooltipString;

   if(note && [note ApplicationName] && [note Title] && [note Description]) {      
      NSDictionary *font = [NSDictionary dictionaryWithObject:[NSFont toolTipsFontOfSize:0] forKey:NSFontAttributeName];
      NSString *string = [NSString stringWithFormat:@"%@ - %@\n%@", [note ApplicationName], [note Title], [note Description]];
      tooltipString = [[NSAttributedString alloc] initWithString:string attributes:font];
   } else {
      tooltipString = [[NSAttributedString alloc] initWithString:@"ERROR!"];
   }
   return tooltipString;
}

-(NSAttributedString*)applicationLine
{
   if(applicationLine)
      return applicationLine;
   
   if(note && [note Title] && [note ApplicationName]){
      NSFont *boldFont = [NSFont boldSystemFontOfSize:0];
      NSColor *white = [NSColor whiteColor];
      NSDictionary *appAttr = [NSDictionary dictionaryWithObject:boldFont forKey:NSFontAttributeName];
      NSMutableAttributedString *applicationName = [[NSMutableAttributedString alloc] initWithString:[note ApplicationName] attributes:appAttr];
      [applicationName autorelease];
      NSString *string = [NSString stringWithFormat:@" - %@", [note Title]];
      NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:string];
      [applicationName appendAttributedString:attrString];
      [attrString release];
      [applicationName addAttributes:[NSDictionary dictionaryWithObject:white forKey:NSForegroundColorAttributeName] range:NSMakeRange(0, [applicationName length])];
      
      applicationLine = [applicationName copyWithZone:nil];
   } else {
      applicationLine = [[NSAttributedString alloc] initWithString:@"ERROR!"];
   }
   return applicationLine;
}

-(NSAttributedString*)descriptionLine
{
   if(descriptionLine)
      return descriptionLine;
   
   if(note && [note Description]){
      NSDictionary *white = [NSDictionary dictionaryWithObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
      descriptionLine = [[NSAttributedString alloc] initWithString:[note Description] attributes:white];
   }else {
      descriptionLine = [[NSAttributedString alloc] initWithString:@"ERROR!"];
   }
   return descriptionLine;
}

-(void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if (note) {
      NSImage *image = [[note Image] Thumbnail];
		NSSize	imageSize = [image size];
		NSRect	imageFrame;
      NSRect   appFrame;
      NSRect   descriptionFrame;
      
		NSDivideRect(cellFrame, &imageFrame, &cellFrame, 15.0 + imageSize.width, NSMinXEdge);
		imageFrame.origin.x += 3.0;
      
		if ([controlView isFlipped]) {
			imageFrame.origin.y += GrowlCGFloatCeiling((cellFrame.size.height + imageSize.height) * 0.5);
		} else {
			imageFrame.origin.y += GrowlCGFloatCeiling((cellFrame.size.height - imageSize.height) * 0.5);
		}
            
		[image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
      
      NSAttributedString *appLine = [self applicationLine];
      NSAttributedString *descriptionString = [self descriptionLine];
      NSDivideRect(cellFrame, &appFrame, &descriptionFrame, 17.0, NSMinYEdge);
      NSStringDrawingOptions options = NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingTruncatesLastVisibleLine;
      
      [appLine drawWithRect:appFrame options:options];
      [descriptionString drawWithRect:descriptionFrame options:options];
	} else {
      [super drawWithFrame:cellFrame inView:controlView];
   }
}

- (NSSize) cellSize {
	NSSize cellSize = [super cellSize];
	cellSize.width += (note ? [[[note Image] Thumbnail] size].width + 3.0 : 3.0);
	return cellSize;
}

-(NSRect)expansionFrameWithFrame:(NSRect)cellFrame inView:(NSView *)view
{
   NSSize	imageSize = [[[note Image] Thumbnail] size];
   NSRect	imageFrame;
   NSDivideRect(cellFrame, &imageFrame, &cellFrame, 15.0 + imageSize.width, NSMinXEdge);
   NSAttributedString *string = [self tooltipString];
   NSRect bound = [string boundingRectWithSize:NSMakeSize(cellFrame.size.width, 0) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingTruncatesLastVisibleLine];
   bound.origin = cellFrame.origin;
   if(bound.size.height > cellFrame.size.height)
      return bound;
   else
      return NSZeroRect;
}

-(void)drawWithExpansionFrame:(NSRect)cellFrame inView:(NSView *)view
{
   NSAttributedString *string = [self tooltipString];
   [string drawWithRect:cellFrame options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingTruncatesLastVisibleLine];
}


@end
