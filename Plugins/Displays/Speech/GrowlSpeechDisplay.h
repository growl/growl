//
//  GrowlSpeechDisplay.h
//  Display Plugins
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004–2011 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GrowlPlugins/GrowlActionPlugin.h>

@interface GrowlSpeechDisplay : GrowlActionPlugin <GrowlDispatchNotificationProtocol, NSSpeechSynthesizerDelegate> {
    NSMutableArray *speech_queue;
    NSSpeechSynthesizer *syn;
}

@property (retain) NSMutableArray *speech_queue;
@property (retain) NSSpeechSynthesizer *syn;

- (void)speakNotification:(NSString*)notificationToSpeak withVoice:(NSString*)voice;

@end
