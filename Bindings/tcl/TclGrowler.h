#ifndef __TclGrowler_h__
#define __TclGrowler_h__

@interface TclGrowler : NSObject <GrowlApplicationBridgeDelegate> {
	NSString *appName;
	NSData   *appIcon;
	NSArray  *allNotifications;
}

- (id)initWithName:(NSString *)aName notifications:(NSArray *)notes icon:(NSImage *)aIcon;

@end

#endif /* __TclGrowler_h__ */
