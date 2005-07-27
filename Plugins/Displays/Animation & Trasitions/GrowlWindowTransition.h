//
//  GrowlWindowTransition.h
//  Growl
//
//  Created by Ofri Wolfus on 27/07/05.
//  Copyright 2005 Ofri Wolfus. All rights reserved.
//

#import "GrowlAnimation.h"


@interface GrowlWindowTransition : GrowlAnimation {
	NSWindow *window;
}

- (id)initWithWindow:(NSWindow *)inWindow;

- (NSWindow *) window;
- (void) setWindow:(NSWindow *)inWindow;

@end
