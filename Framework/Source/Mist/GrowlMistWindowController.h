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
@end


@interface GrowlMistWindowController : NSWindowController <NSAnimationDelegate> {

	GrowlMistView				*mistView;
	
	NSTimer						*lifetime;
	BOOL						 closed;
	BOOL						 sticky;
	BOOL						 visible;
	BOOL						 selected;
	
	id							 delegate;
	
	id							 userInfo;
	
}

@property (nonatomic,readonly) BOOL sticky;
@property (nonatomic,readonly) BOOL visible;
@property (nonatomic,readonly) BOOL selected;
@property (nonatomic,readonly) id userInfo;
@property (nonatomic,assign) id delegate;

- (id)initWithNotificationTitle:(NSString *)title text:(NSString *)text image:(NSImage *)image sticky:(BOOL)isSticky userInfo:(id)info delegate:(id)delegate;

- (void)fadeIn;
- (void)fadeOut;

@end
