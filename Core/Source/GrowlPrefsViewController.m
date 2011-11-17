//
//  GrowlPrefsViewController.m
//  Growl
//
//  Created by Daniel Siemer on 11/9/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlPrefsViewController.h"
#import "GrowlPreferencePane.h"
#import "GrowlPreferencesController.h"

@implementation GrowlPrefsViewController

@synthesize prefPane;
@synthesize preferencesController;
@synthesize releaseTimer;

- (id)initWithNibName:(NSString *)nibNameOrNil 
               bundle:(NSBundle *)nibBundleOrNil
          forPrefPane:(GrowlPreferencePane*)aPrefPane
{
    if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
       self.prefPane = aPrefPane;
       self.preferencesController = [GrowlPreferencesController sharedController];
    }
    
    return self;
}

- (void)dealloc
{
   [prefPane release];
   [super dealloc];
}

+ (NSString*)nibName {
   return nil;
}

- (void)releaseTimerFire:(NSTimer*)theTimer {
   [self.releaseTimer invalidate];
   self.releaseTimer = nil;
   if([[self view] superview]){
      return;
   }
   [prefPane releaseTab:self];
}

- (void)viewWillLoad{
   if(self.releaseTimer){
      [releaseTimer invalidate];
      self.releaseTimer = nil;
   }
}
- (void)viewDidLoad{
   
}
- (void)viewWillUnload{
   
}
- (void)viewDidUnload{
   if(!releaseTimer){
      self.releaseTimer = [NSTimer timerWithTimeInterval:30.0
                                                  target:self 
                                                selector:@selector(releaseTimerFire:) 
                                                userInfo:nil 
                                                 repeats:NO];
      [[NSRunLoop mainRunLoop] addTimer:self.releaseTimer forMode:NSRunLoopCommonModes];
   }
}

@end
