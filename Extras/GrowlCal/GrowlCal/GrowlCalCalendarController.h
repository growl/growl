//
//  GrowlCalCalendarController.h
//  GrowlCal
//
//  Created by Daniel Siemer on 12/20/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GrowlCalCalendarController : NSObject

@property (strong) NSMutableArray *calendars;

- (void)saveCalendars;

@end
