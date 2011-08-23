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

#define FIRST_LAUNCH_WELCOME_TITLE      NSLocalizedString(@"Welcome to Growl!",@"Title welcoming a new user to growl")
#define FIRST_LAUNCH_START_GROWL_TITLE  NSLocalizedString(@"Let Growl Start at Login", @"Title for starting growl at login")
#define FIRST_LAUNCH_OLD_GROWL_TITLE    NSLocalizedString(@"Remove old copies of Growl",@"Title for removing old copies of growl")
#define FIRST_LAUNCH_WHATS_NEW_TITLE    NSLocalizedString(@"New to Growl %@", @"Title for whats new to growl")

#define FIRST_LAUNCH_START_GROWL_NEXT   NSLocalizedString(@"Continue on to enable Growl at login", @"Next page is enabling growl at login")
#define FIRST_LAUNCH_OLD_GROWL_NEXT     NSLocalizedString(@"Continue to remove old copies of Growl",@"Next page is removing old growl's")
#define FIRST_LAUNCH_WHATS_NEW_NEXT     NSLocalizedString(@"Continue to learn whats new in Growl %@",@"Next page is whats new in the current growl")
#define FIRST_LAUNCH_DONE_NEXT          NSLocalizedString(@"You are all ready to go, enjoy Growl!", @"Done with first launch dialog")

#define FIRST_LAUNCH_WELCOME_ID 1
#define FIRST_LAUNCH_START_GROWL_ID 2
#define FIRST_LAUNCH_WHATS_NEW_ID 3
#define FIRST_LAUNCH_DONE_ID 4
#define FIRST_LAUNCH_OLD_GROWL_ID 5

@implementation GrowlFirstLaunchWindowController

@synthesize contentView;
@synthesize currentContent;
@synthesize pageTitle;
@synthesize nextPageIntro;

@synthesize welcomeView;
@synthesize startAtLoginView;
@synthesize removeOldGrowlView;
@synthesize whatsNewView;

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
        state = FIRST_LAUNCH_WELCOME_ID;
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

- (void)setState:(NSUInteger)newState
{
    if(state != newState){
        state = newState;
        [self updateViews];
    }
}

-(void)updateNextState
{
   NSString *current = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];

   GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];
   NSString *newContinue = nil;
   switch (state) {
      case FIRST_LAUNCH_WELCOME_ID:
         if(![preferences allowStartAtLogin]){
            newContinue = FIRST_LAUNCH_START_GROWL_NEXT;
            nextState = FIRST_LAUNCH_START_GROWL_ID;
         }
      case FIRST_LAUNCH_START_GROWL_ID:
         if(!newContinue && [GrowlFirstLaunchWindowController previousVersionOlder]){
            newContinue = [NSString stringWithFormat:FIRST_LAUNCH_WHATS_NEW_NEXT, current];
            nextState = FIRST_LAUNCH_WHATS_NEW_ID;
         }
      case FIRST_LAUNCH_WHATS_NEW_ID:
         if(!newContinue && [GrowlPathUtilities growlPrefPaneBundle] != nil){
            newContinue = FIRST_LAUNCH_OLD_GROWL_NEXT;
            nextState = FIRST_LAUNCH_OLD_GROWL_ID;
         }
      case FIRST_LAUNCH_OLD_GROWL_ID:
         if(!newContinue){
            newContinue = FIRST_LAUNCH_DONE_NEXT;
            nextState = FIRST_LAUNCH_DONE_ID;
         }
         break;
      case FIRST_LAUNCH_DONE_ID:
      default:
         return;
   }
   [nextPageIntro setStringValue:newContinue];
}

- (void)updateViews
{
    NSView *newContentView = nil;
    NSString *newTitle = nil;
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];

    [self updateNextState];
    switch (state) {
        case FIRST_LAUNCH_WELCOME_ID:
            newContentView = welcomeView;
            newTitle = FIRST_LAUNCH_WELCOME_TITLE;
            break;
        case FIRST_LAUNCH_START_GROWL_ID:
            newContentView = startAtLoginView;
            newTitle = FIRST_LAUNCH_START_GROWL_TITLE;
            break;
        case FIRST_LAUNCH_WHATS_NEW_ID:
            newContentView = whatsNewView;
            newTitle = [NSString stringWithFormat:FIRST_LAUNCH_WHATS_NEW_TITLE, version];
            break;
        case FIRST_LAUNCH_OLD_GROWL_ID:
            newContentView = removeOldGrowlView;
            newTitle = FIRST_LAUNCH_OLD_GROWL_TITLE;
            break;
        case FIRST_LAUNCH_DONE_ID:
            [self close];
        default:
            return;
            break;
    }
   
    CGFloat height = contentView.frame.size.height;
    CGFloat yOrigin = height - newContentView.frame.size.height;
   
    [pageTitle setStringValue:newTitle];
    if(currentContent){
        [currentContent retain];
        [contentView replaceSubview:currentContent with:newContentView];
    }else{
        [contentView addSubview:newContentView];
    }

    currentContent = newContentView;
    [currentContent setFrameOrigin:NSMakePoint(0, yOrigin)];
}

-(IBAction)nextPage:(id)sender
{
    [self setState:nextState];
}

-(IBAction)enableGrowlAtLogin:(id)sender
{
    GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];
    [preferences setShouldStartGrowlAtLogin:YES];
    [preferences setAllowStartAtLogin:YES];
}

-(IBAction)openGrowlUninstallerPage:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://growl.info/downloads.php"]];
}

-(IBAction)openPreferences:(id)sender
{
    [[[GrowlApplicationController sharedController] statusMenu] openGrowlPreferences:self];
}

@end
