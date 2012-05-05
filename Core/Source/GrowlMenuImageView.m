//
//  GrowlMenuImageView.m
//  Growl
//
//  Created by Daniel Siemer on 10/10/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlMenuImageView.h"
#import "GrowlMenu.h"
#import <QuartzCore/QuartzCore.h>

@implementation GrowlMenuImageView

@synthesize mode;

@synthesize menuItem;
@synthesize mainImage;
@synthesize alternateImage;
@synthesize squelchImage;
@synthesize mainLayer;
@synthesize mouseDown;

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        // Initialization code here.
        menuItem = nil;
        mainImage = nil;
        alternateImage = nil;
        mouseDown = NO;
        
        CALayer *rootLayer = [CALayer layer];
        rootLayer.frame = frameRect;
        rootLayer.delegate = self;
        rootLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
        
        self.mainLayer = [CALayer layer];
        mainLayer.opacity = 1.0f;
        
        [mainLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
        [mainLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY]];
         
        [rootLayer addSublayer:mainLayer];
        [self setWantsLayer:YES];
        [self setLayer:rootLayer];
        
        [self addObserver:self forKeyPath:@"mode" options:NSKeyValueObservingOptionNew context:&self];
        [self addObserver:self forKeyPath:@"mainImage" options:NSKeyValueObservingOptionNew context:&self];
        [self addObserver:self forKeyPath:@"mouseDown" options:NSKeyValueObservingOptionNew context:&self];
    }
    
    return self;
}

-(void)dealloc
{
    [self removeObserver:self forKeyPath:@"mode"];
    [self removeObserver:self forKeyPath:@"mainImage"];
    [self removeObserver:self forKeyPath:@"mouseDown"];

    [mainImage release];
    [alternateImage release];
    [squelchImage release];
    
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"mainImage"])
    {
        CGRect newBounds = CGRectZero;
        newBounds.size = [mainImage size];
        mainLayer.frame = newBounds;
        self.mode = 0;
        [self.layer setNeedsLayout];
    }
    else if ([keyPath isEqualToString:@"mouseDown"])
    {
        if(mouseDown)
        {
            [self.layer setNeedsDisplay];
            self.mode = 1;
        }
        else
        {
            self.mode = previousMode;
            [self.layer setNeedsDisplay];
        }
    } 
    else if ([keyPath isEqualToString:@"mode"])
    {
        switch(mode)
        {
            case 1:
                mainLayer.contents = (id)alternateImage;
                break;
            case 2:
                previousMode = self.mode;
                mainLayer.contents = (id)squelchImage;
                break;
            case 0:
            default:
                previousMode = self.mode;
                mainLayer.contents = (id)mainImage;
                break;
        }
    }
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    NSGraphicsContext *previousContext = [NSGraphicsContext currentContext];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:ctx flipped:NO]];
    [[menuItem statusItem] drawStatusBarBackgroundInRect:[self frame] withHighlight:mouseDown];
    [NSGraphicsContext setCurrentContext:previousContext];
}

-(void)mouseDown:(NSEvent *)theEvent
{
   self.mouseDown = YES;

    [[menuItem statusItem] popUpStatusItemMenu:[menuItem menu]];

    self.mouseDown = NO;
}

- (void)startAnimation
{
    if(![self.mainLayer animationForKey:@"pulseAnimation"])
    {
        CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"opacity"];
        anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        anim.duration = 1.0f;
        anim.repeatCount = HUGE_VALF;
        anim.autoreverses = YES;
        anim.removedOnCompletion = NO;
        anim.toValue = [NSNumber numberWithFloat:0.0f];
        [mainLayer addAnimation:anim forKey:@"pulseAnimation"];    
    }
}

- (void)stopAnimation
{
    [self.mainLayer removeAnimationForKey:@"pulseAnimation"];
}

@end
