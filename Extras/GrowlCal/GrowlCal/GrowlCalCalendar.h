//
//  GrowlCalCalendar.h
//  GrowlCal
//
//  Created by Daniel Siemer on 12/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CalCalendar;

@interface GrowlCalCalendar : NSObject

@property (strong) CalCalendar *calendar;
@property (strong) NSString *uid;
@property (nonatomic) BOOL use;

-(id)initWithUID:(NSString*)uid;
-(id)initWithDictionary:(NSDictionary*)dict;

@end
