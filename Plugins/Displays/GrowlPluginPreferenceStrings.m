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
@synthesize growlDisplayPriorityVeryLow;
@synthesize growlDisplayPriorityModerate;
@synthesize growlDisplayPriorityNormal;
@synthesize growlDisplayPriorityHigh;
@synthesize growlDisplayPriorityEmergency;

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
      NSBundle *frameworkBundle = [NSBundle bundleForClass:[self class]];
      
      self.growlDisplayOpacity = NSLocalizedStringFromTableInBundle(@"Opacity:", @"PluginPrefStrings", frameworkBundle, @"How clear the display is");
      self.growlDisplayDuration = NSLocalizedStringFromTableInBundle(@"Duration:", @"PluginPrefStrings", frameworkBundle, @"How long a notification will stay on screen");
      
      self.growlDisplayPriority = NSLocalizedStringFromTableInBundle(@"Priority: (low to high)", @"PluginPrefStrings", frameworkBundle, @"Label for columns of color wells for various priority levels");
      self.growlDisplayPriorityVeryLow = NSLocalizedStringFromTableInBundle(@"Very Low", @"PluginPrefStrings", frameworkBundle, @"Notification Priority Very Low");
      self.growlDisplayPriorityModerate = NSLocalizedStringFromTableInBundle(@"Moderate", @"PluginPrefStrings", frameworkBundle, @"Notification Priority Moderate");
      self.growlDisplayPriorityNormal = NSLocalizedStringFromTableInBundle(@"Normal", @"PluginPrefStrings", frameworkBundle, @"Notification Priority Normal");
      self.growlDisplayPriorityHigh = NSLocalizedStringFromTableInBundle(@"High", @"PluginPrefStrings", frameworkBundle, @"Notification Priority High");
      self.growlDisplayPriorityEmergency = NSLocalizedStringFromTableInBundle(@"Emergency", @"PluginPrefStrings", frameworkBundle, @"Notification Priority Emergency");
      
      self.growlDisplayTextColor = NSLocalizedStringFromTableInBundle(@"Text", @"PluginPrefStrings", frameworkBundle, @"Label for row of color wells for the text element of the plugin");
      self.growlDisplayBackgroundColor = NSLocalizedStringFromTableInBundle(@"Background", @"PluginPrefStrings", frameworkBundle, @"Label for row of color wells for the background of the plugin");
      
      self.growlDisplayLimitLines = NSLocalizedStringFromTableInBundle(@"Limit to 2-5 lines", @"PluginPrefStrings", frameworkBundle, @"Checkbox to limit the display to 2-5 lines");
      self.growlDisplayScreen = NSLocalizedStringFromTableInBundle(@"Screen:", @"PluginPrefStrings", frameworkBundle, @"Label for box to select screen for display to use");
      self.growlDisplaySize = NSLocalizedStringFromTableInBundle(@"Size:", @"PluginPrefStrings", frameworkBundle, @"Label for pop up box for selecting the size of the display");
      self.growlDisplaySizeNormal = NSLocalizedStringFromTableInBundle(@"Normal", @"PluginPrefStrings", frameworkBundle, @"Normal size for the display");
      self.growlDisplaySizeLarge = NSLocalizedStringFromTableInBundle(@"Large", @"PluginPrefStrings", frameworkBundle, @"Large size for the display");
      self.growlDisplaySizeSmall = NSLocalizedStringFromTableInBundle(@"Small", @"PluginPrefStrings", frameworkBundle, @"Small size for the display");
      
      self.growlDisplayFloatingIcon = NSLocalizedStringFromTableInBundle(@"Floating Icon", @"PluginPrefStrings", frameworkBundle, @"Label for checkbox that says to do a floating icon");
      
      self.effectLabel = NSLocalizedStringFromTableInBundle(@"Effect:", @"PluginPrefStrings", frameworkBundle, @"Label for the effect to use");
      self.slideEffect = NSLocalizedStringFromTableInBundle(@"Slide", @"PluginPrefStrings", frameworkBundle, @"A slide effect");
      self.fadeEffect = NSLocalizedStringFromTableInBundle(@"Fade", @"PluginPrefStrings", frameworkBundle, @"A fade effect");
   }
   return self;
}

-(void)dealloc {
   [growlDisplayOpacity release];
   
   [growlDisplayDuration release];
   
   [growlDisplayPriority release];
	self.growlDisplayPriorityVeryLow = nil;
	self.growlDisplayPriorityModerate = nil;
	self.growlDisplayPriorityNormal = nil;
	self.growlDisplayPriorityHigh = nil;
	self.growlDisplayPriorityEmergency = nil;
	
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
