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

- (id)initWithBundle:(id)fp8;
- (id)initWithBundle:(id)fp8 data:(id)fp12;
- (void)willUnload;
- (void)dealloc;
- (id)bundle;
- (float)length;
- (void)setLength:(float)fp8;
- (id)image;
- (void)setImage:(id)fp8;
- (id)alternateImage;
- (void)setAlternateImage:(id)fp8;
- (id)menu;
- (void)setMenu:(id)fp8;
- (id)toolTip;
- (void)setToolTip:(id)fp8;
- (id)view;
- (void)setView:(id)fp8;
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
- (id)attributedTitle;
- (void)setAttributedTitle:(id)fp8;
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

@interface NSMenuExtra (NSMenuExtraPrivate)
+ (unsigned int)defaultLength;
- (void)setController:(id)fp8;
- (id)controller;
- (void)setMenuDown:(BOOL)fp8;
- (float)defaultLength;
- (id)accessibilityAttributeNames;
- (id)accessibilityAttributeValue:(id)fp8;
- (BOOL)accessibilityIsAttributeSettable:(id)fp8;
- (void)accessibilitySetValue:(id)fp8 forAttribute:(id)fp12;
- (id)accessibilityActionNames;
- (id)accessibilityActionDescription:(id)fp8;
- (void)accessibilityPerformAction:(id)fp8;
- (BOOL)accessibilityIsIgnored;
- (id)accessibilityHitTest:(struct _NSPoint)fp8;
- (id)accessibilityFocusedUIElement;
- (id)AXRole;
- (id)AXRoleDescription;
- (id)AXSubrole;
- (id)AXDescription;
- (id)AXChildren;
- (id)AXParent;
- (id)AXTitle;
- (id)AXValue;
- (id)AXEnabled;
- (id)AXSelected;
- (BOOL)isAXSelectedSettable;
- (void)setAXSelected:(id)fp8;
- (id)AXPosition;
- (id)AXSize;
- (void)performAXPress;
- (void)performAXCancel;
@end
