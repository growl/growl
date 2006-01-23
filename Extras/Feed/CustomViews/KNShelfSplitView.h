//
//  KNShelfSplitView.h
//  Feed
//
//  Created by Keith on 1/21/06.
//  Copyright 2006 Keith Anderson. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface KNShelfSplitView : NSView {
	IBOutlet NSView *			shelfView;
	IBOutlet NSView *			contentView;
	IBOutlet id					delegate;
	IBOutlet id					target;
	SEL							action;
	
	NSString *					autosaveName;
	NSImage *					actionButtonImage;
	NSImage *					contextButtonImage;
	NSColor *					shelfBackgroundColor;
	float						currentShelfWidth;
	BOOL						isShelfVisible;
	NSMenu *					contextButtonMenu;
	
	NSRect						controlRect;
	BOOL						shouldDrawActionButton;
	NSRect						actionButtonRect;
	BOOL						shouldDrawContextButton;
	NSRect						contextButtonRect;
	NSRect						resizeThumbRect;
	NSRect						resizeBarRect;
	int							activeControlPart;
	BOOL						shouldHilite;
	
	BOOL						delegateHasValidateWidth;
}

-(IBAction)toggleShelf:(id)sender;

-(id)initWithFrame:(NSRect)aFrame shelfView:(NSView *)aShelfView contentView:(NSView *)aContentView;

-(void)setDelegate:(id)aDelegate;
-(id)delegate;
-(void)setTarget:(id)aTarget;
-(id)target;
-(void)setAction:(SEL)aSelector;
-(SEL)action;
-(void)setContextButtonMenu:(NSMenu *)aMenu;
-(NSMenu *)contextButtonMenu;

-(void)setShelfView:(NSView *)aView;
-(NSView *)shelfView;
-(void)setContentView:(NSView *)aView;
-(NSView *)contentView;

-(void)setShelfWidth:(float)aWidth;
-(float)shelfWidth;

-(BOOL)isShelfVisible;
-(void)setShelfIsVisible:(BOOL)visible;

-(void)setAutosaveName:(NSString *)aName;
-(NSString *)autosaveName;


-(void)setActionButtonImage:(NSImage *)anImage;
-(NSImage *)actionButtonImage;
-(void)setContextButtonImage:(NSImage *)anImage;
-(NSImage *)contextButtonImage;
-(void)setShelfBackgroundColor:(NSColor *)aColor;
-(NSColor *)shelfBackgroundColor;


-(void)recalculateSizes;
-(void)drawControlBackgroundInRect:(NSRect)aRect active:(BOOL)isActive;

@end

@interface NSObject (KNShelfSplitViewDelegate)
-(float)shelfSplitView:(KNShelfSplitView *)shelfSplitView validateWidth:(float)proposedWidth;
@end
