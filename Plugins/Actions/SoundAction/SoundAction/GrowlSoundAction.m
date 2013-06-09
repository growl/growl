//
//  GrowlSoundAction.m
//  SoundAction
//
//  Created by Daniel Siemer on 3/15/12.
//  Copyright 2012 The Growl Project, LLC. All rights reserved.
//

#import "GrowlSoundAction.h"
#import "GrowlSoundActionDefines.h"
#import "GrowlSoundActionPreferencePane.h"

#include <CoreAudio/AudioHardware.h>

@implementation GrowlSoundAction

@synthesize audioDeviceId;
@synthesize currentSound;
@synthesize queuedSounds;

- (id)init
{
	if ((self = [super init])) {
		self.audioDeviceId = nil;
		sound_queue = dispatch_queue_create("com.growl.soundaction.sounddispatchqueue", DISPATCH_QUEUE_SERIAL);
		self.queuedSounds = [NSMutableArray array];
	}
	return self;
}

-(void)dealloc {
	dispatch_release(sound_queue);
	[queuedSounds release];
	[audioDeviceId release];
	[super dealloc];
}

+ (NSString*)getAudioDevice
{
	NSString *result = nil;
	AudioObjectPropertyAddress propertyAddress = {kAudioHardwarePropertyDefaultSystemOutputDevice, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMaster};
	UInt32 propertySize;
	
	if(AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &propertySize) == noErr)
	{
		AudioObjectID deviceID;
		if(AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &propertySize, &deviceID) == noErr)
		{
			NSString *UID = nil;
			propertySize = sizeof(UID);
			propertyAddress.mSelector = kAudioDevicePropertyDeviceUID;
			propertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
			propertyAddress.mElement = kAudioObjectPropertyElementMaster;
			if (AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, NULL, &propertySize, &UID) == noErr)
			{
				result = [NSString stringWithString:UID];
				CFRelease(UID);
			}
		}
	}
	return result;    
}

-(void)dispatchNotification:(NSDictionary *)notification withConfiguration:(NSDictionary *)configuration {
	NSString *name = [configuration valueForKey:SelectedSoundPref];
	if(name && [name caseInsensitiveCompare:GrowlSystemDefaultSound] != NSOrderedSame){
		NSSound *soundToPlay = [NSSound soundNamed:name];
		if(!soundToPlay){
			NSLog(@"No sound named %@", name);
			return;
		}
		if(!audioDeviceId)
			self.audioDeviceId = [GrowlSoundAction getAudioDevice];
		[soundToPlay setPlaybackDeviceIdentifier:audioDeviceId];
		[soundToPlay setDelegate:self];
		
		NSUInteger volume = SoundVolumeDefault;
		if([configuration valueForKey:SoundVolumePref])
			volume = [[configuration valueForKey:SoundVolumePref] unsignedIntegerValue];
		
		[soundToPlay setVolume:((CGFloat)volume / 100.0f)];
		
		__block GrowlSoundAction *blockSelf = self;
		dispatch_async(sound_queue, ^{
			if(!blockSelf.currentSound){
				blockSelf.currentSound = soundToPlay;
				[soundToPlay play];
			}else {
				[blockSelf.queuedSounds addObject:soundToPlay];
			}
		});
	}else{
		NSBeep();
	}
}

- (GrowlPluginPreferencePane *) preferencePane {
	if (!preferencePane)
		preferencePane = [[GrowlSoundActionPreferencePane alloc] initWithBundle:[NSBundle bundleForClass:[self class]]];
	
	return preferencePane;
}

-(void)sound:(NSSound *)sound didFinishPlaying:(BOOL)aBool {
	__block GrowlSoundAction *blockSelf = self;
	dispatch_async(sound_queue, ^{
		blockSelf.currentSound = nil;
		if([blockSelf.queuedSounds count] > 0){
			NSSound *newSound = [blockSelf.queuedSounds objectAtIndex:0U];
			blockSelf.currentSound = newSound;
			[blockSelf.queuedSounds removeObjectAtIndex:0U];
			[newSound play];
		}
	});
}

@end
