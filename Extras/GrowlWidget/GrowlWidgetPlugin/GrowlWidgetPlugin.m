#import "GrowlWidgetPlugin.h"
#import "GrowlImageURLProtocol.h"
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

/*!
 * @brief Escape a string for passing to our BOM scripts
 */
- (NSMutableString *) escapeStringForPassingToScript:(NSMutableString *)inString {
	NSRange range = NSMakeRange(0, [inString length]);
	unsigned delta;
	//We need to escape a few things to get our string to the javascript without trouble
	delta = [inString replaceOccurrencesOfString:@"\\" withString:@"\\\\"
										 options:NSLiteralSearch range:range];
	range.length += delta;

	delta = [inString replaceOccurrencesOfString:@"\"" withString:@"\\\""
											 options:NSLiteralSearch range:range];
	range.length += delta;

	delta = [inString replaceOccurrencesOfString:@"\n" withString:@""
										 options:NSLiteralSearch range:range];
	range.length -= delta;

	delta = [inString replaceOccurrencesOfString:@"\r" withString:@"<br />"
										 options:NSLiteralSearch range:range];
	enum { lengthOfBRString = 6 };
	range.length += delta * lengthOfBRString;

	return inString;
}

- (void) gotGrowlNotification:(NSNotification *)notification {
	NSDictionary *userInfo = [notification userInfo];

	NSImage *image = [[NSImage alloc] initWithData:[userInfo objectForKey:GROWL_NOTIFICATION_ICON]];
	NSString *UUID = [[NSProcessInfo processInfo] globallyUniqueString];
	[image setName:UUID];
	[GrowlImageURLProtocol class];	// make sure GrowlImageURLProtocol is +initialized
	[image autorelease];

	NSMutableString *content = [[NSMutableString alloc] initWithFormat:@"<span><div class=\"icon\"><img src=\"growlimage://%@\" alt=\"icon\" /></div><div class=\"title\">%@</div><div class=\"text\">%@</div></span>",
		UUID,
		[userInfo objectForKey:GROWL_NOTIFICATION_TITLE],
		[userInfo objectForKey:GROWL_NOTIFICATION_DESCRIPTION]];
	[self escapeStringForPassingToScript:content];
	NSString *newMessage = [[NSString alloc] initWithFormat:@"setMessage(\"%@\");",
		content];
	[webView stringByEvaluatingJavaScriptFromString:newMessage];
	[content release];
	[newMessage release];
}

@end
