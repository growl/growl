//
//  GrowlWebKitWindowView.h
//  Growl
//
//  Created by Nelson Elhage on Wed Jun 09 2004.
//  Name changed from KABubbleWindowView.h by Justin Burns on Fri Nov 05 2004.
//  Copyright (c) 2004 Nelson Elhage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface GrowlWebKitWindowView : WebView {
	BOOL				mouseOver;
	BOOL				closeOnMouseExit;
	SEL					action;
	id					target;
	NSTrackingRectTag	trackingRectTag;
}

- (void) sizeToFit;

- (id) target;
- (void) setTarget:(id)object;

- (SEL) action;
- (void) setAction:(SEL)selector;

- (BOOL) mouseOver;
- (void) setCloseOnMouseExit:(BOOL)flag;
@end

