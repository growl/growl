//
//  GNTPUtilities.h
//  Growl
//
//  Created by Daniel Siemer on 7/13/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GNTPPacket.h"

typedef BOOL(^GNTPHeaderBlock)(NSString *headerKey, NSString *headerValue);

@interface GNTPUtilities : NSObject

+ (NSData*)doubleCRLF;
+ (NSData*)gntpEndData;

+(NSString*)headerKeyFromHeader:(NSString*)header;
+(NSString*)headerValueFromHeader:(NSString*)header;
+(void)enumerateHeaders:(NSString*)headersString
				  withBlock:(GNTPHeaderBlock)headerBlock;

@end
