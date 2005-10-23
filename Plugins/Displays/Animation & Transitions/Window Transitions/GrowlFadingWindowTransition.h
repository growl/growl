//
//  GrowlFadingWindowTransition.h
//  Growl
//
//  Created by Ofri Wolfus on 27/07/05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "GrowlWindowTransition.h"

typedef enum {
	GrowlNoFadeAction = -1,
	GrowlFadeIn = 0,
	GrowlFadeOut
} GrowlFadeAction;

@interface GrowlFadingWindowTransition : GrowlWindowTransition {
	GrowlFadeAction fadeAction;
}

- (id) initWithWindow:(NSWindow *)inWindow action:(GrowlFadeAction)action;
- (void) reset;

- (GrowlFadeAction) fadeAction;
- (void) setFadeAction: (GrowlFadeAction) theFadeAction;

@end
