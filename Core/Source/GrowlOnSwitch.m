//
//  GrowlOnSwitch.m
//  GrowlSlider
//
//  Created by Daniel Siemer on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GrowlOnSwitch.h"
#import "GrowlOnSwitchKnob.h"

@implementation GrowlOnSwitch

@synthesize knob;
@synthesize onLabel;
@synthesize offLabel;

@synthesize state;
@synthesize mouseLoc;

+(void)initialize
{
   if (self != [GrowlOnSwitch class])
		return;

   [NSObject exposeBinding:@"state"];
}

-(id)initWithFrame:(NSRect)frameRect
{
   if((self = [super initWithFrame:frameRect])){      
      CGRect box = [self bounds];
      CGRect knobFrame = CGRectMake(2.0f, 2.0f, (box.size.width / 1.8f) - 4.0, box.size.height - 4.0f);
      NSView *knobView = knobView = [[GrowlOnSwitchKnob alloc] initWithFrame:knobFrame];
      self.knob = knobView;
      [self addSubview:knob];
      [knobView release];
      
      CGFloat vertical = box.size.height / 2.0f - 10.0f;
      NSShadow *shadow = [[NSShadow alloc] init];
      [shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.5]];
      [shadow setShadowOffset:CGSizeMake(0.0, -1.0)];
      NSDictionary *attrDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica Neue Bold" size:17], NSFontAttributeName,
                                                                          [NSColor colorWithSRGBRed:.15 green:.15 blue:.15 alpha:1.0], NSForegroundColorAttributeName,
                                                                          shadow, NSShadowAttributeName, nil];
      
      NSString *offString = NSLocalizedString(@"OFF", @"If the string is too long, use O");
      NSAttributedString *attrOffTitle = [[NSAttributedString alloc] initWithString:offString
                                                                         attributes:attrDict];
      NSTextField *offView = [[NSTextField alloc] initWithFrame:CGRectMake(55.0f, vertical, 50.0f, 25.0f)];
      [offView setAlignment:NSCenterTextAlignment];
      [offView setEditable:NO];
      [offView setDrawsBackground:NO];
      [offView setBackgroundColor:[NSColor clearColor]];
      [offView setBezeled:NO];
      
      [[offView cell] setAttributedStringValue:attrOffTitle];
      self.offLabel = offView;
      [self addSubview:offView positioned:NSWindowBelow relativeTo:knob];
      [offView setToolTip:@"Are you happy now Gemmel?"];
      [offView release];
      
      NSString *onString = NSLocalizedString(@"ON", @"If the string is too long, use I");
      NSAttributedString *attrOnTitle = [[NSAttributedString alloc] initWithString:onString
                                                                        attributes:attrDict];
      NSTextField *onView = [[NSTextField alloc] initWithFrame:CGRectMake(5.0f, vertical, 50.0f, 25.0f)];
      [onView setAlignment:NSCenterTextAlignment];
      [onView setEditable:NO];
      [onView setDrawsBackground:NO];
      [onView setBackgroundColor:[NSColor clearColor]];
      [onView setBezeled:NO];
      [[onView cell] setAttributedStringValue:attrOnTitle];
      self.onLabel = onView;
      [self addSubview:onView positioned:NSWindowBelow relativeTo:knob];
      [onView release];
      [self addObserver:self 
             forKeyPath:@"state" 
                options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                context:nil];
   }
   return self;
}

-(void)dealloc
{
   [self removeObserver:self forKeyPath:@"state"];
   [knob release];
   [onLabel release];
   [offLabel release];
   [super dealloc];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
   if([keyPath isEqualToString:@"state"]){
      [self updatePosition];
   }
}

- (void)setNilValueForKey:(NSString *)key
{
	if ([key isEqualToString:@"state"])
		[self setState:NO];
	else
		return [super setNilValueForKey:key];
}

-(void)setState:(BOOL)newState
{
   state = newState;
}

-(void)silentSetState:(BOOL)newState
{
   state = newState;
   [self updatePosition];
}

- (void)mouseDown:(NSEvent *)theEvent
{
   CGPoint viewPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	mouseLoc = [knob convertPoint:viewPoint fromView:nil];
}

- (void)mouseUp:(NSEvent*)inEvent
{
	BOOL newState = NO;
   
	CGPoint viewPoint = [self convertPoint:[inEvent locationInWindow] fromView:nil];

	CGPoint currentKnobPoint = [knob convertPoint:viewPoint fromView:nil];

	if (CGPointEqualToPoint(mouseLoc, currentKnobPoint))
		newState = ![self state];
	else if(viewPoint.x >= ([self frame].size.width / 2.2f))
		newState = YES;
   else if(viewPoint.x <= ([self frame].size.width / 2.2f))
      newState = NO;
   
	[self setState:newState];
	mouseLoc = CGPointZero;
}

- (void)mouseDragged:(NSEvent*)inEvent
{	
	CGPoint newMouseLoc = [self convertPoint:[inEvent locationInWindow] fromView:nil];
	if (newMouseLoc.x >= self.frame.size.width - [knob frame].size.width - 4.0f)
		newMouseLoc.x = self.frame.size.width - [knob frame].size.width - 4.0f;
	if (newMouseLoc.x <= 2.0)
		newMouseLoc.x = 2.0;
   mouseLoc = newMouseLoc;
   
   [knob setFrameOrigin:CGPointMake(newMouseLoc.x, 2.0f)];
}

-(void)drawRect:(NSRect)dirtyRect
{
   CGRect inset = CGRectInset([self bounds], 2.0, 2.0);
   NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:inset xRadius:6.0 yRadius:6.0];
   NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor darkGrayColor] endingColor:[NSColor lightGrayColor]];
   [[NSColor colorWithDeviceWhite:.15f alpha:1.0f] setStroke];

   [gradient drawInBezierPath:path angle:-90.0f];
   [path stroke];
   [gradient release];
}

-(void)updatePosition
{
   CGPoint desired;
   if([self state]){
      desired = CGPointMake([self bounds].size.width - [knob bounds].size.width - 2.0f, 2.0f);
   }else{
      desired = CGPointMake(2.0f, 2.0f);
   }
   [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
      [[knob animator] setFrameOrigin:desired];
   } completionHandler:^{
   }];
}

@end
