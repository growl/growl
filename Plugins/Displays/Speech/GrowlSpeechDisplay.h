//
//  GrowlSpeechDisplay.h
//  Display Plugins
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GrowlDisplayPlugin.h"

@interface GrowlSpeechDisplay : GrowlDisplayPlugin {
    dispatch_queue_t speech_queue;
}

@end
