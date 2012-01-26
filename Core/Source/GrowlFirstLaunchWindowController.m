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

@implementation GrowlFirstLaunchWindowController

@synthesize windowTitle;
@synthesize textBoxString;
@synthesize sectionTitle;
@synthesize actionButtonTitle;
@synthesize continueButtonTitle;
@synthesize continueButtonLabel;

@synthesize actionEnabled;

@synthesize state;
@synthesize nextState;

+(BOOL)previousVersionOlder
{
   /*NSString *current = @"1.3";//[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
   NSString *previous = [[GrowlPreferencesController sharedController] objectForKey:LastKnownVersionKey];
   
   return (!previous || compareVersionStrings(previous, current) == kCFCompareLessThan);*/
   return YES;
}

+(BOOL)shouldRunFirstLaunch
{
   /*GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];
   if(![preferences objectForKey:GrowlFirstLaunch] || [preferences boolForKey:GrowlFirstLaunch])
      return YES;
   

   if([GrowlFirstLaunchWindowController previousVersionOlder]){
      return YES;
   }
   return NO;*/
   return YES;
}

- (id)init
{
    if ((self = [super initWithWindowNibName:@"FirstLaunchWindow" owner:self])) {
        // Initialization code here.
        state = firstLaunchWelcome;
       self.windowTitle = NSLocalizedString(@"Welcome to Growl!", @"");
       self.continueButtonTitle = NSLocalizedString(@"Continue", @"Continue button title");
    }
    
    return self;
}

- (void)awakeFromNib
{
    [self updateViews];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

-(void)close
{
   NSString *current = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
   [[GrowlPreferencesController sharedController] setObject:current forKey:LastKnownVersionKey];
   [[GrowlApplicationController sharedController] performSelector:@selector(firstLaunchClosed) withObject:nil afterDelay:1.0];
   [super close];
}

- (void)setState:(GrowlFirstLaunchState)newState
{
    if(state != newState){
        state = newState;
        [self updateViews];
    }
}

-(void)updateNextState
{
   //GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];
   NSString *newContinue = nil;
   switch (state) {
      case firstLaunchWelcome:
         if(/*![preferences allowStartAtLogin]*/YES){
            newContinue = FirstLaunchStartGrowlNext;
            nextState = firstLaunchStartGrowl;
         }
      case firstLaunchStartGrowl:
         if(!newContinue /*&& [GrowlPathUtilities growlPrefPaneBundle] != nil*/){
            newContinue = FirstLaunchOldGrowlNext;
            nextState = firstLaunchOldGrowl;
         }
      case firstLaunchOldGrowl:
         if(!newContinue){
            newContinue = FirstLaunchDoneNext;
            nextState = firstLaunchDone;
         }
         break;      
      /* Done, or something went really wrong*/
      default:
         return;
   }
   if(newContinue)
      self.continueButtonLabel = newContinue;
   
   if(nextState == firstLaunchDone)
      self.continueButtonTitle = NSLocalizedString(@"Done", @"Done");
}

- (void)updateViews
{
    NSString *newTitle = nil;
    id newBody = nil;
    NSString *newButton = nil;

    [self updateNextState];
    switch (state) {
        case firstLaunchWelcome:
            newTitle = FirstLaunchWelcomeTitle;
            NSData *data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Welcome" ofType:@"rtf"]];
            newBody = [[[NSAttributedString alloc] initWithRTF:data documentAttributes:NULL] autorelease];
            break;
        case firstLaunchStartGrowl:
            newTitle = FirstLaunchStartGrowlTitle;
            newBody = FirstLaunchStartGrowlBody;
            newButton = FirstLaunchStartGrowlButton;
            break;
        case firstLaunchOldGrowl:
            newTitle = FirstLaunchOldGrowlTitle;
            newBody = FirstLaunchOldGrowlBody;
            newButton = FirstLaunchOldGrowlButton;
            break;
        default:
            [self close];
            return;
            break;
    }
   
   self.sectionTitle = newTitle;
   if([newBody isKindOfClass:[NSString class]])
      self.textBoxString = [[[NSAttributedString alloc] initWithString:newBody] autorelease];
   else if([newBody isKindOfClass:[NSAttributedString class]])
      self.textBoxString = newBody;
   
   if(newButton){
      self.actionEnabled = YES;
      self.actionButtonTitle = newButton;
   }else
      self.actionEnabled = NO;
}

-(IBAction)nextPage:(id)sender
{
    [self setState:nextState];
}

-(IBAction)actionButton:(id)sender
{
   switch (state) {
      case firstLaunchStartGrowl:
         [self enableGrowlAtLogin:sender];
         break;
      case firstLaunchOldGrowl:
         [self openGrowlUninstallerPage:sender];
         break;
      default:
         break;
   }
}

-(IBAction)enableGrowlAtLogin:(id)sender
{
    GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];
    [preferences setShouldStartGrowlAtLogin:YES];
    [preferences setAllowStartAtLogin:YES];
}

-(IBAction)openGrowlUninstallerPage:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://growl.info/documentation/growl-package-removal.php#1.2easy"]];
}

@end
