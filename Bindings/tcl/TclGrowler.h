#ifndef __TclGrowler_h__
#define __TclGrowler_h__

#include <GrowlApplicationBridge.h>
#include <AppKit/NSImage.h>

@class GrowlApplicationBridge;

@interface TclGrowler : NSObject <GrowlApplicationBridgeDelegate> {
	NSString *_appName;
	NSData   *_appIcon;
	NSArray  *_allNotifications;
}

- (id)initWithName:(NSString *)appName notifications:(NSArray *)notes icon:(NSImage *)appIcon;

@end

#endif /* __TclGrowler_h__ */
