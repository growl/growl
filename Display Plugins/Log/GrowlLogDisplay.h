//
//  GrowlLogDisplay.h
//  Growl Display Plugins
//
//  Created by Nelson Elhage on 8/23/04.
//  Copyright 2004 Nelson Elhage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GrowlDisplayProtocol.h>

@class NSPreferencePane;

@interface GrowlLogDisplay : NSObject <GrowlDisplayPlugin> {
	NSPreferencePane *preferencePane;
}

@end
