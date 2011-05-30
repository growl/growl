//
//  GHA-Stubs.h
//  Growl
//
//  Created by rudy on 8/2/09.
//  Copyright 2009 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlApplicationBridge.h"

@interface GrowlWindowTransition : NSAnimation {
}
@end

@interface GrowlFadingWindowTransition : GrowlWindowTransition {
}
@end

@interface GrowlSlidingWindowTransition : GrowlWindowTransition {
}
@end

@interface GrowlFlippingWindowTransition : GrowlWindowTransition {
}
@end

@interface GrowlShrinkingWindowTransition : GrowlWindowTransition {
}
@end

@interface GrowlScaleWindowTransition : GrowlWindowTransition {
}
@end

@interface GrowlWipeWindowTransition : GrowlWindowTransition {
}
@end

@interface GrowlApplicationController: GrowlAbstractSingletonObject <GrowlApplicationBridgeDelegate>{
}
@end
