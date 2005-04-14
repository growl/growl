//
//  GrowlWebKitWindowController.m
//  Growl
//
//  Created by Nelson Elhage on Wed Jun 09 2004.
//  Name changed from KABubbleWindowController.m by Justin Burns on Fri Nov 05 2004.
//  Copyright (c) 2004 Nelson Elhage. All rights reserved.
//

#import "GrowlWebKitWindowController.h"
#import "GrowlWebKitWindowView.h"
#import "GrowlWebKitPrefsController.h"
#import "GrowlWebKitDefines.h"
#import "NSWindow+Transforms.h"

static unsigned bubbleWindowDepth = 0U;

@implementation GrowlWebKitWindowController

#define MIN_DISPLAY_TIME				4.0
#define ADDITIONAL_LINES_DISPLAY_TIME	0.5
#define MAX_DISPLAY_TIME				10.0
#define GrowlWebKitPadding				5.0f

#pragma mark -

+ (GrowlWebKitWindowController *) bubbleWithTitle:(NSString *) title text:(NSString *) text icon:(NSImage *) icon priority:(int)priority sticky:(BOOL) sticky{
	return [[[GrowlWebKitWindowController alloc] initWithTitle:title text:text icon:icon priority:(int)priority sticky:sticky] autorelease];
}

#pragma mark Regularly Scheduled Coding

- (id) initWithTitle:(NSString *) title text:(NSString *) text icon:(NSImage *) icon priority:(int)priority sticky:(BOOL) sticky {
	screenNumber = 0U;
	READ_GROWL_PREF_INT(GrowlWebKitScreen, GrowlWebKitPrefDomain, &screenNumber);

	// I tried setting the width/height to zero, since the view resizes itself later.
	// This made it ignore the alpha at the edges (using 1.0 instead). Why?
	// A window with a frame of NSZeroRect is off-screen and doesn't respect opacity even
	// if moved on screen later. -Evan
	NSPanel *panel = [[NSPanel alloc] initWithContentRect:NSMakeRect( 0.0f, 0.0f, 270.0f, 65.0f ) 
												styleMask:NSBorderlessWindowMask | NSNonactivatingPanelMask
												  backing:NSBackingStoreBuffered
													defer:NO];
	NSRect panelFrame = [panel frame];
	[panel setBecomesKeyOnlyIfNeeded:YES];
	[panel setHidesOnDeactivate:NO];
	[panel setBackgroundColor:[NSColor clearColor]];
	[panel setLevel:NSStatusWindowLevel];
	[panel setSticky:YES];
	[panel setAlphaValue:0.0f];
	[panel setOpaque:NO];
	[panel setHasShadow:YES];
	[panel setCanHide:NO];
	[panel setOneShot:YES];
	[panel useOptimizedDrawing:YES];
	//[panel setReleasedWhenClosed:YES]; // ignored for windows owned by window controllers.
	//[panel setDelegate:self];

	GrowlWebKitWindowView *view = [[GrowlWebKitWindowView alloc] initWithFrame:panelFrame
																	 frameName:nil
																	 groupName:nil];
	[view setMaintainsBackForwardList:NO];
	[view setTarget:self];
	[view setAction:@selector(_notificationClicked:)];
	[view setPolicyDelegate:self];
	[view setFrameLoadDelegate:self];
	[panel setContentView:view];

	NSString *style = @"div.title { font-size:small; font-family: sans-serif; background-color:gray; } div.text { font-size:x-small; font-family: sans-serif; }";
	NSString *htmlString = [[NSString alloc] initWithFormat:@"<html><head><style type=\"text/css\">%@</style></head><body><div class=\"title\">%@</div><div class=\"text\">%@</div></body></html>", style, title, text];
	WebFrame *webFrame = [view mainFrame];
	[webFrame loadHTMLString:htmlString baseURL:nil];
	[[webFrame frameView] setAllowsScrolling:NO];
	[htmlString release];

	panelFrame = [view frame];
	[panel setFrame:panelFrame display:NO];

	if ((self = [super initWithWindow:panel])) {
		autoFadeOut = !sticky;
		delegate = self;

		// the visibility time for this bubble should be the minimum display time plus
		// some multiple of ADDITIONAL_LINES_DISPLAY_TIME, not to exceed MAX_DISPLAY_TIME
		int rowCount = 2;
		BOOL limitPref = YES;
		READ_GROWL_PREF_BOOL(KALimitPref, GrowlWebKitPrefDomain, &limitPref);
		float duration = MIN_DISPLAY_TIME;
		READ_GROWL_PREF_FLOAT(GrowlWebKitDuration, GrowlWebKitPrefDomain, &duration);
		if (!limitPref) {
			displayTime = MIN (duration + rowCount * ADDITIONAL_LINES_DISPLAY_TIME, 
							   MAX_DISPLAY_TIME);
		} else {
			displayTime = duration;
		}
	}

	return self;
}

/*!
* @brief Prevent the webview from following external links.  We direct these to the users web browser.
 */
- (void) webView:(WebView *)sender
    decidePolicyForNavigationAction:(NSDictionary *)actionInformation
		request:(NSURLRequest *)request
		  frame:(WebFrame *)frame
    decisionListener:(id<WebPolicyDecisionListener>)listener
{
    int actionKey = [[actionInformation objectForKey: WebActionNavigationTypeKey] intValue];
    if (actionKey == WebNavigationTypeOther){
		[listener use];
    } else {
		NSURL *url = [actionInformation objectForKey:WebActionOriginalURLKey];
		
		//Ignore file URLs, but open anything else
		if(![url isFileURL]){
			[[NSWorkspace sharedWorkspace] openURL:url];
		}
		
		[listener ignore];
    }
}

/*!
* @brief Invoked once the webview has loaded and is ready to accept content
 */
- (void) webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	GrowlWebKitWindowView *view = (GrowlWebKitWindowView *)sender;
	[view sizeToFit];
	NSRect panelFrame = [view frame];

	NSRect screen = [[self screen] visibleFrame];

	[[self window] setFrameTopLeftPoint:NSMakePoint( NSMaxX( screen ) - NSWidth( panelFrame ) - GrowlWebKitPadding,
											 NSMaxY( screen ) - GrowlWebKitPadding - bubbleWindowDepth )];
	
#warning this is some temporary code to to stop notifications from spilling off the bottom of the visible screen area
	// It actually doesn't even stop _this_ notification from spilling off the bottom; just the next one.
	if (NSMinY(panelFrame) < 0.0f) {
		depth = bubbleWindowDepth = 0U;
	} else {
		depth = bubbleWindowDepth += NSHeight(panelFrame) + GrowlWebKitPadding;
	}
}

- (void) startFadeOut {
	GrowlWebKitWindowView *view = (GrowlWebKitWindowView *)[[self window] contentView];
	if ([view mouseOver]) {
		[view setCloseOnMouseExit:YES];
	} else {
		[super startFadeOut];
	}
}

- (void) dealloc {
	if (depth == bubbleWindowDepth) {
		bubbleWindowDepth = 0U;
	}
	NSWindow *myWindow = [self window];
	WebView *webView = [myWindow contentView];
	[webView setPolicyDelegate:nil];
	[webView setFrameLoadDelegate:nil];
	[webView release];
	[myWindow release];

	[super dealloc];
}

@end
