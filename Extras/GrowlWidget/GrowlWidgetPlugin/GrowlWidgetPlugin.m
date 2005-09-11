#import "GrowlWidgetPlugin.h"
#import "GrowlImageURLProtocol.h"
#import <GrowlDefines.h>
#import <WebKit/WebKit.h>
#include "CFMutableStringAdditions.h"

/*********************************************/
// The implementation of the widget plugin follows...
/*********************************************/

@implementation GrowlWidgetPlugin

/*********************************************/
// Methods required by the WidgetPlugin protocol
/*********************************************/

// initWithWebView
//
// This method is called when the widget plugin is first loaded as the
// widget's web view is first initialized
- (id) initWithWebView:(WebView *)w {
	webView = [w retain];
	if ((self = [super init])) {
		NSDistributedNotificationCenter *dnc = [NSDistributedNotificationCenter defaultCenter];
		[dnc addObserver:self
				selector:@selector(growlIsReady:)
					name:GROWL_IS_READY
				  object:nil];
		[self subscribeToGrowlNotificationCenter];
	}
	return self;
}

- (void) dealloc {
	[growlNotificationCenter removeObserver:self];
	[image   release];
	[webView release];
	[super dealloc];
}

/*********************************************/
// Methods required by the WebScripting protocol
/*********************************************/

// windowScriptObjectAvailable
//
// This method gives you the object that you use to bridge between the
// Obj-C world and the JavaScript world.  Use setValue:forKey: to give
// the object the name it's refered to in the JavaScript side.
- (void) windowScriptObjectAvailable:(WebScriptObject *)wso {
	[wso setValue:self forKey:@"GrowlPlugin"];
}

// webScriptNameForSelector
//
// This method lets you offer friendly names for methods that normally
// get mangled when bridged into JavaScript.
+ (NSString *) webScriptNameForSelector:(SEL)aSel {
#pragma unused(aSel)
	NSLog(@"\tunknown selector");
	return nil;
}

// isSelectorExcludedFromWebScript
//
// This method lets you filter which methods in your plugin are accessible
// to the JavaScript side.
+ (BOOL) isSelectorExcludedFromWebScript:(SEL)aSel {
#pragma unused(aSel)
	return YES;
}

// isKeyExcludedFromWebScript
//
// Prevents direct key access from JavaScript.
+ (BOOL) isKeyExcludedFromWebScript:(const char *)key {
#pragma unused(key)
	return YES;
}

#pragma mark -

- (void) subscribeToGrowlNotificationCenter {
	@try {
		NSConnection *connection = [NSConnection connectionWithRegisteredName:@"GrowlNotificationCenter" host:nil];
		NSDistantObject *theProxy = [connection rootProxy];
		[theProxy setProtocolForProxy:@protocol(GrowlNotificationCenterProtocol)];
		growlNotificationCenter = (id<GrowlNotificationCenterProtocol>)theProxy;
		[growlNotificationCenter addObserver:self];
	} @catch(NSException *e) {
		NSLog(@"Failed to subscribe to GrowlNotificationCenter: %@", e);
	}
}

- (void) growlIsReady:(NSNotification *)notification {
#pragma unused(notification)
	[self subscribeToGrowlNotificationCenter];
}

- (void) notifyWithDictionary:(NSDictionary *)userInfo {
	[image release];
	// TODO: find out why this doesn't work ([NSImage imageNamed] returns nil)
	//image = [[userInfo objectForKey:GROWL_NOTIFICATION_ICON] copy];
	// WORKAROUND:
	image = [[NSImage alloc] initWithData:[[userInfo objectForKey:GROWL_NOTIFICATION_ICON] TIFFRepresentation]];

	NSString *UUID = [[NSProcessInfo processInfo] globallyUniqueString];
	[image setName:UUID];
	[GrowlImageURLProtocol class];	// make sure GrowlImageURLProtocol is +initialized

	int priority = [[userInfo objectForKey:GROWL_NOTIFICATION_PRIORITY] intValue];
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

	BOOL titleIsHTML;
	BOOL textIsHTML;
	CFStringRef titleHTML = (CFStringRef)[userInfo objectForKey:GROWL_NOTIFICATION_TITLE_HTML];
	if (titleHTML)
		titleIsHTML = YES;
	else {
		titleIsHTML = NO;
		titleHTML = (CFStringRef)[userInfo objectForKey:GROWL_NOTIFICATION_TITLE];
		if (titleHTML)
			titleHTML = createStringByEscapingForHTML(titleHTML);
	}
	CFStringRef textHTML = (CFStringRef)[userInfo objectForKey:GROWL_NOTIFICATION_DESCRIPTION_HTML];
	if (textHTML)
		textIsHTML = YES;
	else {
		textIsHTML = NO;
		textHTML = (CFStringRef)[userInfo objectForKey:GROWL_NOTIFICATION_DESCRIPTION];
		if (textHTML)
			textHTML = createStringByEscapingForHTML(textHTML);
	}

	NSMutableString *content = [[NSMutableString alloc] initWithFormat:@"<span class=\"%@\"><div class=\"icon\"><img src=\"growlimage://%@\" alt=\"icon\" /></div><div class=\"title\">%@</div><div class=\"text\">%@</div></span>",
		priorityName,
		UUID,
		titleHTML ? titleHTML : CFSTR(""),
		textHTML ? textHTML : CFSTR("")];
	if (titleHTML && !titleIsHTML)
		CFRelease(titleHTML);
	if (textHTML && !textIsHTML)
		CFRelease(textHTML);
	NSString *newMessage = [[NSString alloc] initWithFormat:@"setMessage(\"%@\");",
		escapeForJavaScript((CFMutableStringRef)content)];
	[content release];
	[webView stringByEvaluatingJavaScriptFromString:newMessage];
	[newMessage release];
}

@end
