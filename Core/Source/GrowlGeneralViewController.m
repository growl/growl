//
//  GrowlGeneralViewController.m
//  Growl
//
//  Created by Daniel Siemer on 11/9/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlGeneralViewController.h"
#import "GrowlPreferencePane.h"
#import "GrowlPreferencesController.h"
#import "GrowlPositionPicker.h"
#import "GrowlOnSwitch.h"
#import <ShortcutRecorder/ShortcutRecorder.h>
#import <GrowlPlugins/SGHotKey.h>
#import <GrowlPlugins/SGKeyCombo.h>

#import "GrowlDefines.h"

@implementation GrowlGeneralViewController

@synthesize globalPositionPicker;
@synthesize startAtLoginSwitch;
@synthesize recorderControl;
@synthesize useAppleNotificationCenterSwitch;
@synthesize useAppleNotificationCenterLabelField;
@synthesize useAppleNotificationCenterExplanationField;
@synthesize growlClawLogo;
@synthesize additionalDownloadsButton;

@synthesize additionalDownloadsButtonTitle;
@synthesize startGrowlAtLoginLabel;
@synthesize defaultStartingPositionLabel;
@synthesize iconMenuOptionsList;
@synthesize closeAllNotificationsTitle;
@synthesize useAppleNotificationCenterLabel;
@synthesize appleNotificationCenterExplanation;

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil forPrefPane:(GrowlPreferencePane *)aPrefPane {
   if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil forPrefPane:aPrefPane])){
      self.additionalDownloadsButtonTitle = NSLocalizedString(@"Additional Downloads", @"Button title for opening growl.info to downloads page");
      self.startGrowlAtLoginLabel = NSLocalizedString(@"Start Growl at Login", @"Start Growl at Login switch label");
      self.useAppleNotificationCenterLabel = NSLocalizedString(@"OS X Notifications", @"Use Mac OS X Notifications switch label");
      self.defaultStartingPositionLabel = NSLocalizedString(@"Default starting position for notifications", @"Label for the global default starting position picker");
      self.iconMenuOptionsList = [NSArray arrayWithObjects:NSLocalizedString(@"Show icon in the menubar", @"Growl will have a menu bar icon only"),
                                                           NSLocalizedString(@"Show icon in the dock", @"Growl will have an icon only in the dock"),
                                                           NSLocalizedString(@"Show icon in both", @"Growl will have an icon in the menu and the dock"),
                                                           NSLocalizedString(@"No icon visible", @"Growl will run compeletely in the background"), nil];
       self.closeAllNotificationsTitle = NSLocalizedString(@"Close all notifications", @"close all open notifications");
		self.appleNotificationCenterExplanation = NSLocalizedString(@"Disable Growl visual controls and foward notifications to OS X", @"Explanation for what the big magic notification center switch means");
   }
   return self;
}

-(void)awakeFromNib
{
   [startAtLoginSwitch setState:[self.preferencesController shouldStartGrowlAtLogin]];
   [startAtLoginSwitch addObserver:self 
                        forKeyPath:@"state" 
                           options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                           context:nil];
   
   [useAppleNotificationCenterSwitch setState:[self.preferencesController shouldUseAppleNotifications]];
   [useAppleNotificationCenterSwitch addObserver:self
                                forKeyPath:@"state"
                                   options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                                   context:nil];
   
   // Check if we have Notification Center support.
   // If so, we hide the Growl logo and show the on/off switch there.
   // If not, we hide those controls, and change the globalPositionPicker's nextKeyView
   // back to the "Additional Downloads" button.
   BOOL hasNotificationCenter = (NSClassFromString(@"NSUserNotificationCenter") != nil);
   [growlClawLogo setHidden:hasNotificationCenter];
   [useAppleNotificationCenterSwitch setHidden:!hasNotificationCenter];
   [useAppleNotificationCenterLabelField setHidden:!hasNotificationCenter];
	[useAppleNotificationCenterExplanationField setHidden:!hasNotificationCenter];
   
   if (!hasNotificationCenter) {
      globalPositionPicker.nextKeyView = additionalDownloadsButton;
   }
   
	// bind the global position picker programmatically since its a custom view, register for notification so we can handle updating manually
	[globalPositionPicker bind:@"selectedPosition" 
                     toObject:self.preferencesController 
                  withKeyPath:@"selectedPosition" 
                      options:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self 
                                            selector:@selector(updatePosition:) 
                                                name:GrowlPositionPickerChangedSelectionNotification 
                                              object:globalPositionPicker];

    KeyCombo combo = {SRCarbonToCocoaFlags([GrowlPreferencesController sharedController].closeAllCombo.modifiers), [GrowlPreferencesController sharedController].closeAllCombo.keyCode};
    [self.recorderControl setKeyCombo:combo];
}

+ (NSString*)nibName {
   return @"GeneralPrefs";
}

- (void)dealloc {
    [startAtLoginSwitch removeObserver:self forKeyPath:@"state"];
    [additionalDownloadsButtonTitle release];
    [startGrowlAtLoginLabel release];
    [useAppleNotificationCenterLabel release];
    [closeAllNotificationsTitle release];
    [defaultStartingPositionLabel release];
    [iconMenuOptionsList release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
   if(object == startAtLoginSwitch && [keyPath isEqualToString:@"state"])
      [self startGrowlAtLogin:nil];
   if (object == useAppleNotificationCenterSwitch && [keyPath isEqualToString:@"state"])
      [self useAppleNotificationCenter:nil];
}

- (void) updatePosition:(NSNotification *)notification {
	if([notification object] == globalPositionPicker) {
		[self.preferencesController setInteger:[globalPositionPicker selectedPosition] 
                                      forKey:GROWL_POSITION_PREFERENCE_KEY];
	}
}

-(IBAction)startGrowlAtLogin:(id)sender{
   if([startAtLoginSwitch state]){
      if(![self.preferencesController allowStartAtLogin]){
         NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Alert! Enabling this option will add Growl.app to your login items", nil)
                                          defaultButton:NSLocalizedString(@"Ok", nil)
                                        alternateButton:NSLocalizedString(@"Cancel", nil)
                                            otherButton:nil
                              informativeTextWithFormat:NSLocalizedString(@"Allowing this will let Growl launch everytime you login, so that it is available for applications which use it at all times", nil)];
         [alert beginSheetModalForWindow:[sender window]
                           modalDelegate:self
                          didEndSelector:@selector(startGrowlAtLoginAlert:didReturn:contextInfo:)
                             contextInfo:nil];
      }else{
         [self.preferencesController setShouldStartGrowlAtLogin:YES];
      }
   }else{
      [self.preferencesController setShouldStartGrowlAtLogin:NO];
   }
}

-(IBAction)useAppleNotificationCenter:(id)sender
{
   [self.preferencesController setShouldUseAppleNotifications:[useAppleNotificationCenterSwitch state]];
}

-(IBAction)launchAdditionalDownloads:(id)sender{
   [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://growl.info/downloads.php"]];
}

- (IBAction)startGrowlAtLoginAlert:(NSAlert*)alert didReturn:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
   switch (returnCode) {
      case NSAlertDefaultReturn:
         [self.preferencesController setAllowStartAtLogin:YES];
         [self.preferencesController setShouldStartGrowlAtLogin:YES];
         break;
      default:
         [startAtLoginSwitch setState:NO];
         break;
   }
}

- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason
{
    return NO;
}

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo
{
    SGKeyCombo *combo = [SGKeyCombo keyComboWithKeyCode:newKeyCombo.code modifiers:SRCocoaToCarbonFlags(newKeyCombo.flags)];
    
    if(combo.keyCode == -1)
        combo = nil;
    
    [GrowlPreferencesController sharedController].closeAllCombo = combo;
}

@end
