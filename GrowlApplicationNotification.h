//
//  GrowlApplicationNotification.h
//  Growl
//
//  Created by Karl Adam on 10/29/04.
//  Copyright 2004 matrixPointer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef enum GrowlPriority {
	GP_verylow		= -2,
	GP_low			= -1,
	GP_normal		=  0,
	GP_high         =  1,
	GP_emergency	=  2
} GrowlPriority;

@interface GrowlApplicationNotification : NSObject {
	NSString		*_name;
	GrowlPriority	 _priority;
	BOOL			 _enabled;
    int				 _sticky;
}

+ (GrowlApplicationNotification *) notificationWithName:(NSString*)name;
+ (GrowlApplicationNotification *) notificationFromDict:(NSDictionary*)dict;
- (GrowlApplicationNotification *) initWithName:(NSString*)name priority:(GrowlPriority)priority enabled:(BOOL)enabled sticky:(int)sticky;
- (NSDictionary*) notificationAsDict;

#pragma mark -

- (NSString*) name;

- (GrowlPriority) priority;
- (void) setPriority:(GrowlPriority)newPriority;

- (BOOL) enabled;
- (void) setEnabled:(BOOL)yorn;
- (void) enable;
- (void) disable;

- (int) sticky;
- (void) setSticky:(int)sticky;
@end
