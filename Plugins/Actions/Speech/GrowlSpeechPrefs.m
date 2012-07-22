//
//  GrowlSpeechPrefs.m
//  Display Plugins
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004–2011 The Growl Project. All rights reserved.
//

#import "GrowlSpeechPrefs.h"
#import "GrowlSpeechDefines.h"
#import <AppKit/NSSpeechSynthesizer.h>
#import <ShortcutRecorder/ShortcutRecorder.h>
#import <GrowlPlugins/SGHotKey.h>
#import <GrowlPlugins/SGKeyCombo.h>

@interface GrowlSpeechPrefs ()

@property (nonatomic, retain) NSString *voiceLabel;
@property (nonatomic, retain) NSString *limitCharCheckboxTitle;
@property (nonatomic, retain) NSString *charactersLabel;
@property (nonatomic, retain) NSString *rateAdjustCheckbox;
@property (nonatomic, retain) NSString *slowLabel;
@property (nonatomic, retain) NSString *fastLabel;
@property (nonatomic, retain) NSString *volumeAdjustCheckbox;
@property (nonatomic, retain) NSString *globalHotkeysBoxLabel;
@property (nonatomic, retain) NSString *pauseResumeLabel;
@property (nonatomic, retain) NSString *skipNoteLabel;
@property (nonatomic, retain) NSString *clickNoteLabel;

@end

@implementation GrowlSpeechPrefs
@synthesize pauseShortcut;
@synthesize skipShortcut;
@synthesize clickShortcut;
@synthesize voices;

@synthesize useLimit;
@synthesize characterLimit;
@synthesize useRate;
@synthesize rate;
@synthesize useVolume;
@synthesize volume;

@synthesize voiceLabel;
@synthesize limitCharCheckboxTitle;
@synthesize charactersLabel;
@synthesize rateAdjustCheckbox;
@synthesize slowLabel;
@synthesize fastLabel;
@synthesize volumeAdjustCheckbox;
@synthesize globalHotkeysBoxLabel;
@synthesize pauseResumeLabel;
@synthesize skipNoteLabel;
@synthesize clickNoteLabel;

- (id)initWithBundle:(NSBundle *)bundle {
   if((self = [super initWithBundle:bundle])){
      self.voiceLabel = NSLocalizedStringFromTableInBundle(@"Voice:", @"Localizable", bundle, @"Label for popup with voices");
		self.limitCharCheckboxTitle = NSLocalizedStringFromTableInBundle(@"Limit to", @"Localizable", bundle, @"Limit speech display to a given amount of characters");
		self.charactersLabel = NSLocalizedStringFromTableInBundle(@"characters", @"Localizable", bundle, @"label for the unit in the box for character limit");
		self.rateAdjustCheckbox = NSLocalizedStringFromTableInBundle(@"Adjust rate:", @"Localizable", bundle, @"Rate adjustment slider checkbox");
		self.slowLabel = NSLocalizedStringFromTableInBundle(@"Slow", @"Localizable", bundle, @"Label speech slower");
		self.fastLabel = NSLocalizedStringFromTableInBundle(@"Fast:", @"Localizable", bundle, @"Label for speech faster");
		self.volumeAdjustCheckbox = NSLocalizedStringFromTableInBundle(@"Volume:", @"Localizable", bundle, @"Volume adjustment checkcbox");
		self.globalHotkeysBoxLabel = NSLocalizedStringFromTableInBundle(@"Global Hotkeys:", @"Localizable", bundle, @"Label for box containing global hot keys for the speech display");
		self.pauseResumeLabel = NSLocalizedStringFromTableInBundle(@"Pause/Resume", @"Localizable", bundle, @"Label for hotkey recorder for pause/resume the speech display");
		self.skipNoteLabel = NSLocalizedStringFromTableInBundle(@"Skip Note", @"Localizable", bundle, @"Label for hotkey recorder for skipping the current note");
		self.clickNoteLabel = NSLocalizedStringFromTableInBundle(@"Click Note", @"Localizable", bundle, @"Label for hotkey recorder for 'clicking' the current note being spoken");
	}
   return self;
}

-(void)dealloc {
	self.voices = nil;
	self.voiceLabel = nil;
	self.limitCharCheckboxTitle = nil;
	self.charactersLabel = nil;
	self.rateAdjustCheckbox = nil;
	self.slowLabel = nil;
	self.fastLabel = nil;
	self.volumeAdjustCheckbox = nil;
	self.globalHotkeysBoxLabel = nil;
	self.pauseResumeLabel = nil;
	self.skipNoteLabel = nil;
	self.clickNoteLabel = nil;
	[super dealloc];
}

- (NSString *) mainNibName {
	return @"GrowlSpeechPrefs";
}

- (NSSet*)bindingKeys {
	static NSSet *keys = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		keys = [[NSSet setWithObjects:@"useLimit",
					@"characterLimit",
					@"useRate",
					@"rate",
					@"useVolume",
					@"volume", nil] retain];
	});
	return keys;
}

- (void) awakeFromNib {
	[self updateVoiceList];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSInteger pauseCode = [[defaults valueForKey:GrowlSpeechPauseKeyCodePref] integerValue];
	NSUInteger pauseModifiers = [[defaults valueForKey:GrowlSpeechPauseKeyModifierPref] unsignedIntegerValue];
	KeyCombo pauseCombo = {SRCarbonToCocoaFlags(pauseModifiers), pauseCode};
	[self.pauseShortcut setKeyCombo:pauseCombo];
	
	NSInteger skipCode = [[defaults valueForKey:GrowlSpeechSkipKeyCodePref] integerValue];
	NSUInteger skipModifiers = [[defaults valueForKey:GrowlSpeechSkipKeyModifierPref] unsignedIntegerValue];
	KeyCombo skipCombo = {SRCarbonToCocoaFlags(skipModifiers), skipCode};
	[self.skipShortcut setKeyCombo:skipCombo];
	
	NSInteger clickCode = [[defaults valueForKey:GrowlSpeechClickKeyCodePref] integerValue];
	NSUInteger clickModifiers = [[defaults valueForKey:GrowlSpeechClickKeyModifierPref] unsignedIntegerValue];
	KeyCombo clickCombo = {SRCarbonToCocoaFlags(clickModifiers), clickCode};
	[self.clickShortcut setKeyCombo:clickCombo];
}

-(void)updateVoiceList {
	NSMutableArray *voiceAttributes = [NSMutableArray array];
	
	NSMutableDictionary *defaultChoice = [NSMutableDictionary dictionary];
	[defaultChoice setObject:GrowlSpeechSystemVoice forKey:NSVoiceIdentifier];
	[defaultChoice setObject:NSLocalizedString(@"System Default", @"The voice chosen as the system voice in the Speech preference pane") forKey:NSVoiceName];
	[voiceAttributes addObject:defaultChoice];
	
	for (NSString *voiceIdentifier in [NSSpeechSynthesizer availableVoices]) {
		[voiceAttributes addObject:[NSSpeechSynthesizer attributesForVoice:voiceIdentifier]];
	}
	[self setVoices:voiceAttributes];
}

-(void)updateConfigurationValues {
	[self updateVoiceList];
	NSString *voice = [self.configuration valueForKey:GrowlSpeechVoicePref];
	NSArray *availableVoices = [voices valueForKey:NSVoiceIdentifier];
	NSUInteger row = NSNotFound;
	if (voice) {
		row = [availableVoices indexOfObject:voice];
	}
	
	if (row == NSNotFound)
		row = [availableVoices indexOfObject:[NSSpeechSynthesizer defaultVoice]];
	
	if ((row == NSNotFound) && ([availableVoices count]))
		row = 1;
	
	if (row != NSNotFound && [voices count] > 0) {
		[voiceList selectItemAtIndex:row];
	}
	[super updateConfigurationValues];
}

- (IBAction) previewVoice:(id)sender {
	NSInteger row = [sender indexOfSelectedItem];
	
	if (row != -1) {
		if(lastPreview != nil && [lastPreview isSpeaking]) {
			[lastPreview stopSpeaking];
		}
		NSString *voice = [[voices objectAtIndex:row] objectForKey:NSVoiceIdentifier];
		if([voice isEqualToString:GrowlSpeechSystemVoice])
            voice = nil;
        NSSpeechSynthesizer *quickVoice = [[NSSpeechSynthesizer alloc] initWithVoice:voice];
		[quickVoice startSpeakingString:[NSString stringWithFormat:NSLocalizedString(@"This is a preview of the %@ voice.", nil), [[voices objectAtIndex:row] objectForKey:NSVoiceName]]];
		lastPreview = quickVoice;
	}
}

- (IBAction) voiceClicked:(id)sender {
	NSInteger row = [sender indexOfSelectedItem];

	if (row != -1) {
		NSString *voice = [[voices objectAtIndex:row] objectForKey:NSVoiceIdentifier];
		[self setConfigurationValue:voice forKey:GrowlSpeechVoicePref];
		[self previewVoice:sender];
	}
}

#pragma mark -
#pragma mark Accessors

-(BOOL)useLimit {
	BOOL value = GrowlSpeechUseLimitDefault;
	if([self.configuration valueForKey:GrowlSpeechUseLimitPref]){
		value = [[self.configuration valueForKey:GrowlSpeechUseLimitPref] boolValue];
	}
	return value;
}
-(void)setUseLimit:(BOOL)value {
	[self setConfigurationValue:[NSNumber numberWithBool:value] forKey:GrowlSpeechUseLimitPref];
}

-(BOOL)useRate {
	BOOL value = GrowlSpeechUseRateDefault;
	if([self.configuration valueForKey:GrowlSpeechUseRatePref]){
		value = [[self.configuration valueForKey:GrowlSpeechUseRatePref] boolValue];
	}
	return value;
}
-(void)setUseRate:(BOOL)value {
	[self setConfigurationValue:[NSNumber numberWithBool:value] forKey:GrowlSpeechUseRatePref];
}

-(BOOL)useVolume {
	BOOL value = GrowlSpeechUseVolumeDefault;
	if([self.configuration valueForKey:GrowlSpeechUseVolumePref]){
		value = [[self.configuration valueForKey:GrowlSpeechUseVolumePref] boolValue];
	}
	return value;
}
-(void)setUseVolume:(BOOL)value {
	[self setConfigurationValue:[NSNumber numberWithBool:value] forKey:GrowlSpeechUseVolumePref];
}

-(NSUInteger)characterLimit {
	NSUInteger value = GrowlSpeechLimitDefault;
	if([self.configuration valueForKey:GrowlSpeechLimitPref]){
		value = [[self.configuration valueForKey:GrowlSpeechLimitPref] unsignedIntegerValue];
	}
	return value;
}
-(void)setCharacterLimit:(NSUInteger)value {
	[self setConfigurationValue:[NSNumber numberWithUnsignedInteger:value] forKey:GrowlSpeechLimitPref];
}

-(float)rate {
	float value = GrowlSpeechRateDefault;
	if([self.configuration valueForKey:GrowlSpeechRatePref]){
		value = [[self.configuration valueForKey:GrowlSpeechRatePref] floatValue];
	}
	return value;
}
-(void)setRate:(float)value {
	[self setConfigurationValue:[NSNumber numberWithFloat:value] forKey:GrowlSpeechRatePref];
}

-(NSUInteger)volume {
	NSUInteger value = GrowlSpeechVolumeDefault;
	if([self.configuration valueForKey:GrowlSpeechVolumePref]){
		value = [[self.configuration valueForKey:GrowlSpeechVolumePref] unsignedIntegerValue];
	}
	return value;
}
-(void)setVolume:(NSUInteger)value {
	[self setConfigurationValue:[NSNumber numberWithUnsignedInteger:value] forKey:GrowlSpeechVolumePref];
}

#pragma mark SRRecorderControl delegate

- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason
{
	return NO;
}

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo
{
	SGKeyCombo *combo = [SGKeyCombo keyComboWithKeyCode:newKeyCombo.code modifiers:SRCocoaToCarbonFlags(newKeyCombo.flags)];
	
	if(combo.keyCode == -1)
		combo = nil;
	
	SpeechHotKey type = SpeechPauseHotKey;
	NSString *codePref = GrowlSpeechPauseKeyCodePref;
	NSString *modifierPref = GrowlSpeechPauseKeyModifierPref;
	if(aRecorder == skipShortcut){
		type = SpeechSkipHotKey;
		codePref = GrowlSpeechSkipKeyCodePref;
		modifierPref = GrowlSpeechSkipKeyModifierPref;
	}
	if(aRecorder == clickShortcut){
		type = SpeechClickHotKey;
		codePref = GrowlSpeechClickKeyCodePref;
		modifierPref = GrowlSpeechClickKeyModifierPref;
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:combo.keyCode] 
															forKey:codePref];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithUnsignedInteger:combo.modifiers] 
															forKey:modifierPref];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:GrowlSpeechHotKeyChanged 
																		 object:self 
																	  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:type] 
																														forKey:@"hotKeyType"]];
}

@end
