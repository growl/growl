//
//  GrowlMailFoundBundle.h
//  GrowlMailUUIDPatcher
//
//  Copyright 2010 The Growl Project. All rights reserved.
//

@interface GrowlMailFoundBundle : NSObject {
	NSURL *URL;
}

+ (id) foundBundleWithURL:(NSURL *)newURL;
- (id) initWithURL:(NSURL *)newURL;

@property(nonatomic, readonly) NSURL *URL;
@property(nonatomic, readonly, getter=isCompatibleWithCurrentMailAndMessageFramework) BOOL compatibleWithCurrentMailAndMessageFramework;
@property(nonatomic, readonly) NSSearchPathDomainMask domain;
@property(nonatomic, readonly) NSString *bundleVersion;

@end

@interface GrowlMailFoundBundle (HeyTheresViewMethodsInMyModelClass)

//Returns the Home, Computer, Finder, or Network icon image.
- (NSImage *) domainImage;
//Returns either the white-checkmark-on-green-circle or white-X-on-red-circle image.
- (NSImage *) compatibleImage;

@end
