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

#import "GrowlDefines.h"

@implementation GrowlGeneralViewController

@synthesize globalPositionPicker;
@synthesize startAtLoginSwitch;

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil forPrefPane:(GrowlPreferencePane *)aPrefPane {
   if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil forPrefPane:aPrefPane])){
      
   }
   return self;
}

-(void)awakeFromNib
{
   if([self.preferencesController shouldStartGrowlAtLogin])
      [startAtLoginSwitch setSelectedSegment:0];
   else
      [startAtLoginSwitch setSelectedSegment:1];   

	// bind the global position picker programmatically since its a custom view, register for notification so we can handle updating manually
	[globalPositionPicker bind:@"selectedPosition" 
                     toObject:self.preferencesController 
                  withKeyPath:@"selectedPosition" 
                      options:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self 
                                            selector:@selector(updatePosition:) 
                                                name:GrowlPositionPickerChangedSelectionNotification 
                                              object:globalPositionPicker];
}

- (void) updatePosition:(NSNotification *)notification {
	if([notification object] == globalPositionPicker) {
		[self.preferencesController setInteger:[globalPositionPicker selectedPosition] 
                                      forKey:GROWL_POSITION_PREFERENCE_KEY];
	}
}

-(IBAction)startGrowlAtLogin:(id)sender{
   if([(NSSegmentedControl*)sender selectedSegment] == 0){
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
         [startAtLoginSwitch setSelectedSegment:1];
         break;
   }
}

@end
