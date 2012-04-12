//
//  GrowlMiniDispatch.h
//
//  Created by Rachel Blackman on 7/13/11.
//

#import <Cocoa/Cocoa.h>
#import "GrowlDefines.h"

@protocol GrowlMiniDispatchDelegate
@optional
- (void)growlNotificationWasClicked:(id)context;
- (void)growlNotificationTimedOut:(id)context;
@end

@class GrowlPositionController;

@interface GrowlMiniDispatch : NSObject <NSAnimationDelegate> {
	GrowlPositionController *positionController;
	NSMutableSet *windows;
	NSMutableArray *queuedWindows;
	
	id				delegate;
	
}

@property (nonatomic,assign) id delegate;
@property (nonatomic,retain) GrowlPositionController *positionController;

- (void)displayNotification:(NSDictionary *)notification;

@end
