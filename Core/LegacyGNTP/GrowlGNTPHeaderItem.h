//
//  GrowlGNTPHeaderItem.h
//  Growl
//
//  Created by Evan Schoenberg on 10/2/08.
//  Copyright 2008-2009 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlTCPPathway.h"

@interface GrowlGNTPHeaderItem : NSObject <GNTPOutgoingItem> {
	NSString *headerName;
	NSString *headerValue;
}

/*!
 * @brief Create a GrowlGNTPHeaderItem from data
 *
 * @param inData The network data, which should represent a single CRLF terminated line in UTF8 encoding
 * @param outError If non-NULL, will contain an error on return if and only if this method returns nil
 */
+ (GrowlGNTPHeaderItem *)headerItemFromData:(NSData *)inData error:(NSError **)outError;

/*!
 * @brief Create a GrowlGNTPHeaderItem from name/value
 */
+ (GrowlGNTPHeaderItem *)headerItemWithName:(NSString *)name value:(NSString *)value;


/*!
 * @brief A singleton used to indicate a separator header item
 *
 * A separator header item contained a single CRLF and no other data.
 * This return value can be checked against other GrowlGNTPHeaderItem objects with simple pointer equality.
 */
+ (GrowlGNTPHeaderItem *)separatorHeaderItem;

- (NSString *)headerName;
- (NSString *)headerValue;

@end
