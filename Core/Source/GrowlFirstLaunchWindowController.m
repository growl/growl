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
#define FIRST_LAUNCH_OLD_GROWL_ID 3
#define FIRST_LAUNCH_WHATS_NEW_ID 4
#define FIRST_LAUNCH_DONE_ID 5

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

- (id)init
{
    if ((self = [super initWithWindowNibName:@"FirstLaunchWindow" owner:self])) {
        // Initialization code here.
        state = FIRST_LAUNCH_WELCOME_ID;
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [self updateViews];
}

-(void)windowWillClose:(NSNotification *)notification
{
    [[GrowlApplicationController sharedController] performSelector:@selector(firstLaunchClosed) withObject:nil afterDelay:1.0];
}

- (void)setState:(NSUInteger)newState
{
    if(state != newState){
        state = newState;
        [self updateViews];
    }
}

- (void)updateViews
{
    NSView *newContentView = nil;
    NSString *newTitle = nil;
    NSString *newContinue = nil;
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];

    switch (state) {
        case FIRST_LAUNCH_WELCOME_ID:
            newContentView = welcomeView;
            newTitle = FIRST_LAUNCH_WELCOME_TITLE;
            newContinue = FIRST_LAUNCH_START_GROWL_NEXT;
            nextState = FIRST_LAUNCH_START_GROWL_ID;
            break;
        case FIRST_LAUNCH_START_GROWL_ID:
            newContentView = startAtLoginView;
            newTitle = FIRST_LAUNCH_START_GROWL_TITLE;
            newContinue = FIRST_LAUNCH_OLD_GROWL_NEXT;
            nextState = FIRST_LAUNCH_OLD_GROWL_ID;
            break;
        case FIRST_LAUNCH_OLD_GROWL_ID:
            newContentView = removeOldGrowlView;
            newTitle = FIRST_LAUNCH_OLD_GROWL_TITLE;
            newContinue = [NSString stringWithFormat:FIRST_LAUNCH_WHATS_NEW_NEXT, version];
            nextState = FIRST_LAUNCH_WHATS_NEW_ID;
            break;
        case FIRST_LAUNCH_WHATS_NEW_ID:
            newContentView = whatsNewView;
            newTitle = [NSString stringWithFormat:FIRST_LAUNCH_WHATS_NEW_TITLE, version];
            newContinue = FIRST_LAUNCH_DONE_NEXT;
            nextState = FIRST_LAUNCH_DONE_ID;
            break;
        case FIRST_LAUNCH_DONE_ID:
            [self close];
        default:
            return;
            break;
    }
    
    
    CGFloat currentHeight = contentView.frame.size.height;
    CGFloat newHeight = newContentView.frame.size.height;
    
    NSRect newFrame = [self window].frame;
    CGFloat difference = newHeight - currentHeight;
    newFrame.origin.y = newFrame.origin.y - difference;
    newFrame.size.height = newFrame.size.height + (difference);
    [[self window] setFrame:newFrame display:YES animate:YES];
    
    [nextPageIntro setStringValue:newContinue];
    [pageTitle setStringValue:newTitle];
    if(currentContent){
        [contentView replaceSubview:currentContent with:newContentView];
    }else{
        [contentView addSubview:newContentView];
    }
    currentContent = newContentView;
}

-(void)close
{
    [super close];
    //Do this on a later loop so that the window has time to close
    [[GrowlApplicationController sharedController] performSelector:@selector(firstLaunchClosed) withObject:nil afterDelay:1.0];
}

-(IBAction)nextPage:(id)sender
{
    [self setState:nextState];
}

-(IBAction)exit:(id)sender
{
    [self close];
}

-(IBAction)enableGrowlAtLogin:(id)sender
{
    GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];
    [preferences setShouldStartGrowlAtLogin:YES];
    [preferences setAllowStartAtLogin:YES];
}

-(IBAction)openGrowlUninstallerPage:(id)sender
{
    //TODO FIX ME WITH RIGHT ADDRESS
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://growl.info/"]];
}

-(IBAction)openPreferences:(id)sender
{
    [[[GrowlApplicationController sharedController] statusMenu] openGrowlPreferences:self];
}

-(IBAction)openRollup:(id)sender
{
    //Open the rollup, or display an image or something?
}

@end
