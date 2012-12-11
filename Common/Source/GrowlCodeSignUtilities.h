//
//  GrowlCodeSignUtilities.h
//  GrowlTunes
//
//  Created by Daniel Siemer on 12/11/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GrowlCodeSignUtilities : NSObject

+ (BOOL) isLionOrGreater;
+ (BOOL) hasEntitlement:(NSString*)entitlement;
+ (BOOL) hasSandboxEntitlement;
+ (BOOL) hasNetworkClientEntitlement;
+ (BOOL) hasNetworkServerEntitlement;
+ (BOOL) isSandboxed;

@end
