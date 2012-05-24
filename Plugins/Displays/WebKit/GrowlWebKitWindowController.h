//
//  GrowlWebKitWindowController.h
//  Growl
//
//  Created by Ingmar Stein on Thu Apr 14 2005.
//  Copyright 2005–2011 The Growl Project. All rights reserved.
//

#import <GrowlPlugins/GrowlDisplayWindowController.h>

@class WebView, GrowlNotification;

@interface GrowlWebKitWindowController : GrowlDisplayWindowController {
	NSString		*templateHTML;
	NSURL			*baseURL;

	BOOL			positioned;
	CGFloat			paddingX;
	CGFloat			paddingY;
	
	NSString		*cacheKey;
}

+ (NSData *)cachedImageForKey:(NSString*)key;
+ (void)setCachedImage:(NSData*)image forKey:(NSString*)key;
+ (void)removeCachedImageForKey:(NSString*)key;

@end
