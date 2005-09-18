//
//  NSDate+KNExtras.m
//  Feed
//
//  Created by Keith on 3/8/05.
//  Copyright 2005 Keith Anderson. All rights reserved.
//

#import "NSDate+KNExtras.h"


@implementation NSDate (KNExtras)

-(NSString *)naturalString{
	return [self naturalStringWithDateFormat: [[NSUserDefaults standardUserDefaults] stringForKey: NSDateFormatString]];
}

-(NSString *)naturalStringWithDateFormat:(NSString *)dateFormat{
	return [self naturalStringWithDateFormat: dateFormat timeFormat: [[NSUserDefaults standardUserDefaults] stringForKey: NSTimeFormatString]];
}

-(NSString *)naturalStringWithDateFormat:(NSString *)dateFormat timeFormat:(NSString *)timeFormat{
#pragma unused(timeFormat)
	NSString *			dateAndTime = nil;
	NSString *			now = [[NSDate date] descriptionWithCalendarFormat: @"%m/%d/%Y" timeZone: nil locale: nil];
	NSString *			yesterday = [[[NSDate date] addTimeInterval: -24*60*60] descriptionWithCalendarFormat: @"%m/%d/%Y" timeZone: nil locale: nil];
	NSString *			dateString = [self descriptionWithCalendarFormat: @"%m/%d/%Y" timeZone: nil locale: nil];
	
	if( [dateString isEqualToString:now] ){
		dateAndTime = [[[[NSUserDefaults standardUserDefaults] stringArrayForKey:NSThisDayDesignations] objectAtIndex:0] capitalizedString];
		dateAndTime = [dateAndTime stringByAppendingFormat:@" %@", [self descriptionWithCalendarFormat: [[NSUserDefaults standardUserDefaults] stringForKey: @"NSTimeFormatString"] timeZone: nil locale: nil]];
	}else if( [dateString isEqualToString:yesterday] ){
		dateAndTime = [[[[NSUserDefaults standardUserDefaults] stringArrayForKey:NSPriorDayDesignations] objectAtIndex:0] capitalizedString];
		dateAndTime = [dateAndTime stringByAppendingFormat:@" %@", [self descriptionWithCalendarFormat: [[NSUserDefaults standardUserDefaults] stringForKey: @"NSTimeFormatString"] timeZone: nil locale: nil]];
	}else{
		dateAndTime = [self descriptionWithCalendarFormat: dateFormat timeZone: nil locale: nil];
	}
	return dateAndTime;
}

-(NSString *)naturalStringForWidth:(float)maxWidth withAttributes:(NSDictionary *)atts{
	NSUserDefaults *			defaults = [NSUserDefaults standardUserDefaults];
	NSString *					timeFormat = [defaults stringForKey: @"NSTimeFormatString"];
	NSString *					shortDateFormat = [defaults stringForKey: @"NSShortDateFormatString"];
	float						timeWidth = [self widthOfTimeWithFormat: timeFormat attributes: atts];
	
	if( ([self widthOfDateWithFormat: @"%B %e, %Y" attributes: atts] + timeWidth) <= maxWidth ){
		return [NSString stringWithFormat: @"%@ %@", [self dateStringWithFormat: @"%B %e, %Y"], [self timeStringWithFormat: timeFormat]];
	}
	if( ([self widthOfDateWithFormat: @"%b %e, %Y" attributes: atts] + timeWidth) <= maxWidth ){
		return [NSString stringWithFormat: @"%@ %@", [self dateStringWithFormat: @"%b %e, %Y"], [self timeStringWithFormat: timeFormat]];
	}
	if( ([self widthOfDateWithFormat: shortDateFormat attributes: atts] + timeWidth) <= maxWidth ){
		return [NSString stringWithFormat: @"%@ %@", [self dateStringWithFormat: shortDateFormat], [self timeStringWithFormat: timeFormat]];
	}
	
	return [NSString stringWithString: [self dateStringWithFormat: shortDateFormat]];
}

-(NSString *)dateStringWithFormat:(NSString *)dateFormat{
	NSString *			resultString = nil;
	NSString *			now = [[NSDate date] descriptionWithCalendarFormat: @"%m/%d/%y" timeZone: nil locale: nil];
	NSString *			yesterday = [[[NSDate date] addTimeInterval: -24*60*60] descriptionWithCalendarFormat: @"%m/%d/%y" timeZone: nil locale: nil];
	NSString *			dateString = [self descriptionWithCalendarFormat: @"%m/%d/%Y" timeZone: nil locale: nil];
	
	if( [dateString isEqualToString: now] ){
		resultString = [[[[NSUserDefaults standardUserDefaults] stringArrayForKey:NSThisDayDesignations] objectAtIndex:0] capitalizedString];
	}else if( [dateString isEqualToString: yesterday] ){
		resultString = [[[[NSUserDefaults standardUserDefaults] stringArrayForKey:NSPriorDayDesignations] objectAtIndex:0] capitalizedString];
	}else{
		resultString = [self descriptionWithCalendarFormat: dateFormat timeZone: nil locale: nil];
	}
	return resultString;
}

-(NSString *)timeStringWithFormat:(NSString *)timeFormat{
	return [self descriptionWithCalendarFormat: timeFormat timeZone: nil locale: nil];
}

-(float)widthOfDateWithFormat:(NSString *)dateFormat attributes:(NSDictionary *)atts{
	NSString *			resultString = [self dateStringWithFormat: dateFormat];
	return [resultString sizeWithAttributes: atts].width;
}

-(float)widthOfTimeWithFormat:(NSString *)timeFormat attributes:(NSDictionary *)atts{
	NSString *			resultString = [self timeStringWithFormat: timeFormat];
	return [resultString sizeWithAttributes: atts].width;
}

@end
