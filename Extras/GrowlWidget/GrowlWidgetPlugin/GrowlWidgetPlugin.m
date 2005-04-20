#import "GrowlWidgetPlugin.h"
#import "GrowlImageURLProtocol.h"
#import "NSMutableStringAdditions.h"
#import <GrowlDefines.h>
#import <WebKit/WebKit.h>

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
				selector:@selector(gotGrowlNotification:)
					name:GROWL_DASHBOARD_NOTIFICATION
				  object:nil];
	}
	return self;
}

- (void) dealloc {
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

- (void) gotGrowlNotification:(NSNotification *)notification {
	NSDictionary *userInfo = [notification userInfo];

	[image release];
	image = [[NSImage alloc] initWithData:[userInfo objectForKey:GROWL_NOTIFICATION_ICON]];
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

	NSMutableString *titleHTML = [[[NSMutableString alloc] initWithString:[userInfo objectForKey:GROWL_NOTIFICATION_TITLE]] escapeForHTML];
	NSMutableString *textHTML = [[[NSMutableString alloc] initWithString:[userInfo objectForKey:GROWL_NOTIFICATION_DESCRIPTION]] escapeForHTML];
	NSMutableString *content = [[NSMutableString alloc] initWithFormat:@"<span class=\"%@\"><div class=\"icon\"><img src=\"growlimage://%@\" alt=\"icon\" /></div><div class=\"title\">%@</div><div class=\"text\">%@</div></span>",
		priorityName,
		UUID,
		titleHTML,
		textHTML];
	[titleHTML release];
	[textHTML release];
	NSString *newMessage = [[NSString alloc] initWithFormat:@"setMessage(\"%@\");",
		[content escapeForJavaScript]];
	[webView stringByEvaluatingJavaScriptFromString:newMessage];
	[content release];
	[newMessage release];
}

@end
