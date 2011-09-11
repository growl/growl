//
//  GrowlMistView.m
//
//  Created by Rachel Blackman on 7/11/11.
//

#import "GrowlMistView.h"
#import "NSImageAdditions.h"

@implementation GrowlMistView

@synthesize notificationText;
@synthesize notificationTitle;
@synthesize notificationImage;
@synthesize delegate;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		clipPath = [[NSBezierPath bezierPathWithRoundedRect:[self bounds] xRadius:8 yRadius:8] retain];
		NSRect insetRect = NSInsetRect([self bounds], 1, 1);
		strokePath = [[NSBezierPath bezierPathWithRoundedRect:insetRect xRadius:8 yRadius:8] retain];
		NSMutableParagraphStyle *titleParaStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopyWithZone:nil] autorelease];
		[titleParaStyle setLineBreakMode:NSLineBreakByTruncatingTail];
		notificationTitleFont = [[NSFont boldSystemFontOfSize:MIST_TITLE_SIZE] retain];
		notificationTitleAttrs = [[NSDictionary alloc] initWithObjectsAndKeys:notificationTitleFont,NSFontAttributeName,[NSColor whiteColor],NSForegroundColorAttributeName,titleParaStyle,NSParagraphStyleAttributeName,nil];
		notificationTextFont = [[NSFont systemFontOfSize:MIST_TEXT_SIZE] retain];
		notificationTextAttrs = [[NSDictionary alloc] initWithObjectsAndKeys:notificationTextFont,NSFontAttributeName,[NSColor whiteColor],NSForegroundColorAttributeName,nil];
		
		trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways) owner:self userInfo:nil];
		[self addTrackingArea:trackingArea];
    }
    return self;
}

- (void)dealloc {
	[self removeTrackingArea:trackingArea];
	[trackingArea release];
    [notificationImage release];
	[notificationTitleAttrs release];
	[notificationTitleFont release];
    [notificationTitle release];
	[notificationTextAttrs release];
	[notificationTextFont release];
    [notificationText release];
	[strokePath release];
	[clipPath release];
    [super dealloc];
}

// Override the default synthesized notificationImage setter, to pre-size our image.
- (void)setNotificationImage:(NSImage *)image {
	NSImage *oldImage = notificationImage;
	notificationImage = [[[image imageSizedToDimensionSquaring:MIST_IMAGE_DIM] flippedImage] retain];
	[oldImage release];
}

- (void)setFrame:(NSRect)frameRect
{
	[super setFrame:frameRect];
	
	[clipPath release];
	clipPath = [[NSBezierPath bezierPathWithRoundedRect:[self bounds] xRadius:8 yRadius:8] retain];

	[strokePath release];
	NSRect insetRect = NSInsetRect([self bounds], 1, 1);
	strokePath = [[NSBezierPath bezierPathWithRoundedRect:insetRect xRadius:8 yRadius:8] retain];
	
	[self removeTrackingArea:trackingArea];
	[trackingArea release];
	trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways) owner:self userInfo:nil];
	[self addTrackingArea:trackingArea];
}

- (BOOL)isOpaque {
	return NO;
}

- (BOOL)isFlipped {
	return YES;
}

- (void)sizeToFit {
	NSRect imageRect = NSZeroRect;
	if (notificationImage) {
		imageRect.size = [notificationImage size];
	}

	NSRect titleRect = NSZeroRect;
	if (notificationTitle) {
		NSSize titleSize = [notificationTitle sizeWithAttributes:notificationTitleAttrs];
		titleRect.size = titleSize;
	}

	float baseWidth = imageRect.size.width + (MIST_TEXT_PADDING * 2);
	
	NSRect textRect = [notificationText boundingRectWithSize:NSMakeSize(MIST_WIDTH - baseWidth, 1e7) options:(NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin) attributes:notificationTextAttrs];
	
	NSRect myFrame = self.frame;
	myFrame.size.width = MIST_WIDTH;
	myFrame.size.height = titleRect.size.height + textRect.size.height + (notificationTitle ? MIST_TEXT_LINESPACE * 2 : 0) + (MIST_PADDING * 2);
	
	if (myFrame.size.height < (MIST_IMAGE_DIM + (MIST_PADDING * 2)))
		myFrame.size.height = MIST_IMAGE_DIM + (MIST_PADDING * 2);
	
	[self setFrame:myFrame];
}

- (void)drawRect:(NSRect)rect {
	[[NSGraphicsContext currentContext] saveGraphicsState];
	
	if (selected) {
		[[NSColor colorWithDeviceWhite:0.0 alpha:1] set];		
	}
	else {
		[[NSColor colorWithDeviceWhite:0.0 alpha:0.75] set];
	}
	[clipPath fill];
	
	if (selected) {
		[[NSColor whiteColor] set];
		[strokePath setLineWidth:3.0f];
		[strokePath stroke];
	}
	
	// Draw image.
	NSRect imageRect = NSZeroRect;
	if (notificationImage) {
		imageRect.size = [notificationImage size];
		imageRect.origin.x = self.bounds.origin.x + MIST_PADDING;
		imageRect.origin.y = self.bounds.origin.y + MIST_PADDING;
		[notificationImage drawInRect:imageRect];
	}
	
	// Draw title.
	NSRect titleRect = NSZeroRect;
	if (notificationTitle) {
		NSSize titleSize = [notificationTitle sizeWithAttributes:notificationTitleAttrs];
		titleRect.size = titleSize;
		titleRect.origin.y = self.bounds.origin.y + MIST_PADDING;
		titleRect.origin.x = imageRect.origin.x + imageRect.size.width + MIST_TEXT_PADDING;
		
		[notificationTitle drawInRect:titleRect withAttributes:notificationTitleAttrs];
	}
	
	// Draw text.
	if (notificationText) {
		float baseWidth = imageRect.size.width + (MIST_TEXT_PADDING * 2);
		
		NSRect textRect = [notificationText boundingRectWithSize:NSMakeSize(MIST_WIDTH - baseWidth, 1e7) options:(NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin) attributes:notificationTextAttrs];
		textRect.origin.x = imageRect.origin.x + imageRect.size.width + MIST_TEXT_PADDING;
		textRect.origin.y = titleRect.origin.y + titleRect.size.height + (notificationTitle ? MIST_TEXT_LINESPACE * 2 : MIST_PADDING);
		
		[notificationText drawInRect:textRect withAttributes:notificationTextAttrs];
	}
	
	if (selected) {
		// Draw mouseover close button
	}
	
	[[NSGraphicsContext currentContext] restoreGraphicsState];
	
}

- (void)mouseEntered:(NSEvent *)theEvent {
	selected = YES;
	[self setNeedsDisplay:YES];
	if ([[self delegate] respondsToSelector:@selector(mistViewSelected:)])	
		[[self delegate] mistViewSelected:YES];
}

- (void)mouseExited:(NSEvent *)theEvent {
	selected = NO;
	[self setNeedsDisplay:YES];
	if ([[self delegate] respondsToSelector:@selector(mistViewSelected:)])
		[[self delegate] mistViewSelected:NO];
}

- (void)mouseDown:(NSEvent *)theEvent {
   if(([theEvent modifierFlags] & NSAlternateKeyMask) != 0){
      if([[self delegate] respondsToSelector:@selector(closeAllNotifications)])
         [[self delegate] closeAllNotifications];
   }else{
      if ([[self delegate] respondsToSelector:@selector(mistViewDismissed:)])
         [[self delegate] mistViewDismissed:NO];
   }
}

@end
