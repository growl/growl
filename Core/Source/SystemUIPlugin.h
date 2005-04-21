//  SystemUIPlugin.h

@class NSBundle, NSMenu, NSView;

@interface NSMenuExtra : NSStatusItem
{
    NSBundle *_bundle;
    NSMenu *_menu;
    NSView *_view;
    float _length;
    struct {
        unsigned int customView:1;
        unsigned int menuDown:1;
        unsigned int reserved:30;
    } _flags;
    id _controller;
}

- (id)initWithBundle:(NSBundle *)fp8;
- (id)initWithBundle:(NSBundle *)fp8 data:(id)fp12;
- (void)willUnload;
- (void)dealloc;
- (NSBundle *)bundle;
- (float)length;
- (void)setLength:(float)fp8;
- (NSImage *)image;
- (void)setImage:(NSImage *)fp8;
- (NSImage *)alternateImage;
- (void)setAlternateImage:(NSImage *)fp8;
- (NSMenu *)menu;
- (void)setMenu:(NSMenu *)fp8;
- (NSString *)toolTip;
- (void)setToolTip:(NSString *)fp8;
- (NSView *)view;
- (void)setView:(NSView *)fp8;
- (BOOL)isMenuDown;
- (void)drawMenuBackground:(BOOL)fp8;
- (void)popUpMenu:(id)fp8;
- (void)unload;
- (id)statusBar;
- (SEL)action;
- (void)setAction:(SEL)fp8;
- (id)target;
- (void)setTarget:(id)fp8;
- (id)title;
- (void)setTitle:(id)fp8;
- (NSAttributedString *)attributedTitle;
- (void)setAttributedTitle:(NSAttributedString *)fp8;
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)fp8;
- (void)setHighlightMode:(BOOL)fp8;
- (BOOL)highlightMode;
- (void)sendActionOn:(int)fp8;
- (id)_initInStatusBar:(id)fp8 withLength:(float)fp12 withPriority:(int)fp16;
- (id)_window;
- (id)_button;
- (void)_adjustLength;

@end
