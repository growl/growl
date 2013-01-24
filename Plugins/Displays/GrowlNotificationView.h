//
//  GrowlNotificationView.h
//  Growl
//
//  Created by Jamie Kirkpatrick on 27/11/05.
//  Copyright 2005-2006  Jamie Kirkpatrick. All rights reserved.
//

@interface GrowlNotificationView : NSView {
	BOOL				initialDisplayTest;
	BOOL				mouseOver;
	BOOL				closeOnMouseExit;
	NSPoint				closeBoxOrigin;
	SEL					action;
	id					target;
	NSTrackingRectTag	trackingRectTag;
}

@property (assign) id target;
@property (assign) SEL action;

- (BOOL) mouseOver;
- (void) setCloseOnMouseExit:(BOOL)flag;

+ (NSButton *) closeButton;  //Default
+ (NSButton *) closeButtonForKey:(NSString*)key;
+ (void)makeButtonWithImage:(NSImage*)image pressedImage:(NSImage*)pressed forKey:(NSString*)key;
+ (void)setButton:(NSButton*)button forKey:(NSString*)key;
- (BOOL) showsCloseBox;
- (void) setCloseBoxVisible:(BOOL)yorn;
- (void) setCloseBoxOrigin:(NSPoint)inOrigin;
- (void) clickedCloseBox:(id)sender;

- (void) setPriority:(int)priority;
- (void) setTitle:(NSString *) aTitle;
- (void) setText:(NSString *)aText;
- (void) setIcon:(NSImage *)anIcon;
- (void) sizeToFit;

- (NSDictionary *) configurationDict;
- (NSString*)buttonKey;

@end
