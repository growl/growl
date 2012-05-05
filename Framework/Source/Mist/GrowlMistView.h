//
//  GrowlMistView.h
//  Basic notification view, loosely inspired by Smoke.  This 
//  view has a bare minimum of functionality, in order to work
//  as a default notification style embedded in the framework
//  while not having a lot of dependencies in the greater
//  Growl project.
//
//  Created by Rachel Blackman on 7/11/11.
//
//

#import <Cocoa/Cocoa.h>

// Width of any Mist notification
#define MIST_WIDTH 320

// We size the image to this, if given one
#define MIST_IMAGE_DIM 42

// Font size for the title and text content
#define MIST_TITLE_SIZE 14
#define MIST_TEXT_SIZE 12

// Paddings and layouts
#define MIST_TEXT_PADDING 6
#define MIST_TEXT_LINESPACE 0
#define MIST_PADDING 6

// Number of seconds that Mist views should live.
// (This isn't actually used by GrowlMistView anywhere,
// but it seemed to belong in this header file with
// the other constants.)
#define MIST_LIFETIME 5

@protocol GrowlMistViewDelegate
@optional
- (void)mistViewDismissed:(BOOL)closed;
- (void)mistViewSelected:(BOOL)selected;
- (void)closeAllNotifications;
@end


@interface GrowlMistView : NSView {

    NSImage             *notificationImage;
	
	NSDictionary		*notificationTitleAttrs;
	NSFont				*notificationTitleFont;
    NSString            *notificationTitle;
	
	NSDictionary		*notificationTextAttrs;
	NSFont				*notificationTextFont;
    NSString            *notificationText;
	
	NSBezierPath		*clipPath;
	NSBezierPath		*strokePath;
	
	NSTrackingArea		*trackingArea;

	BOOL				 selected;
	
    id                   delegate;

}

@property (nonatomic,retain) NSString *notificationTitle;
@property (nonatomic,retain) NSString *notificationText;
@property (nonatomic,retain) NSImage *notificationImage;

@property (nonatomic,assign) id delegate;

- (void)sizeToFit;

@end
