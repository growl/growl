//
//  GrowlFadingWindowTransition.h
//  Growl
//
//  Created by Ofri Wolfus on 27/07/05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "GrowlWindowTransition.h"

// Warning: Don't try to use more then one fade transition at once!

typedef enum {
	GrowlNoFadeAction = -1,
	GrowlFadeIn = 0,
	GrowlFadeOut
} GrowlFadeAction;

@interface GrowlFadingWindowTransition : GrowlWindowTransition {
	GrowlFadeAction fadeAction;
	GrowlFadeAction defaultAction;
}

- (id) initWithWindow:(NSWindow *)inWindow defaultAction:(GrowlFadeAction)action;

- (void) startFadeIn;
- (void) startFadeOut;
- (void) reset;

- (GrowlFadeAction) defaultAction;
- (void) setDefaultAction:(GrowlFadeAction)action;

@end

//Delegate Methods
@interface NSObject (GrowlFadingWindowTransitionDelegate)
- (void) fadeInWindowTransitionWillStart:(GrowlFadingWindowTransition *)fadingWindowTransition;
- (void) fadeInWindowTransitionDidEnd:(GrowlFadingWindowTransition *)fadingWindowTransition;

- (void) fadeOutWindowTransitionWillStart:(GrowlFadingWindowTransition *)fadingWindowTransition;
- (void) fadeOutWindowTransitionDidEnd:(GrowlFadingWindowTransition *)fadingWindowTransition;
@end

//Notifications
#define GrowlFadeInWindowTransitionWillStart	@"GrowlFadeInWindowTransitionWillStart"
#define GrowlFadeInWindowTransitionDidEnd		@"GrowlFadeInWindowTransitionDidEnd"
#define GrowlFadeOutWindowTransitionWillStart	@"GrowlFadeOutWindowTransitionWillStart"
#define GrowlFadeOutWindowTransitionDidEnd		@"GrowlFadeOutWindowTransitionDidEnd"
