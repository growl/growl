#import "GrowlProwlWebViewWindowController.h"

@interface GrowlProwlWebViewWindowController ()
@property (nonatomic, assign, readwrite) id<GrowlProwlWebViewWindowControllerDelegate> delegate;
@property (nonatomic, retain, readwrite) NSString *retrieveURL;

@property (nonatomic, assign) BOOL successful;
@end

@implementation GrowlProwlWebViewWindowController
@synthesize webView = _webView;
@synthesize progressIndicator = _progressIndicator;
@synthesize retrieveURL = _retrieveURL;
@synthesize successful = _successful;
@synthesize delegate = _delegate;

- (id)initWithURL:(NSString *)retrieveURL
		 delegate:(id<GrowlProwlWebViewWindowControllerDelegate>)delegate
{
	self = [super initWithWindowNibName:@"GrowlProwlWebViewWindowController"];
	if(self) {
		self.retrieveURL = retrieveURL;
		self.delegate = delegate;
	}
	return self;
}

- (void)dealloc
{
	[_webView close];
	[_retrieveURL release];
    [super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
}

- (void)showWindow:(id)sender
{
	[super showWindow:sender];
	[self.webView setMainFrameURL:self.retrieveURL];
	[self.progressIndicator startAnimation:nil];
}

- (void)windowWillClose:(NSNotification *)notification
{
	if(!self.successful) {
		[self.delegate webViewDidSucceed:self];
	}
}

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
	[self.progressIndicator startAnimation:nil];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	[self.progressIndicator stopAnimation:nil];
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	[self.delegate webView:self didFailWithError:error];
}

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation
		request:(NSURLRequest *)request
		  frame:(WebFrame *)frame
decisionListener:(id<WebPolicyDecisionListener>)listener
{
	if([request.URL.scheme isEqualToString:@"prowl"]) {
		self.successful = YES;
		[self.delegate webViewDidSucceed:self];
		[listener ignore];
	} else {
		[listener use];
	}
}

@end
