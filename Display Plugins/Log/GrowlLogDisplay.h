//
//  GrowlLogDisplay.h
//  Growl Display Plugins
//
//  Created by Nelson Elhage on 8/23/04.
//  Copyright 2004 Nelson Elhage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GrowlDisplayProtocol.h>
#import "GrowlDefines.h"

@class GrowlLogPrefs;

@interface GrowlLogDisplay : NSObject <GrowlDisplayPlugin> {
	GrowlLogPrefs *logPrefPane;
}

@end
