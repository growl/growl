//
//  GrowlController.h
//  Growl
//
//  Created by Karl Adam on Thu Apr 22 2004.
//

#import <Foundation/Foundation.h>
#import "GrowlDefines.h" //this should not be needed

@interface GrowlController : NSObject {
	NSMutableDictionary			*_tickets;				//Application tickets
	id <GrowlDisplayPlugin>		*_displayController;
}

- (void) dispatchNotification:(NSNotification *) note;
@end
