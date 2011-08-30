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

@synthesize pageTitle;
@synthesize nextPageIntro;
@synthesize pageBody;

@synthesize actionButton;
@synthesize continueButton;

@synthesize state;
@synthesize nextState;

+(BOOL)previousVersionOlder
{
   NSString *current = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
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
        state = firstLaunchWelcome;
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
   GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];
   NSString *newContinue = nil;
   switch (state) {
      case firstLaunchWelcome:
         if(![preferences allowStartAtLogin]){
            newContinue = FirstLaunchStartGrowlNext;
            nextState = firstLaunchStartGrowl;
         }
      case firstLaunchStartGrowl:
         if(!newContinue && [GrowlFirstLaunchWindowController previousVersionOlder]){
            newContinue = FirstLaunchWhatsNewNext;
            nextState = firstLaunchWhatsNew1;
         }
      /* If we fell into firstLaunchWhatsNew1 above, we wind up here after the other two panes of intro*/
      case firstLaunchWhatsNew3:
         if(!newContinue && [GrowlPathUtilities growlPrefPaneBundle] != nil){
            newContinue = FirstLaunchOldGrowlNext;
            nextState = firstLaunchOldGrowl;
         }
      case firstLaunchOldGrowl:
         if(!newContinue){
            newContinue = FirstLaunchDoneNext;
            nextState = firstLaunchDone;
         }
         break;

      /* Thes two cases dont have fall throughs, if you hit them, you get to see the rest of whats new */
      case firstLaunchWhatsNew1:
         nextState = firstLaunchWhatsNew2;
         break;
      case firstLaunchWhatsNew2:
         nextState = firstLaunchWhatsNew3;
         break;
      
      /* Done, or something went really wrong*/
      default:
         return;
   }
   if(newContinue)
      [nextPageIntro setStringValue:newContinue];
   
   if(nextState == firstLaunchDone)
      [continueButton setTitle:NSLocalizedString(@"Done", @"Done")];
}

- (void)updateViews
{
    NSString *newTitle = nil;
    NSString *newBody = nil;
    NSString *newButton = nil;

    [self updateNextState];
    switch (state) {
        case firstLaunchWelcome:
            newTitle = FirstLaunchWelcomeTitle;
            newBody = FirstLaunchWelcomeBody;
            break;
        case firstLaunchStartGrowl:
            newTitle = FirstLaunchStartGrowlTitle;
            newBody = FirstLaunchStartGrowlBody;
            newButton = FirstLaunchStartGrowlButton;
            break;
        case firstLaunchWhatsNew1:
            newTitle = FirstLaunchWhatsNewTitle;
            newBody = FirstLaunchWhatsNewBody1;
            newButton = FirstLaunchWhatsNewButton1;
            break;
        case firstLaunchWhatsNew2:
            newTitle = FirstLaunchWhatsNewTitle;
            newBody = FirstLaunchWhatsNewBody2;
            newButton = FirstLaunchWhatsNewButton2;
            break;
        case firstLaunchWhatsNew3:
            newTitle = FirstLaunchWhatsNewTitle;
            newBody = FirstLaunchWhatsNewBody3;
            newButton = FirstLaunchWhatsNewButton3;
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
   
    [pageTitle setStringValue:newTitle];
    [pageBody setStringValue:newBody];
    if(newButton){
       [actionButton setHidden:NO];
       [actionButton setTitle:newButton];
    }else
       [actionButton setHidden:YES];
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
      case firstLaunchWhatsNew1:
         [self openPreferences:sender];
         break;
      case firstLaunchWhatsNew2:
         [self disableHistory:sender];
         break;
      case firstLaunchWhatsNew3:
         [self openGrowlGNTPPage:sender];
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

/*TODO: MAKE POINT AT RIGHT PAGE*/
-(IBAction)openGrowlGNTPPage:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://growl.info/documentation.php"]];
}

-(IBAction)openPreferences:(id)sender
{
    [[[GrowlApplicationController sharedController] statusMenu] openGrowlPreferences:self];
}

-(IBAction)disableHistory:(id)sender
{
   [[GrowlPreferencesController sharedController] setGrowlHistoryLogEnabled:NO];
}

@end
