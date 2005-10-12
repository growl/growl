/*

BSD License

Copyright (c) 2005, Keith Anderson
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

*	Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.
*	Redistributions in binary form must reproduce the above copyright notice,
	this list of conditions and the following disclaimer in the documentation
	and/or other materials provided with the distribution.
*	Neither the name of keeto.net or Keith Anderson nor the names of its
	contributors may be used to endorse or promote products derived
	from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


*/


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
