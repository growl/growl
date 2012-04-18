//
//  GrowlPluginPreferenceStrings.m
//  Growl
//
//  Created by Daniel Siemer on 1/30/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlPluginPreferenceStrings.h"

@implementation GrowlPluginPreferenceStrings

@synthesize growlDisplayOpacity;
@synthesize growlDisplayDuration;

@synthesize growlDisplayPriority;
@synthesize growlDisplayTextColor;
@synthesize growlDisplayBackgroundColor;

@synthesize growlDisplayLimitLines;
@synthesize growlDisplayScreen;
@synthesize growlDisplaySize;
@synthesize growlDisplaySizeNormal;
@synthesize growlDisplaySizeLarge;
@synthesize growlDisplaySizeSmall;

@synthesize growlDisplayFloatingIcon;

@synthesize effectLabel;
@synthesize slideEffect;
@synthesize fadeEffect;

-(id)init {
   if((self = [super init])){
      self.growlDisplayOpacity = GrowlDisplayOpacity;
      self.growlDisplayDuration = GrowlDisplayDuration;
      
      self.growlDisplayPriority = GrowlDisplayPriority;
      self.growlDisplayTextColor = GrowlDisplayTextColor;
      self.growlDisplayBackgroundColor = GrowlDisplayBackgroundColor;
      
      self.growlDisplayLimitLines = GrowlDisplayLimitLines;
      self.growlDisplayScreen = GrowlDisplayScreen;
      self.growlDisplaySize = GrowlDisplaySize;
      self.growlDisplaySizeNormal = GrowlDisplaySizeNormal;
      self.growlDisplaySizeLarge = GrowlDisplaySizeLarge;
      self.growlDisplaySizeSmall = GrowlDisplaySizeSmall;
      
      self.growlDisplayFloatingIcon = GrowlDisplayFloatingIcon;
      
      self.effectLabel = GrowlDisplayEffect;
      self.slideEffect = GrowlDisplayEffectSlide;
      self.fadeEffect = GrowlDisplayEffectFade;
   }
   return self;
}

-(void)dealloc {
   [growlDisplayOpacity release];
   
   [growlDisplayDuration release];
   
   [growlDisplayPriority release];
   [growlDisplayTextColor release];
   [growlDisplayBackgroundColor release];
   
   [growlDisplayLimitLines release];
   [growlDisplayScreen release];
   [growlDisplaySize release];
   [growlDisplaySizeNormal release];
   [growlDisplaySizeLarge release];
   [growlDisplaySizeSmall release];
   
   [growlDisplayFloatingIcon release];
   
   [effectLabel release];
   [fadeEffect release];
   [super dealloc];
}

@end
