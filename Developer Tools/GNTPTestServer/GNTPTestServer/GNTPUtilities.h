//
//  GNTPUtilities.h
//  Growl
//
//  Created by Daniel Siemer on 7/13/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GNTPPacket.h"

@interface GNTPUtilities : NSObject

+ (NSData*)doubleCRLF;
+ (NSData*)gntpEndData;

@end
