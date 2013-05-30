//
//  GrowlMistWindowController.h
//
//  Created by Rachel Blackman on 7/13/11.
//

#import <Cocoa/Cocoa.h>

#import "GrowlMistView.h"

@class GrowlMistWindowController;

@protocol GrowlMistWindowControllerDelegate
@optional
- (void)mistNotificationDismissed:(GrowlMistWindowController *)window;
- (void)mistNotificationClicked:(GrowlMistWindowController *)window;
- (void)closeAllNotifications:(GrowlMistWindowController *)window;
@end


@interface GrowlMistWindowController : NSWindowController <NSAnimationDelegate> {
	GrowlMistView				*mistView;
	NSViewAnimation 			*fadeAnimation;
	NSTimer						*lifetime;
   NSString                *uuid;
	BOOL						 closed;
	BOOL						 sticky;
	BOOL						 visible;
	BOOL						 selected;
	id							 delegate;
}

@property (nonatomic,readwrite,retain) NSViewAnimation *fadeAnimation;
@property (nonatomic,readwrite,retain) NSTimer *lifetime;
@property (nonatomic,readonly) BOOL sticky;
@property (nonatomic,readonly) BOOL visible;
@property (nonatomic,readonly) BOOL selected;
@property (nonatomic,readonly) NSString *uuid;
@property (nonatomic,assign) id delegate;

- (id)initWithNotificationTitle:(NSString *)title
                           text:(NSString *)text
                          image:(NSImage *)image
                         sticky:(BOOL)isSticky
                           uuid:(NSString*)uuid
                       delegate:(id)delegate;

- (void)fadeIn;
- (void)fadeOut;

@end
