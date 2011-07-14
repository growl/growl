//
//  GrowlMiniDispatch.h
//  SmokeLite
//
//  Created by Rachel Blackman on 7/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlDefines.h"

@protocol GrowlMiniDispatchDelegate
@optional
- (void)growlNotificationWasClicked:(id)context;
- (void)growlNotificationTimedOut:(id)context;
@end


@interface GrowlMiniDispatch : NSObject <NSAnimationDelegate> {

	NSMutableArray *windows;
	NSViewAnimation *repositionAnimation;
	
	id				delegate;
	
}

@property (nonatomic,assign) id delegate;

- (void)repositionAllWindows;

- (void)displayNotification:(NSDictionary *)notification;

@end
