//
//  GrowlWebKitWindowController.m
//  Growl
//
//  Created by Ingmar Stein on Thu Apr 14 2005.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "GrowlWebKitWindowController.h"
#import "GrowlWebKitWindowView.h"
#import "GrowlWebKitPrefsController.h"
#import "GrowlWebKitDefines.h"
#import "GrowlImageURLProtocol.h"
#import "NSWindow+Transforms.h"
#import "GrowlPluginController.h"
#import "NSViewAdditions.h"
#import "GrowlDefines.h"
#import "GrowlPathUtilities.h"
#import "GrowlApplicationNotification.h"
#include "CFGrowlAdditions.h"
#include "CFDictionaryAdditions.h"
#include "CFMutableStringAdditions.h"
#import "GrowlNotificationDisplayBridge.h"
#import "GrowlDisplayPlugin.h"
#import "GrowlFadingWindowTransition.h"

/*
 * A panel that always pretends to be the key window.
 */
@interface KeyPanel : NSPanel {
}
@end

@implementation KeyPanel
- (BOOL) isKeyWindow {
	return YES;
}
@end

static unsigned webkitWindowDepth = 0U;

@implementation GrowlWebKitWindowController

#define MIN_DISPLAY_TIME				4.0
#define ADDITIONAL_LINES_DISPLAY_TIME	0.5
#define MAX_DISPLAY_TIME				10.0
#define GrowlWebKitPadding				5.0f

#pragma mark -

- (id) initWithBridge:(GrowlNotificationDisplayBridge *)displayBridge {
	// init the window used to init
	NSPanel *panel = [[KeyPanel alloc] initWithContentRect:NSMakeRect(0.0f, 0.0f, 270.0f, 1.0f)
												 styleMask:NSBorderlessWindowMask | NSNonactivatingPanelMask
												   backing:NSBackingStoreBuffered
													 defer:YES];

	if (!(self = [super initWithWindow:panel]))
		return nil;

	GrowlDisplayPlugin *plugin = [displayBridge display];

	// Read the template file....exit on error...
	NSError *error = nil;
	NSBundle *displayBundle = [plugin bundle];
	NSString *templateFile = [displayBundle pathForResource:@"template" ofType:@"html"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:templateFile])
		templateFile = [[NSBundle mainBundle] pathForResource:@"template" ofType:@"html"];
	templateHTML = [[NSString alloc] initWithContentsOfFile:templateFile
												   encoding:NSUTF8StringEncoding
													  error:&error];
	if (!templateHTML) {
		NSLog(@"ERROR: could not read template '%@' - %@", templateFile,error);
		[self release];
		return nil;
	}
	baseURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)[displayBundle resourcePath], kCFURLPOSIXPathStyle, true);

	[self setDelegate:self]; // Needed???

	// Read the prefs for the plugin...
	unsigned theScreenNo = 0U;
	READ_GROWL_PREF_INT(GrowlWebKitScreenPref, [plugin prefDomain], &theScreenNo);
	[self setScreenNumber:theScreenNo];

	// the visibility time for this bubble should be the minimum display time plus
	// some multiple of ADDITIONAL_LINES_DISPLAY_TIME, not to exceed MAX_DISPLAY_TIME
	int rowCount = 2;
	BOOL limitPref = YES;
	READ_GROWL_PREF_BOOL(GrowlWebKitLimitPref, [plugin prefDomain], &limitPref);
	float duration = MIN_DISPLAY_TIME;
	READ_GROWL_PREF_FLOAT(GrowlWebKitDurationPref, [plugin prefDomain], &duration);
	if (limitPref)
		[self setDisplayDuration:duration];
	else
		[self setDisplayDuration:MIN(duration + rowCount * ADDITIONAL_LINES_DISPLAY_TIME,
									 MAX_DISPLAY_TIME)];

	// Read the plugin specifics from the info.plist
	NSDictionary *styleInfo = [[plugin bundle] infoDictionary];
	BOOL hasShadow = NO;
	hasShadow =	[(NSNumber *)[styleInfo valueForKey:@"GrowlHasShadow"] boolValue];
	paddingX = GrowlWebKitPadding;
	paddingY = GrowlWebKitPadding;
	NSNumber *xPad = [styleInfo valueForKey:@"GrowlPaddingX"];
	NSNumber *yPad = [styleInfo valueForKey:@"GrowlPaddingY"];
	if (xPad)
		paddingX = [xPad floatValue];
	if (yPad)
		paddingY = [yPad floatValue];

	// Configure the window
	[panel setBecomesKeyOnlyIfNeeded:YES];
	[panel setHidesOnDeactivate:NO];
	[panel setBackgroundColor:[NSColor clearColor]];
	[panel setLevel:NSStatusWindowLevel];
	[panel setSticky:YES];
	[panel setAlphaValue:0.0f];
	[panel setOpaque:NO];
	[panel setCanHide:NO];
	[panel setOneShot:YES];
	[panel useOptimizedDrawing:YES];
	[panel disableCursorRects];
	[panel setHasShadow:hasShadow];

	// Configure the view
	NSRect panelFrame = [panel frame];
	GrowlWebKitWindowView *view = [[GrowlWebKitWindowView alloc] initWithFrame:panelFrame
																	 frameName:nil
																	 groupName:nil];
	[view setMaintainsBackForwardList:NO];
	[view setTarget:self];
	[view setAction:@selector(notificationClicked:)];
	[view setPolicyDelegate:self];
	[view setFrameLoadDelegate:self];
	if ([view respondsToSelector:@selector(setDrawsBackground:)])
		[view setDrawsBackground:NO];
	[panel setContentView:view];
	[panel makeFirstResponder:[[[view mainFrame] frameView] documentView]];
	[self setBridge:displayBridge];

	// set up the transitions...
	GrowlFadingWindowTransition *fader = [[GrowlFadingWindowTransition alloc] initWithWindow:panel];
	[self addTransition:fader];
	[self setStartPercentage:0 endPercentage:100 forTransition:fader];
	[fader setAutoReverses:YES];
	[fader release];
	
	return self;
}

- (void) dealloc {
	if (depth == webkitWindowDepth)
		webkitWindowDepth = 0U;

	WebView *webView = [[self window] contentView];
	[webView      setPolicyDelegate:nil];
	[webView      setFrameLoadDelegate:nil];
	[image        release];
	[templateHTML release];

	[super dealloc];
}

- (void) setTitle:(NSString *)title titleHTML:(BOOL)titleIsHTML text:(NSString *)text textHTML:(BOOL)textIsHTML icon:(NSImage *)icon priority:(int)priority forView:(WebView *)view {
	CFStringRef priorityName;
	switch (priority) {
		case -2:
			priorityName = CFSTR("verylow");
			break;
		case -1:
			priorityName = CFSTR("moderate");
			break;
		default:
		case 0:
			priorityName = CFSTR("normal");
			break;
		case 1:
			priorityName = CFSTR("high");
			break;
		case 2:
			priorityName = CFSTR("emergency");
			break;
	}

	CFMutableStringRef htmlString = CFStringCreateMutableCopy(kCFAllocatorDefault, 0, (CFStringRef)templateHTML);
	CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
	CFStringRef uuidString = CFUUIDCreateString(kCFAllocatorDefault, uuid);
	CFRelease(uuid);
	image = [icon retain];
	[image setName:(NSString *)uuidString];
	[GrowlImageURLProtocol class];	// make sure GrowlImageURLProtocol is +initialized

	float opacity = 95.0f;
	READ_GROWL_PREF_FLOAT(GrowlWebKitOpacityPref, [[bridge display] prefDomain], &opacity);
	opacity *= 0.01f;

	CFStringRef titleHTML = titleIsHTML ? (CFStringRef)title : createStringByEscapingForHTML((CFStringRef)title);
	CFStringRef textHTML = textIsHTML ? (CFStringRef)text : createStringByEscapingForHTML((CFStringRef)text);
	CFStringRef opacityString = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("%f"), opacity);

	CFStringFindAndReplace(htmlString, CFSTR("%baseurl%"),  CFURLGetString(baseURL), CFRangeMake(0, CFStringGetLength(htmlString)), 0);
	CFStringFindAndReplace(htmlString, CFSTR("%opacity%"),  opacityString,           CFRangeMake(0, CFStringGetLength(htmlString)), 0);
	CFStringFindAndReplace(htmlString, CFSTR("%priority%"), priorityName,            CFRangeMake(0, CFStringGetLength(htmlString)), 0);
	CFStringFindAndReplace(htmlString, CFSTR("%image%"),    uuidString,              CFRangeMake(0, CFStringGetLength(htmlString)), 0);
	CFStringFindAndReplace(htmlString, CFSTR("%title%"),    titleHTML,               CFRangeMake(0, CFStringGetLength(htmlString)), 0);
	CFStringFindAndReplace(htmlString, CFSTR("%text%"),     textHTML,                CFRangeMake(0, CFStringGetLength(htmlString)), 0);

	CFRelease(uuidString);
	CFRelease(opacityString);
	CFRelease(baseURL);
	if (!titleIsHTML)
		CFRelease(titleHTML);
	if (!textIsHTML)
		CFRelease(textHTML);
	WebFrame *webFrame = [view mainFrame];
	[[self window] disableFlushWindow];
	[self retain];							// Needed?
	[webFrame loadHTMLString:(NSString *)htmlString baseURL:nil];
	[[webFrame frameView] setAllowsScrolling:NO];
	CFRelease(htmlString);
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
#pragma unused(sender, request, frame)
	int actionKey = getIntegerForKey(actionInformation, WebActionNavigationTypeKey);
	if (actionKey == WebNavigationTypeOther) {
		[listener use];
	} else {
		NSURL *url = getObjectForKey(actionInformation, WebActionOriginalURLKey);

		//Ignore file URLs, but open anything else
		if (![url isFileURL])
			[[NSWorkspace sharedWorkspace] openURL:url];

		[listener ignore];
	}
}

/*!
 * @brief Invoked once the webview has loaded and is ready to accept content
 */
- (void) webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
#pragma unused(frame)
	NSWindow *myWindow = [self window];
	if ([myWindow isFlushWindowDisabled])
		[myWindow enableFlushWindow];

	GrowlWebKitWindowView *view = (GrowlWebKitWindowView *)sender;
	[view sizeToFit];
#warning all this needs to be handled by super or the positioning controller, left in for now
	if (!positioned) {
		NSRect panelFrame = [view frame];
		NSRect screen = [[self screen] visibleFrame];
		[myWindow setFrameTopLeftPoint:NSMakePoint(NSMaxX(screen) - NSWidth(panelFrame) - paddingX,
												   NSMaxY(screen) - paddingY - webkitWindowDepth)];

		// It actually doesn't even stop _this_ notification from spilling off the bottom; just the next one.
		if (NSMinY(panelFrame) < 0.0f)
			depth = webkitWindowDepth = 0U;
		else
			depth = webkitWindowDepth += NSHeight(panelFrame) + paddingY;
		positioned = YES;
	}
	[myWindow invalidateShadow];
	[self startDisplay];			//-> Hopefuly this will handle all the transitions etc and know what state we are already in.
	[self release];	// we retained before loadHTMLString
}

- (void) setNotification:(GrowlApplicationNotification *)theNotification {
    //NSLog(@"in -setNotification:, old value of notification: %@, changed to: %@", notification, theNotification);

    if (notification == theNotification)
		return;

	[super setNotification:theNotification];

	// Extract the new details from the notification
	NSDictionary *noteDict = [notification dictionaryRepresentation];
	NSString *title = [notification HTMLTitle];
	NSString *text  = [notification HTMLDescription];
	NSImage *icon   = getObjectForKey(noteDict, GROWL_NOTIFICATION_ICON);
	int priority    = getIntegerForKey(noteDict, GROWL_NOTIFICATION_PRIORITY);
	/*BOOL sticky     = getBooleanForKey(noteDict, GROWL_NOTIFICATION_STICKY);
	NSString *ident = getObjectForKey(noteDict, GROWL_NOTIFICATION_IDENTIFIER);*/
	BOOL textHTML, titleHTML;

	if (title)
		titleHTML = YES;
	else {
		titleHTML = NO;
		title = [notification title];
	}
	if (text)
		textHTML = YES;
	else {
		textHTML = NO;
		text = [notification notificationDescription];
	}

	NSPanel *panel = (NSPanel *)[self window];
	WebView *view = [panel contentView];
	[self retain];
	[self setTitle:title titleHTML:titleHTML text:text textHTML:textHTML icon:icon priority:priority forView:view];

	NSRect panelFrame = [view frame];
	[panel setFrame:panelFrame display:NO];
}

#pragma mark -
#pragma mark positioning methods

- (NSPoint) idealOriginInRect:(NSRect)rect {
	NSRect viewFrame = [[[self window] contentView] frame];
	return NSMakePoint(NSMaxX(rect) - NSWidth(viewFrame) - paddingX,
					   NSMaxY(rect) - paddingY - NSHeight(viewFrame));
}

- (GrowlExpansionDirection) primaryExpansionDirection {
	return GrowlDownExpansionDirection;
}

- (GrowlExpansionDirection) secondaryExpansionDirection {
	return GrowlLeftExpansionDirection;
}

- (float) requiredDistanceFromExistingDisplays {
	return paddingY;
}

@end
