//
//  NSDate+KNExtras.h
//  Feed
//
//  Created by Keith on 3/8/05.
//  Copyright 2005 Keith Anderson. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSDate (KNExtras)

-(NSString *)naturalString;
-(NSString *)naturalStringWithDateFormat:(NSString *)dateFormat;
-(NSString *)naturalStringWithDateFormat:(NSString *)dateFormat timeFormat:(NSString *)timeFormat;

-(NSString *)naturalStringForWidth:(float)maxWidth withAttributes:(NSDictionary *)atts;

-(NSString *)dateStringWithFormat:(NSString *)dateFormat;
-(NSString *)timeStringWithFormat:(NSString *)timeFormat;
-(float)widthOfTimeWithFormat:(NSString *)timeFormat attributes:(NSDictionary *)atts;
-(float)widthOfDateWithFormat:(NSString *)dateFormat attributes:(NSDictionary *)atts;
@end
