//
//  GrowlRipplingWindowTransition.h
//  Growl
//
//  Created by rudy on 1/14/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlWindowTransition.h"
#import "AWRippler.h"

@interface GrowlRipplingWindowTransition : GrowlWindowTransition {
	AWRippler *rippler;
	NSWindow *win;
}

@end
