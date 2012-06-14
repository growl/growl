//
//  NSURL+StringEncoding.h
//  Boxcar
//
//  Created by Daniel Siemer on 4/10/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (StringEncoding)

+(NSString*)encodedStringByAddingPercentEscapesToString:(NSString*)string;

@end
