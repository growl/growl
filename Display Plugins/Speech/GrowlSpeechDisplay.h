//
//  GrowlSpeechDisplay.h
//  Display Plugins
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GrowlDisplayProtocol.h>

@class GrowlSpeechPrefs;

@interface GrowlSpeechDisplay : NSObject <GrowlDisplayPlugin>
{
	GrowlSpeechPrefs	*prefPane;
}

@end
