//
//  SGHotKeyCenterAppDelegate.m
//  SGHotKeyCenter
//
//  Created by Justin Williams on 7/26/09.
//  Copyright 2009 Second Gear. All rights reserved.
//

#import "SGHotKeyCenterAppDelegate.h"
#import "SGHotKeyCenter.h"

NSString *kGlobalHotKey = @"Global Hot Key";

@implementation SGHotKeyCenterAppDelegate

@synthesize window;
@synthesize hotKeyControl;
@synthesize resultsTextField;
@synthesize hotKey;

- (void)dealloc {
  [window release];
  [hotKeyControl release];
  [resultsTextField release];
  [hotKey release];
  [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)theNotification {
	[[SGHotKeyCenter sharedCenter] unregisterHotKey:hotKey];	
  id keyComboPlist = [[NSUserDefaults standardUserDefaults] objectForKey:kGlobalHotKey];
	SGKeyCombo *keyCombo = [[[SGKeyCombo alloc] initWithPlistRepresentation:keyComboPlist] autorelease];
	hotKey = [[SGHotKey alloc] initWithIdentifier:kGlobalHotKey keyCombo:keyCombo target:self action:@selector(hotKeyPressed:)];
	[[SGHotKeyCenter sharedCenter] registerHotKey:hotKey];
	[hotKeyControl setKeyCombo:SRMakeKeyCombo(hotKey.keyCombo.keyCode, [hotKeyControl carbonToCocoaFlags:hotKey.keyCombo.modifiers])];
}

- (void)applicationWillTerminate:(NSNotification *)theNotification {
	[[NSUserDefaults standardUserDefaults] setObject:[self.hotKey.keyCombo plistRepresentation] forKey:kGlobalHotKey];
}

- (void)hotKeyPressed:(id)sender {
	[resultsTextField setStringValue:[NSString stringWithFormat: @"%@\n%@", sender, [NSCalendarDate calendarDate]]];
}

#pragma mark -
#pragma mark ShortcutRecorder Delegate Methods

- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason {	
	return NO;
}

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  
  SGKeyCombo *keyCombo = [SGKeyCombo keyComboWithKeyCode:[aRecorder keyCombo].code
                                               modifiers:[aRecorder cocoaToCarbonFlags:[aRecorder keyCombo].flags]];
  
	if (aRecorder == hotKeyControl) {		
		self.hotKey.keyCombo = keyCombo;

		// Re-register the new hot key
    [[SGHotKeyCenter sharedCenter] registerHotKey:self.hotKey];
		[defaults setObject:[keyCombo plistRepresentation] forKey:kGlobalHotKey];
	} 
  
	[defaults synchronize];
}

@end
