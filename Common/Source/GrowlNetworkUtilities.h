//
//  GrowlNetworkUtilities.h
//  Growl
//
//  Created by Daniel Siemer on 11/11/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GrowlNetworkUtilities : NSObject

+(NSString*)localHostName;

//Should be called from a background queue or thread, blocking.
+(NSData *)addressDataForGrowlServerOfType:(NSString *)type withName:(NSString *)name withDomain:(NSString*)domain;

@end
