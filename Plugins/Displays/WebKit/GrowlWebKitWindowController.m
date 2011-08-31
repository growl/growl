//
//  GrowlWebKitWindowController.m
//  Growl
//
//  Created by Ingmar Stein on Thu Apr 14 2005.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlWebKitWindowController.h"
#import "GrowlWebKitWindowView.h"
#import "GrowlWebKitPrefsController.h"
#import "GrowlWebKitDefines.h"
#import "GrowlPluginController.h"
#import "NSViewAdditions.h"
#import "GrowlDefines.h"
#import "GrowlPathUtilities.h"
#import "GrowlNotification.h"
#import "NSMutableStringAdditions.h"
#import "GrowlNotificationDisplayBridge.h"
#import "GrowlDisplayPlugin.h"
#import "GrowlFadingWindowTransition.h"
#import "GrowlImageAdditions.h"
#import "NSStringAdditions.h"

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

@interface NSData (Base64Additions)
- (NSString *)base64Encoding;
@end

@interface GrowlWebKitWindowController ()
- (void) viewIsReady:(GrowlWebKitWindowView *)view;
@end

@implementation GrowlWebKitWindowController

#define GrowlWebKitDurationPrefDefault				5.0
#define ADDITIONAL_LINES_DISPLAY_TIME	0.5
#define MAX_DISPLAY_TIME				10.0
#define GrowlWebKitPadding				5.0

#pragma mark -

- (id) initWithBridge:(GrowlNotificationDisplayBridge *)displayBridge {
	// init the window used to init
	NSPanel *panel = [[KeyPanel alloc] initWithContentRect:NSMakeRect(0.0, 0.0, 270.0, 1.0)
												 styleMask:NSBorderlessWindowMask | NSNonactivatingPanelMask
												   backing:NSBackingStoreBuffered
													 defer:YES];
	if (!(self = [super initWithWindow:panel])) {
		[panel release];
		return nil;
	}

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
	baseURL = [[NSURL fileURLWithPath:[displayBundle resourcePath]] retain];

	// Read the prefs for the plugin...
	unsigned theScreenNo = 0U;
	READ_GROWL_PREF_INT(GrowlWebKitScreenPref, [plugin prefDomain], &theScreenNo);
	[self setScreenNumber:theScreenNo];

	CFNumberRef prefsDuration = NULL;
	READ_GROWL_PREF_VALUE(GrowlWebKitDurationPref, [plugin prefDomain], CFNumberRef, &prefsDuration);
	[self setDisplayDuration:(prefsDuration ?
							  [(NSNumber *)prefsDuration doubleValue] :
							  GrowlWebKitDurationPrefDefault)];
	if (prefsDuration) CFRelease(prefsDuration);
	
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
	[panel setLevel:GrowlVisualDisplayWindowLevel];
	[panel setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	[panel setAlphaValue:0.0];
	[panel setOpaque:NO];
	[panel setCanHide:NO];
	[panel setOneShot:YES];
	[panel useOptimizedDrawing:YES];
	[panel disableCursorRects];
	[panel setHasShadow:hasShadow];
	[panel setDelegate:self];

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
	[view release];

	[self setBridge:displayBridge];

	// set up the transitions...
	GrowlFadingWindowTransition *fader = [[GrowlFadingWindowTransition alloc] initWithWindow:panel];
	[self addTransition:fader];
	[self setStartPercentage:0 endPercentage:100 forTransition:fader];
	[fader setAutoReverses:YES];
	[fader release];

	[panel release];

	return self;
}

- (void) dealloc {
	GrowlWebKitWindowView *webView = [[self window] contentView];
	[webView      setPolicyDelegate:nil];
	[webView      setFrameLoadDelegate:nil];
	[webView      setTarget:nil];

	[templateHTML release];
	[baseURL	  release];
	
	[super dealloc];
}

- (void) setTitle:(NSString *)title text:(NSString *)text icon:(NSImage *)icon priority:(int)priority forView:(WebView *)view {
	NSString *priorityName;
	switch (priority) {
		case -2:
			priorityName = @"verylow";
			break;
		case -1:
			priorityName = @"moderate";
			break;
		default:
		case 0:
			priorityName = @"normal";
			break;
		case 1:
			priorityName = @"high";
			break;
		case 2:
			priorityName = @"emergency";
			break;
	}

	NSMutableString *htmlString = [[templateHTML mutableCopy] autorelease];

	NSString *imageMediaType = @"image/png";
	NSData *imageData = [icon PNGRepresentation];
	if (!imageData) {
		//Couldn't create a PNG, so fall back on TIFF.
		imageMediaType = @"image/tiff";
		imageData = [icon TIFFRepresentation];
	}
	NSString *growlImageString = [NSString stringWithFormat:@"data:%@;base64,%@", imageMediaType, [imageData base64Encoding]];

	CGFloat opacity = 95.0;
	READ_GROWL_PREF_FLOAT(GrowlWebKitOpacityPref, [[bridge display] prefDomain], &opacity);
	opacity *= 0.01;

	NSString *titleHTML = [title stringByEscapingForHTML];
	NSString *textHTML = [text stringByEscapingForHTML];
	NSString *opacityString = [NSString stringWithFormat:@"%f", opacity];

	[htmlString replaceOccurrencesOfString:@"%baseurl%" withString:[baseURL absoluteString] options:0 range:NSMakeRange(0, [htmlString length])];
	[htmlString replaceOccurrencesOfString:@"%opacity%" withString:opacityString options:0 range:NSMakeRange(0, [htmlString length])];
	[htmlString replaceOccurrencesOfString:@"%priority%" withString:priorityName options:0 range:NSMakeRange(0, [htmlString length])];
	[htmlString replaceOccurrencesOfString:@"growlimage://%image%" withString:growlImageString options:0 range:NSMakeRange(0, [htmlString length])];
	[htmlString replaceOccurrencesOfString:@"%title%" withString:titleHTML options:0 range:NSMakeRange(0, [htmlString length])];
	[htmlString replaceOccurrencesOfString:@"%text%" withString:textHTML options:0 range:NSMakeRange(0, [htmlString length])];

	WebFrame *webFrame = [view mainFrame];
	[[self window] disableFlushWindow];

	[webFrame loadHTMLString:htmlString baseURL:baseURL];
	[[webFrame frameView] setAllowsScrolling:NO];
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
	int actionKey = [[actionInformation objectForKey:WebActionNavigationTypeKey] intValue];
	if (actionKey == WebNavigationTypeOther) {
		[listener use];
	} else {
		NSURL *url = [actionInformation objectForKey:WebActionOriginalURLKey];

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
	if (frame != [sender mainFrame]) return;

	if ([[[frame frameView] documentView] frame].size.height < 2.0f) {
		//Finished loading it may be, but it's not finished rendering, in which case the document view's height will be 1 px. Not good for sizing to fit. So, try again one cycle of the run loop from now.
		[self performSelector:@selector(viewIsReady:) withObject:sender afterDelay:0.0];
	} else {
		//It really is done, so just call through directly.
		[self viewIsReady:(GrowlWebKitWindowView *)sender];
	}
}
- (void) viewIsReady:(GrowlWebKitWindowView *)view {
	NSWindow *myWindow = [self window];
	if ([myWindow isFlushWindowDisabled])
		[myWindow enableFlushWindow];

	[view sizeToFit];

	//Update our new frame
	[[GrowlPositionController sharedInstance] positionDisplay:self];

	[myWindow invalidateShadow];
}

- (void) setNotification:(GrowlNotification *)theNotification {
    if (notification == theNotification)
		return;

	[super setNotification:theNotification];

	// Extract the new details from the notification
	NSDictionary *noteDict = [notification dictionaryRepresentation];
	NSString *title = [notification title];
	NSString *text  = [notification notificationDescription];

	NSImage *icon;	
	NSData *iconData = [noteDict objectForKey:GROWL_NOTIFICATION_ICON_DATA];
	if ([iconData isKindOfClass:[NSImage class]])
		icon = (NSImage *)iconData;
	else
		icon = (iconData ? [[[NSImage alloc] initWithData:iconData] autorelease] : nil);
	
	int priority    = [[noteDict objectForKey:GROWL_NOTIFICATION_PRIORITY] intValue];

	NSPanel *panel = (NSPanel *)[self window];
	WebView *view = [panel contentView];
	[self setTitle:title text:text icon:icon priority:priority forView:view];
}

#pragma mark -
#pragma mark positioning methods

- (NSPoint) idealOriginInRect:(NSRect)rect {
	NSView *contentView = [[self window] contentView];
	NSRect viewFrame = [contentView frame];
	enum GrowlPosition originatingPosition = [[GrowlPositionController sharedInstance] originPosition];
	NSPoint idealOrigin;

	switch(originatingPosition){
		case GrowlTopRightPosition:
			idealOrigin = NSMakePoint(NSMaxX(rect) - NSWidth(viewFrame) - paddingX,
									  NSMaxY(rect) - paddingY - NSHeight(viewFrame));
			break;
		case GrowlTopLeftPosition:
			idealOrigin = NSMakePoint(NSMinX(rect) + paddingX,
									  NSMaxY(rect) - paddingY - NSHeight(viewFrame));
			break;
		case GrowlBottomLeftPosition:
			idealOrigin = NSMakePoint(NSMinX(rect) + paddingX,
									  NSMinY(rect) + paddingY);
			break;
		case GrowlBottomRightPosition:
			idealOrigin = NSMakePoint(NSMaxX(rect) - NSWidth(viewFrame) - paddingX,
									  NSMinY(rect) + paddingY);
			break;
		default:
			idealOrigin = NSMakePoint(NSMaxX(rect) - NSWidth(viewFrame) - paddingX,
									  NSMaxY(rect) - paddingY - NSHeight(viewFrame));
			break;			
	}

	return idealOrigin;	
}

- (enum GrowlExpansionDirection) primaryExpansionDirection {
	enum GrowlPosition originatingPosition = [[GrowlPositionController sharedInstance] originPosition];
	enum GrowlExpansionDirection directionToExpand;
	
	switch(originatingPosition){
		case GrowlTopLeftPosition:
			directionToExpand = GrowlDownExpansionDirection;
			break;
		case GrowlTopRightPosition:
			directionToExpand = GrowlDownExpansionDirection;
			break;
		case GrowlBottomLeftPosition:
			directionToExpand = GrowlUpExpansionDirection;
			break;
		case GrowlBottomRightPosition:
			directionToExpand = GrowlUpExpansionDirection;
			break;
		default:
			directionToExpand = GrowlDownExpansionDirection;
			break;			
	}
	
	return directionToExpand;
}

- (enum GrowlExpansionDirection) secondaryExpansionDirection {
	enum GrowlPosition originatingPosition = [[GrowlPositionController sharedInstance] originPosition];
	enum GrowlExpansionDirection directionToExpand;
	
	switch(originatingPosition){
		case GrowlTopLeftPosition:
			directionToExpand = GrowlRightExpansionDirection;
			break;
		case GrowlTopRightPosition:
			directionToExpand = GrowlLeftExpansionDirection;
			break;
		case GrowlBottomLeftPosition:
			directionToExpand = GrowlRightExpansionDirection;
			break;
		case GrowlBottomRightPosition:
			directionToExpand = GrowlLeftExpansionDirection;
			break;
		default:
			directionToExpand = GrowlRightExpansionDirection;
			break;
	}
	
	return directionToExpand;
}

- (CGFloat) requiredDistanceFromExistingDisplays {
	return paddingY;
}

@end

@implementation NSData (Base64Additions)

static const unichar encodingTable[64] = {
	'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
	'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
	'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/' };

- (NSString *) base64EncodingWithLineLength:(unsigned int) lineLength {
	const unsigned char	*bytes = [self bytes];
	NSMutableString *result = [NSMutableString stringWithCapacity:[self length]];
	unsigned long ixtext = 0;
	unsigned long lentext = [self length];
	long ctremaining = 0;
	unsigned char inbuf[3], outbuf[4];
	unsigned short i = 0;
	unsigned short charsonline = 0, ctcopy = 0;
	unsigned long ix = 0;
	
	while( YES ) {
		ctremaining = lentext - ixtext;
		if( ctremaining <= 0 ) break;
		
		for( i = 0; i < 3; i++ ) {
			ix = ixtext + i;
			if( ix < lentext ) inbuf[i] = bytes[ix];
			else inbuf [i] = 0;
		}
		
		outbuf [0] = (inbuf [0] & 0xFC) >> 2;
		outbuf [1] = ((inbuf [0] & 0x03) << 4) | ((inbuf [1] & 0xF0) >> 4);
		outbuf [2] = ((inbuf [1] & 0x0F) << 2) | ((inbuf [2] & 0xC0) >> 6);
		outbuf [3] = inbuf [2] & 0x3F;
		ctcopy = 4;
		
		switch( ctremaining ) {
			case 1:
				ctcopy = 2;
				break;
			case 2:
				ctcopy = 3;
				break;
		}
		
		for( i = 0; i < ctcopy; i++ )
			[result appendCharacter:encodingTable[outbuf[i]]];
		
		for( i = ctcopy; i < 4; i++ )
			[result appendString:@"="];
		
		ixtext += 3;
		charsonline += 4;
		
		if( lineLength > 0 ) {
			if( charsonline >= lineLength ) {
				charsonline = 0;
				[result appendString:@"\n"];
			}
		}
	}
	
	return result;
}

- (NSString *) base64Encoding {
	return [self base64EncodingWithLineLength:0];
}

@end
