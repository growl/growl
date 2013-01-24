//
//  GrowlSpeechDisplay.m
//  Display Plugins
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004–2011 The Growl Project. All rights reserved.
//

#import <GrowlPlugins/GrowlNotification.h>
#import "GrowlSpeechDisplay.h"
#import "GrowlSpeechPrefs.h"
#import "GrowlSpeechDefines.h"
#import "GrowlPathUtilities.h"
#import "GrowlDefinesInternal.h"
#import <ShortcutRecorder/ShortcutRecorder.h>
#import <GrowlPlugins/SGHotKey.h>
#import <GrowlPlugins/SGKeyCombo.h>
#import <GrowlPlugins/SGHotKeyCenter.h>

@implementation GrowlSpeechDisplay
@synthesize speech_queue;
@synthesize syn;
@synthesize paused;

- (id) init {
    if((self = [super init])) {
        self.speech_queue = [NSMutableArray array];
        self.syn = [[[NSSpeechSynthesizer alloc] initWithVoice:nil] autorelease];
        syn.delegate = self;
		 self.prefDomain = GrowlSpeechPrefDomain;
		 speech_dispatch_queue = dispatch_queue_create("com.growl.Speech.speech_dispatch_queue", 0);
		 self.paused = NO;
		 [self updateKeyCombo:SpeechPauseHotKey];
		 [self updateKeyCombo:SpeechSkipHotKey];
		 [self updateKeyCombo:SpeechClickHotKey];
    }
    return self;
}

- (void) dealloc {
	dispatch_release(speech_dispatch_queue);
	[speech_queue release];
	[syn release];
	[preferencePane release];
	[super dealloc];
}

-(void)updateKeyCombo:(SpeechHotKey)key {
	NSString *identifier = nil;
	NSString *codePref = nil;
	NSString *modifierPref = nil;
	SEL keySelector;
	switch (key) {
		case SpeechSkipHotKey:
			identifier = GrowlSpeechSkipKeyID;
			codePref = GrowlSpeechSkipKeyCodePref;
			modifierPref = GrowlSpeechSkipKeyModifierPref;
			keySelector = @selector(skipNote);
			break;
		case SpeechClickHotKey:
			identifier = GrowlSpeechClickKeyID;
			codePref = GrowlSpeechClickKeyCodePref;
			modifierPref = GrowlSpeechClickKeyModifierPref;
			keySelector = @selector(clickNote);
			break;
		case SpeechPauseHotKey:
		default:
			identifier = GrowlSpeechPauseKeyID;
			codePref = GrowlSpeechPauseKeyCodePref;
			modifierPref = GrowlSpeechPauseKeyModifierPref;
			keySelector = @selector(toggleSpeech);
			break;
	}
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSNumber *code = [defaults valueForKey:codePref];
	NSNumber *modifiers = [defaults valueForKey:modifierPref];
    SGKeyCombo *combo = nil;
    
	if(code && modifiers){
		combo = [SGKeyCombo keyComboWithKeyCode:[code integerValue] modifiers:[modifiers unsignedIntegerValue]];
    }
    
    if(combo && combo.keyCode) {
        SGHotKey *hotKey = [[[SGHotKey alloc] initWithIdentifier:identifier
                                                        keyCombo:combo
                                                          target:self
                                                          action:keySelector] autorelease];
        [[SGHotKeyCenter sharedCenter] registerHotKey:hotKey];
    }else{
        SGHotKey *hotKey = [[SGHotKeyCenter sharedCenter] hotKeyWithIdentifier:identifier];
        [[SGHotKeyCenter sharedCenter] unregisterHotKey:hotKey];
    }
}

- (GrowlPluginPreferencePane *) preferencePane {
	if (!preferencePane){
		preferencePane = [[GrowlSpeechPrefs alloc] initWithBundle:[NSBundle bundleForClass:[self class]]];
		__block GrowlSpeechDisplay *blockSelf = self;
		[[NSNotificationCenter defaultCenter] addObserverForName:GrowlSpeechHotKeyChanged
																		  object:preferencePane
																			queue:[NSOperationQueue mainQueue]
																	 usingBlock:^(NSNotification *note) {
																		 SpeechHotKey hotKey = (int)[[[note userInfo] valueForKey:@"hotKeyType"] integerValue];
																		 [blockSelf updateKeyCombo:hotKey];
																	 }];
	}
	return preferencePane;
}

- (void)dispatchNotification:(NSDictionary*)noteDict withConfiguration:(NSDictionary*)configuration {
	__block GrowlSpeechDisplay *blockSelf = self;
	//We are called on a background concurrent queue, but we want access to our queue serialized to one thread/serial queue
	dispatch_async(speech_dispatch_queue, ^{
		NSString *title = [noteDict valueForKey:GROWL_NOTIFICATION_TITLE];
		NSString *desc = [noteDict valueForKey:GROWL_NOTIFICATION_DESCRIPTION];
		
		NSString *summary = [NSString stringWithFormat:@"%@\n\n%@", title, desc];
		if([configuration valueForKey:GrowlSpeechUseLimitPref] && [[configuration valueForKey:GrowlSpeechUseLimitPref] boolValue]){
			NSUInteger limit = [configuration valueForKey:GrowlSpeechLimitPref] ? [[configuration valueForKey:GrowlSpeechLimitPref] unsignedIntegerValue] : GrowlSpeechLimitDefault;
			if([summary length] > limit){
				NSRange nearestWhite = [summary rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]
																				options:NSBackwardsSearch 
																				  range:NSMakeRange(0, limit)];
				if(nearestWhite.location != NSNotFound && nearestWhite.location != 0)
					limit = nearestWhite.location;
				summary = [summary substringToIndex:limit];
			}
		}
		
		NSDictionary *queueDict = [NSDictionary dictionaryWithObjectsAndKeys:summary, @"summary", noteDict, @"note", configuration, @"configuration", nil];
		
		[blockSelf.speech_queue addObject:queueDict];
		if(![blockSelf.syn isSpeaking] && !blockSelf.paused)
		{
			[blockSelf speakNotification:summary withConfiguration:configuration];
		}
	});
}

- (void)speakNotification:(NSString*)notificationToSpeak withConfiguration:(NSDictionary*)config
{
	NSString *voice = [config valueForKey:GrowlSpeechVoicePref];
	if([voice isEqualToString:GrowlSpeechSystemVoice])
		voice = nil;
	syn.voice = voice;
	
	if([config valueForKey:GrowlSpeechUseRatePref] && [[config valueForKey:GrowlSpeechUseRatePref] boolValue]){
		syn.rate = [config valueForKey:GrowlSpeechRatePref] ? [[config valueForKey:GrowlSpeechRatePref] floatValue] : GrowlSpeechRateDefault;
	}else {
		syn.rate = GrowlSpeechRateDefault;
	}
	
	if([config valueForKey:GrowlSpeechUseVolumePref] && [[config valueForKey:GrowlSpeechUseVolumePref] boolValue]){
		syn.volume = [config valueForKey:GrowlSpeechVolumePref] ? [[config valueForKey:GrowlSpeechVolumePref] floatValue] / 100.0f : 1.0f;
	}else{
		syn.volume = 1.0f;
	}
	
	[syn startSpeakingString:notificationToSpeak];
	
}

-(void)toggleSpeech {
	__block GrowlSpeechDisplay *blockSelf = self;
	dispatch_async(speech_dispatch_queue, ^{
		if([blockSelf.syn isSpeaking] || blockSelf.paused){
			blockSelf.paused = blockSelf.paused ? NO : YES;
			if(blockSelf.paused){
				[blockSelf.syn pauseSpeakingAtBoundary:NSSpeechWordBoundary];
			}else{
				[blockSelf.syn continueSpeaking];
			}
		}
	});
}

-(void)skipNote {
	__block GrowlSpeechDisplay *blockSelf = self;
	dispatch_async(speech_dispatch_queue, ^{
		blockSelf.paused = NO;
		[blockSelf.syn stopSpeaking];
	});
}

-(void)clickNote {
	__block GrowlSpeechDisplay *blockSelf = self;
	dispatch_async(speech_dispatch_queue, ^{
		if([blockSelf.speech_queue count]){
			NSDictionary *noteDict = [[blockSelf.speech_queue objectAtIndex:0U] valueForKey:@"note"];
			NSDictionary *configDict = [[blockSelf.speech_queue objectAtIndex:0U] valueForKey:@"configuration"];
			GrowlNotification *note = [GrowlNotification notificationWithDictionary:noteDict configurationDict:configDict];
			[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION_CLICKED
																				 object:note
																			  userInfo:nil];
		}
	});
}

#pragma mark -
#pragma mark NSSpeechSynthesizerDelegate
#pragma mark -

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)finishedSpeaking
{
	if([sender isEqualTo:syn])
	{
		if([speech_queue count]){
			[speech_queue removeObjectAtIndex:0U];
			if([speech_queue count])
			{
				//insert a slight delay
				__block GrowlSpeechDisplay *blockSelf = self;
				NSDictionary *speechDict = [speech_queue objectAtIndex:0U];
				double delayInSeconds = 1.0;
				dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
				dispatch_after(popTime, speech_dispatch_queue, ^(void){
					[blockSelf speakNotification:[speechDict valueForKey:@"summary"] withConfiguration:[speechDict valueForKey:@"configuration"]];
				});
			}
		}
	}
	else
		NSLog(@"something else");
}

@end
