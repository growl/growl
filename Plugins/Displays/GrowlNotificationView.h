//
//  GrowlNotificationView.h
//  Growl
//
//  Created by Jamie Kirkpatrick on 27/11/05.
//  Copyright 2005-2006  Jamie Kirkpatrick. All rights reserved.
//

#import "GrowlThreadedView.h"

@interface GrowlNotificationView : GrowlThreadedView {
	BOOL				mouseOver;
	BOOL				closeOnMouseExit;
	SEL					action;
	id					target;
	id                  delegate;
	NSTrackingRectTag	trackingRectTag;
}

- (id) delegate;
- (void) setDelegate: (id) theDelegate;

- (id) target;
- (void) setTarget:(id)object;

- (SEL) action;
- (void) setAction:(SEL)selector;

- (BOOL) mouseOver;
- (void) setCloseOnMouseExit:(BOOL)flag;

@end

@interface NSObject (GrowlNotificationViewDelegate)
- (void) mouseExitedNotificationView:(GrowlNotificationView *)view;
@end
