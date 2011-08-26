//
//  NSStringAdditions.h
//  Growl
//
//  Created by Ingmar Stein on 16.05.05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <Cocoa/Cocoa.h>

@interface NSString (GrowlAdditions)

- (unsigned long) unsignedLongValue;
- (unsigned) unsignedIntValue;

- (BOOL) isSubpathOf:(NSString *)superpath;

- (BOOL) Growl_isLikelyDomainName;
- (BOOL) Growl_isLikelyIPAddress;
- (BOOL) isLocalHost;

+(NSString*)stringWithAddressData:(NSData*)aAddressData;
+(NSString*)hostNameForAddressData:(NSData *)aAddressData;

- (NSString*)stringByEscapingForHTML;

@end
