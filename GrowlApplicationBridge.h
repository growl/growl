//
//  GrowlApplicationBridge.h
//  Growl
//
//  Created by Evan Schoenberg on Wed Jun 16 2004.
//

#import <Foundation/Foundation.h>

#define GROWL_PREFPANE_BUNDLE_IDENTIFIER	@"com.growl.prefpanel"

@interface GrowlApplicationBridge : NSObject {

}

/*
 + (BOOL)launchGrowlIfInstalledNotifyingTarget:(id)target selector:(SEL)selector context:(void *)context
 Returns YES (TRUE) if the Growl helper app began launching.
 Returns NO (FALSE) and performs no other action if the Growl prefPane is not properly installed.
 GrowlApplicationBridge will send "selector" to "target" when Growl is ready for use (this will only occur when it also returns YES).
	Note: selector should take a single argument; this is to allow applications to have context-relevent information passed back. It is perfectly
	acceptable for context to be NULL.
 */
+ (BOOL)launchGrowlIfInstalledNotifyingTarget:(id)target selector:(SEL)selector context:(void *)context;

@end
