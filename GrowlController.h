//
//  GrowlController.h
//  Growl
//
//  Created by Karl Adam on Thu Apr 22 2004.
//

#import <Foundation/Foundation.h>

@protocol GrowlDisplayPlugin 
- (void)  displayNotificationWithinfo:(NSDictionary *) noteDict;
@end

@interface GrowlController : NSObject {
	NSMutableArray				*_tickets;		//Application tickets
	id <GrowlDisplayPlugin>		*_displayController;
}

- (void) dispatchNotification:(NSNotification *) note;
@end
