//
//  GrowlWebKitWindowController.m
//  Growl
//
//  Created by Ingmar Stein on Thu Apr 14 2005.
//  Copyright 2005–2011 The Growl Project. All rights reserved.
//

#import <GrowlPlugins/GrowlNotification.h>
#import <GrowlPlugins/GrowlDisplayPlugin.h>
#import <GrowlPlugins/GrowlFadingWindowTransition.h>
#import "GrowlDisplayBridgeController.h"
#import "GrowlWebKitWindowController.h"
#import "GrowlWebKitWindowView.h"
#import "GrowlWebKitPrefsController.h"
#import "GrowlWebKitDefines.h"
#import "GrowlWebKitWindowTransition.h"
#import "GrowlPluginController.h"
#import "NSViewAdditions.h"
#import "GrowlDefines.h"
#import "GrowlPathUtilities.h"
#import "NSMutableStringAdditions.h"
#import "GrowlImageAdditions.h"
#import "NSStringAdditions.h"
#import "GrowlPositioningDefines.h"

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

@interface GrowlWebKitWindowController ()
- (void) viewIsReady:(GrowlWebKitWindowView *)view;
@end

@implementation GrowlWebKitWindowController

#define GrowlWebKitDurationPrefDefault				5.0
#define ADDITIONAL_LINES_DISPLAY_TIME	0.5
#define MAX_DISPLAY_TIME				10.0
#define GrowlWebKitPadding				5.0

#pragma mark -

/* This is used to hold on to an image, while it might be needed.
 * (Until the window closes).
 */

static dispatch_queue_t __imageCacheQueue;

+ (void)initialize {
   if(self != [GrowlWebKitWindowController class])
      return;
   
   __imageCacheQueue = dispatch_queue_create("growlwebkitimagecachequeue", DISPATCH_QUEUE_CONCURRENT);
}

+ (NSMutableDictionary *)imageCache {
	static NSMutableDictionary *imageCache = nil;
	static dispatch_once_t onceToken;
   dispatch_once(&onceToken, ^{
      imageCache = [[NSMutableDictionary alloc] init];
   });
	
	return imageCache;
}

+ (NSData*)cachedImageForKey:(NSString *)key {
   __block NSData *image = nil;
   dispatch_sync(__imageCacheQueue, ^{
      image = [[GrowlWebKitWindowController imageCache] objectForKey:key];
      [image retain];
   });
   return [image autorelease];
}

+ (void)setCachedImage:(NSData*)image forKey:(NSString*)key {
   dispatch_barrier_sync(__imageCacheQueue, ^{
      [[GrowlWebKitWindowController imageCache] setObject:image forKey:key];
   });
}

+ (void)removeCachedImageForKey:(NSString*)key {
   dispatch_barrier_sync(__imageCacheQueue, ^{
      [[GrowlWebKitWindowController imageCache] removeObjectForKey:key];
   });
}

- (id) initWithNotification:(GrowlNotification *)note plugin:(GrowlDisplayPlugin *)aPlugin {
	// init the window used to init
	NSDictionary *configDict = [note configurationDict];
	
	NSPanel *panel = [[KeyPanel alloc] initWithContentRect:NSMakeRect(0.0, 0.0, 270.0, 1.0)
												 styleMask:NSBorderlessWindowMask | NSNonactivatingPanelMask
												   backing:NSBackingStoreBuffered
													 defer:YES];
	if (!(self = [super initWithWindow:panel andPlugin:aPlugin])) {
		[panel release];
		return nil;
	}

	// Read the template file....exit on error...
	NSError *error = nil;
	NSBundle *displayBundle = [aPlugin bundle];
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
	if([configDict valueForKey:GrowlWebKitScreenPref]){
		theScreenNo = [[configDict valueForKey:GrowlWebKitScreenPref] unsignedIntValue];
	}
	[self setScreenNumber:theScreenNo];

	NSTimeInterval duration = GrowlWebKitDurationPrefDefault;
	if([configDict valueForKey:GrowlWebKitDurationPref]){
		duration = [[configDict valueForKey:GrowlWebKitDurationPref] floatValue];
	}
	self.displayDuration = duration;
	
	// Read the plugin specifics from the info.plist
	NSDictionary *styleInfo = [displayBundle infoDictionary];
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
	[view setStyleBundle:[plugin bundle]];
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

	// set up the transitions...
	NSDictionary *bundleDict = [[plugin bundle] infoDictionary];
	if(![bundleDict objectForKey:@"UseDefaultWebKitFadeInOut"] || [[bundleDict objectForKey:@"UseDefaultWebKitFadeInOut"] boolValue]){
		GrowlFadingWindowTransition *fader = [[GrowlFadingWindowTransition alloc] initWithWindow:panel];
		[self addTransition:fader];
		[self setStartPercentage:0 endPercentage:100 forTransition:fader];
		[fader setAutoReverses:YES];
		[fader release];
	}else{
		//For now, just do this to force the window to be there
		GrowlFadingWindowTransition *fader = [[GrowlFadingWindowTransition alloc] initWithWindow:panel];
		[self addTransition:fader];
		[self setStartPercentage:100 endPercentage:100 forTransition:fader];
		[fader setAutoReverses:YES];
		[fader release];
	}
	if([bundleDict objectForKey:@"UseWebKitAnimationOut"] && [[bundleDict objectForKey:@"UseWebKitAnimationOut"] boolValue]){
		GrowlWebKitWindowTransition *webkitTransition = [[GrowlWebKitWindowTransition alloc] initWithWindow:panel];
		[self addTransition:webkitTransition];
		[self setStartPercentage:0 endPercentage:100 forTransition:webkitTransition];
		[webkitTransition setAutoReverses:YES];
		[webkitTransition release];
	}
	if([bundleDict objectForKey:@"WebKitAnimationDuration"]){
		[self setTransitionDuration:[[bundleDict objectForKey:@"WebKitAnimationDuration"] floatValue]];
	}
	
	[panel release];
		
	return self;
}

- (void)startDisplay {
	[[GrowlDisplayBridgeController sharedController] addPendingWindow:self];
}

- (void)stopDisplay {
	
	if (cacheKey) {
		[GrowlWebKitWindowController removeCachedImageForKey:cacheKey];
		
		[cacheKey release]; cacheKey = nil;
	}
	
	[super stopDisplay];
}

- (void) dealloc {
	GrowlWebKitWindowView *webView = [[self window] contentView];
	//we do this because its entirely possible to make it to dealloc before a
    //WebView has been assigned as the contentView for our window and all of these
    //method calls expect that that has happened
    if([webView isKindOfClass:[GrowlWebKitWindowView class]])
    {
        [webView      setPolicyDelegate:nil];
        [webView      setFrameLoadDelegate:nil];
        [webView      setTarget:nil];
    }
    
	[templateHTML release];
	[baseURL	  release];
	
	[cacheKey     release];
	
	[super dealloc];
}

- (void) setTitle:(NSString *)title text:(NSString *)text iconData:(NSData *)iconData priority:(int)priority forView:(WebView *)view {
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
	
	if (cacheKey) {
		[GrowlWebKitWindowController removeCachedImageForKey:cacheKey];
		[cacheKey release];
	}
	
	cacheKey = [[NSString alloc] initWithFormat:@"growlimage://%p", view];
	
	[GrowlWebKitWindowController setCachedImage:iconData forKey:cacheKey];
	
	CGFloat opacity = 95.0;
	if([[self configurationDict] valueForKey:GrowlWebKitOpacityPref]){
		opacity = [[[self configurationDict] valueForKey:GrowlWebKitOpacityPref] floatValue];
	}
	opacity *= 0.01;

	NSString *titleHTML = [title stringByEscapingForHTML];
	NSString *textHTML = [text stringByEscapingForHTML];
	NSString *opacityString = [NSString stringWithFormat:@"%f", opacity];

	[htmlString replaceOccurrencesOfString:@"%baseurl%" withString:[baseURL absoluteString] options:0 range:NSMakeRange(0, [htmlString length])];
	[htmlString replaceOccurrencesOfString:@"%opacity%" withString:opacityString options:0 range:NSMakeRange(0, [htmlString length])];
	[htmlString replaceOccurrencesOfString:@"%priority%" withString:priorityName options:0 range:NSMakeRange(0, [htmlString length])];
	[htmlString replaceOccurrencesOfString:@"growlimage://%image%" withString:cacheKey options:0 range:NSMakeRange(0, [htmlString length])];
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

- (void)webView:(WebView *)webView windowScriptObjectAvailable:(WebScriptObject *)windowScriptObject {
	[windowScriptObject setValue:self forKey:@"NotificationWindowController"];
	// Disable user text selection
	[webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserSelect='none';"];
	[webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.cursor='default';"];
}
- (id)invokeUndefinedMethodFromWebScript:(NSString *)name withArguments:(NSArray *)args
{	
	if([name isEqualToString:@"closeNote"])
	{
		GrowlWebKitWindowView *webView = [[self window] contentView];
		if([webView respondsToSelector:@selector(clickedCloseBox:)])
			[webView performSelector:@selector(clickedCloseBox:) withObject:nil];
		[webView stringByEvaluatingJavaScriptFromString:@"if (!e) var e = window.event; e.stopPropagation();"];
	}else if([name isEqualToString:@"clickNote"]){
		[self notificationClicked:nil];
	}
	return nil;
}

/*!
 * @brief Invoked once the webview has loaded and is ready to accept content
 */
- (void) webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	if (frame != [sender mainFrame]) return;

	if ([[[frame frameView] documentView] frame].size.height < 2.0f) {
		//Finished loading it may be, but it's not finished rendering, in which case the document view's height will be 1 px. Not good for sizing to fit. So, try again one cycle of the run loop from now.
		[self performSelector:@selector(viewIsReady:) 
					  withObject:sender 
					  afterDelay:0.0
						  inModes:[NSArray arrayWithObjects:NSRunLoopCommonModes, NSEventTrackingRunLoopMode, nil]];
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
	[myWindow invalidateShadow];
	
	[[GrowlDisplayBridgeController sharedController] windowReadyToStart:self];
}

- (void) setNotification:(GrowlNotification *)theNotification {
    if (notification == theNotification)
		return;

	[super setNotification:theNotification];

	// Extract the new details from the notification
	NSDictionary *noteDict = [notification dictionaryRepresentation];
	NSString *title = [notification title];
	NSString *text  = [notification notificationDescription];

	NSData *iconData = [noteDict objectForKey:GROWL_NOTIFICATION_ICON_DATA];
	if ([iconData isKindOfClass:[NSImage class]])
		iconData = [(NSImage *)iconData PNGRepresentation];
	
	int priority    = [[noteDict objectForKey:GROWL_NOTIFICATION_PRIORITY] intValue];

	NSPanel *panel = (NSPanel *)[self window];
	WebView *view = [panel contentView];
	[self setTitle:title text:text iconData:iconData priority:priority forView:view];
}

#pragma mark -
#pragma mark positioning methods

- (NSPoint) idealOriginInRect:(NSRect)rect {
	NSRect viewFrame = [[[self window] contentView] frame];
	NSDictionary *configDict = [[self notification] configurationDict];
	GrowlPositionOrigin	position = configDict ? [[configDict valueForKey:@"com.growl.positioncontroller.selectedposition"] intValue] : GrowlTopRightCorner;
	NSPoint idealOrigin;

	switch(position){
		case GrowlNoOrigin:
		case GrowlTopRightCorner:
			idealOrigin = NSMakePoint(NSMaxX(rect) - NSWidth(viewFrame) - paddingX,
									  NSMaxY(rect) - paddingY - NSHeight(viewFrame));
			break;
		case GrowlTopLeftCorner:
			idealOrigin = NSMakePoint(NSMinX(rect) + paddingX,
									  NSMaxY(rect) - paddingY - NSHeight(viewFrame));
			break;
		case GrowlBottomLeftCorner:
			idealOrigin = NSMakePoint(NSMinX(rect) + paddingX,
									  NSMinY(rect) + paddingY);
			break;
		case GrowlBottomRightCorner:
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

- (CGFloat) requiredDistanceFromExistingDisplays {
	return MAX(paddingX, paddingY);
}

@end

