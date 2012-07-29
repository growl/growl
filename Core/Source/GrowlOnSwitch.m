//
//  GrowlOnSwitch.m
//  GrowlSlider
//
//  Created by Daniel Siemer on 1/10/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "GrowlOnSwitch.h"

@implementation GrowlOnSwitch

@synthesize onLabel = _onLabel;
@synthesize offLabel = _offLabel;

- (id)initWithFrame:(NSRect)frameRect
{
   if((self = [super initWithFrame:frameRect])){      
      
      NSString *offString = NSLocalizedString(@"OFF", @"If the string is too long, use O");
      [self.offLabel setStringValue:offString];
      
      NSString *onString = NSLocalizedString(@"ON", @"If the string is too long, use I");
      [self.onLabel setStringValue:onString];
      
      [self addObserver:self 
             forKeyPath:@"state" 
                options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                context:nil];
   }
   return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"state"];
    [_onLabel release];
    [_offLabel release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"state"])
    {
        self.onLabel.textColor = (self.state ? [NSColor blueColor] : [NSColor blackColor]);
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)setNilValueForKey:(NSString *)key
{
	if ([key isEqualToString:@"state"])
		[self setState:NO];
	else
		return [super setNilValueForKey:key];
}

- (BOOL)canBecomeKeyView
{
   return YES;
}

- (BOOL)acceptsFirstResponder
{
   return YES;
}

@end
