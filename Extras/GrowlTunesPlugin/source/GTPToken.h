//
//  GTPToken.h
//  GrowlTunes
//
//  Created by rudy on 9/16/07.
//  Copyright 2007 2007 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GTPToken : NSObject 
{
	NSString *displayText;
}

- (void)encodeWithCoder:(NSCoder *)encoder;
- (id)initWithCoder:(NSCoder *)decoder;
- (NSString *)code;

@property (retain) NSString *text;
@end
