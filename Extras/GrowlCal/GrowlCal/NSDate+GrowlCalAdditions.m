//
//  NSDate+GrowlCalAdditions.m
//  GrowlCal
//
//  Created by Daniel Siemer on 1/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSDate+GrowlCalAdditions.h"

@implementation NSDate (GrowlCalAdditions)

-(NSDate*)dayOfDate
{
   NSCalendarDate *calendarDate = [NSCalendarDate dateWithTimeInterval:0 sinceDate:self];
   NSCalendarDate *dayOfDate = [NSCalendarDate dateWithYear:[calendarDate yearOfCommonEra]
                                                      month:[calendarDate monthOfYear]
                                                        day:[calendarDate dayOfMonth]
                                                       hour:0
                                                     minute:0
                                                     second:0
                                                   timeZone:[calendarDate timeZone]];
   return dayOfDate;
}

@end
