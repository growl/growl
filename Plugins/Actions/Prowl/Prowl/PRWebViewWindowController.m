#import "PRWebViewWindowController.h"
#import "PRDefines.h"

@interface PRWebViewWindowController ()
@property (nonatomic, assign, readwrite) id<PRWebViewWindowControllerDelegate> delegate;
@property (nonatomic, retain, readwrite) NSString *retrieveURL;

@property (nonatomic, assign) BOOL successful;
@end

@implementation PRWebViewWindowController
@synthesize webView = _webView;
@synthesize progressIndicator = _progressIndicator;
@synthesize retrieveURL = _retrieveURL;
@synthesize successful = _successful;
@synthesize delegate = _delegate;

- (id)initWithURL:(NSString *)retrieveURL
		 delegate:(id<PRWebViewWindowControllerDelegate>)delegate
{
	self = [super initWithWindowNibName:@"PRWebViewWindowController"];
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
	
	self.window.title = PRLocalizedString(@"Prowl Login", "The title for the window where the user enters their Prowl credentials to create generate API key.");
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
