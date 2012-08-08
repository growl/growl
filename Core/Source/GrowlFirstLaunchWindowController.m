//
//  GrowlFirstLaunchWindowController.m
//  Growl
//
//  Created by Daniel Siemer on 8/17/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlFirstLaunchWindowController.h"
#import "GrowlApplicationController.h"
#import "GrowlPreferencesController.h"
#import "GrowlVersionUtilities.h"
#import "GrowlPathUtilities.h"
#import "GrowlMenu.h"

typedef void(^GrowlFirstLaunchAction)(void);

@implementation GrowlFirstLaunchWindowController

@synthesize windowTitle;
@synthesize textBoxString;
@synthesize actionButtonTitle;
@synthesize continueButtonTitle;

@synthesize actionEnabled;

@synthesize current;

@synthesize launchViews;
@synthesize progressIndicator;
@synthesize progressLabel;

+(BOOL)previousVersionOlder
{
   NSString *current = @"2.0b4";//[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
   NSString *previous = [[GrowlPreferencesController sharedController] objectForKey:LastKnownVersionKey];
   return (!previous || compareVersionStrings(previous, current) == kCFCompareLessThan);
}

+(BOOL)shouldRunFirstLaunch
{
   GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];
   if(![preferences objectForKey:GrowlFirstLaunch] || [preferences boolForKey:GrowlFirstLaunch])
      return YES;
   

   if([GrowlFirstLaunchWindowController previousVersionOlder]){
      return YES;
   }
   return NO;
}

- (id)init
{
    if ((self = [super initWithWindowNibName:@"FirstLaunchWindow" owner:self])) {
        // Initialization code here.
       self.windowTitle = NSLocalizedString(@"Welcome to Growl!", @"");
       self.continueButtonTitle = NSLocalizedString(@"Continue", @"Continue button title");
       
       GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];
       self.current = 0;
       
       NSMutableArray *views = [NSMutableArray array];
      
       NSData *welcomeData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"Welcome" withExtension:@"rtf"]];
       NSAttributedString *welcomeString = [[[NSAttributedString alloc] initWithRTF:welcomeData documentAttributes:nil] autorelease];
       NSDictionary *welcomeDict = [NSDictionary dictionaryWithObjectsAndKeys:welcomeString, @"textBody", nil];
       [views addObject:welcomeDict];
       
       NSData *whatsNewData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"WhatsNew" withExtension:@"rtf"]];
       NSAttributedString *whatsNewString = [[[NSAttributedString alloc] initWithRTF:whatsNewData documentAttributes:nil] autorelease];
       NSDictionary *whatsNewDict = [NSDictionary dictionaryWithObjectsAndKeys:whatsNewString, @"textBody", nil];
       [views addObject:whatsNewDict];
       
       if(![preferences allowStartAtLogin]) {
         GrowlFirstLaunchAction loginBlock = [^{
             GrowlPreferencesController *prefs = [GrowlPreferencesController sharedController];
             [prefs setShouldStartGrowlAtLogin:YES];
             [prefs setAllowStartAtLogin:YES];
          } copy];
          
          NSData *loginData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"StartAtLogin" withExtension:@"rtf"]];
          NSAttributedString *loginString = [[[NSAttributedString alloc] initWithRTF:loginData documentAttributes:nil] autorelease];
          NSDictionary *loginDict = [NSDictionary dictionaryWithObjectsAndKeys:loginString, @"textBody", 
                                                                               loginBlock, @"actionBlock", 
                                                                               FirstLaunchStartGrowlButton, @"actionTitle", nil];
          [views addObject:loginDict];
          [loginBlock release];
       }
       if([GrowlPathUtilities growlPrefPaneBundle] != nil) {
          GrowlFirstLaunchAction oldBlock = [^{
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://growl.info/documentation/growl-package-removal.php#1.2easy"]];
          } copy];
          NSData *oldData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"OldGrowl" withExtension:@"rtf"]];
          NSAttributedString *oldString = [[[NSAttributedString alloc] initWithRTF:oldData documentAttributes:nil] autorelease];
          NSDictionary *oldDict = [NSDictionary dictionaryWithObjectsAndKeys:oldString, @"textBody", 
                                                                             oldBlock, @"actionBlock",
                                                                             FirstLaunchOldGrowlButton, @"actionTitle", nil];
          [views addObject:oldDict];
          [oldBlock release];
       }
       
       self.launchViews = [[views copy] autorelease];
    }
    
    return self;
}

-(void)awakeFromNib
{
   [progressIndicator setMaxValue:[launchViews count]];
   [self showCurrent];
}

- (void)dealloc
{
    [windowTitle release];
    [textBoxString release];
    [actionButtonTitle release];
    [continueButtonTitle release];
    [launchViews release];
    [progressLabel release];

    [super dealloc];
}

-(void)close
{
   NSString *currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
   [[GrowlPreferencesController sharedController] setObject:currentVersion forKey:LastKnownVersionKey];
   [[GrowlApplicationController sharedController] performSelector:@selector(firstLaunchClosed) withObject:nil afterDelay:1.0];
   [super close];
}

-(void)showCurrent
{
   self.progressLabel = [NSString stringWithFormat:@"%lu/%lu", current + 1, [launchViews count]];
   [progressIndicator setDoubleValue:(double)(current + 1)];
   if(current == [launchViews count] - 1){
      self.continueButtonTitle = NSLocalizedString(@"Done", @"Continue button title when done");
   }
   
   if([[launchViews objectAtIndex:current] valueForKey:@"actionBlock"]){
      self.actionEnabled = YES;
      self.actionButtonTitle = [[launchViews objectAtIndex:current] valueForKey:@"actionTitle"];
   }
   
   self.textBoxString = [[launchViews objectAtIndex:current] valueForKey:@"textBody"];
}

-(IBAction)nextPage:(id)sender
{
   self.current++;
   if(current >= [launchViews count]){
      [self close];
      return;
   }
   [self showCurrent];
}

-(IBAction)actionButton:(id)sender
{
   if([[launchViews objectAtIndex:current] valueForKey:@"actionBlock"]){
      GrowlFirstLaunchAction action = [[launchViews objectAtIndex:current] valueForKey:@"actionBlock"];
      action();
   }
}

@end
