/*
 *  GrowlSpeechDefines.h
 *  Display Plugins
 *
 *  Created by Ingmar Stein on 15.11.04.
 *  Copyright 2004–2011 The Growl Project. All rights reserved.
 *
 */

#define GrowlSpeechPrefDomain	@"com.growl.Speech"
#define GrowlSpeechSystemVoice  @"com.Growl.Speech.system"
#define GrowlSpeechVoicePref	@"Speech - Voice"

#define GrowlSpeechHotKeyChanged @"com.growl.speech.hotKeyChangednotification"
#define GrowlSpeechPauseKeyCodePref	@"com.growl.Speech.pauseKeyCode"
#define GrowlSpeechPauseKeyModifierPref @"com.growl.Speech.pauseKeyModifier"
#define GrowlSpeechPauseKeyID @"com.growl.Speech.pauseHotKey"

#define GrowlSpeechSkipKeyCodePref	@"com.growl.Speech.skipKeyCode"
#define GrowlSpeechSkipKeyModifierPref @"com.growl.Speech.skipKeyModifier"
#define GrowlSpeechSkipKeyID @"com.growl.Speech.skipHotKey"

#define GrowlSpeechClickKeyCodePref	@"com.growl.Speech.clickKeyCode"
#define GrowlSpeechClickKeyModifierPref @"com.growl.Speech.clickKeyModifier"
#define GrowlSpeechClickKeyID @"com.growl.Speech.clickHotKey"

#define GrowlSpeechUseLimitPref	@"Speech - UseLimit"
#define GrowlSpeechLimitPref		@"Speech - Limit"
#define GrowlSpeechUseRatePref	@"Speech - UseRate"
#define GrowlSpeechRatePref		@"Speech - Rate"
#define GrowlSpeechUseVolumePref @"Speech - UseVolume"
#define GrowlSpeechVolumePref		@"Speech - Volume"

#define GrowlSpeechUseLimitDefault NO
#define GrowlSpeechLimitDefault 2000
#define GrowlSpeechUseRateDefault NO
#define GrowlSpeechRateDefault 180
#define GrowlSpeechUseVolumeDefault NO
#define GrowlSpeechVolumeDefault 100

typedef enum {
	SpeechPauseHotKey,
	SpeechSkipHotKey,
	SpeechClickHotKey
} SpeechHotKey;

