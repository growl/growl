#import <AppKit/NSView.h>

#define KALimitPref @"Limit Bubbles"

@interface KABubbleWindowView : NSView {
	NSImage				*_icon;
	NSString			*_title;
	NSAttributedString  *_text;
	float				_textHeight;
	SEL					_action;
	id					_target;
}

- (void) setIcon:(NSImage *) icon;
- (void) setTitle:(NSString *) title;
- (void) setAttributedText:(NSAttributedString *) text;
- (void) setText:(NSString *) text;

- (void) sizeToFit;
- (float) descriptionHeight;
- (int) descriptionRowCount;
	
- (id) target;
- (void) setTarget:(id) object;

- (SEL) action;
- (void) setAction:(SEL) selector;
@end

