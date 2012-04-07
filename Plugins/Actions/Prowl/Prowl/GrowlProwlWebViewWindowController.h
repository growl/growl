#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class GrowlProwlWebViewWindowController;
@protocol GrowlProwlWebViewWindowControllerDelegate <NSObject>
- (void)webView:(GrowlProwlWebViewWindowController *)webView didFailWithError:(NSError *)error;
- (void)webViewDidSucceed:(GrowlProwlWebViewWindowController *)webView;
@end

@interface GrowlProwlWebViewWindowController : NSWindowController
@property (assign) IBOutlet WebView *webView;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;

- (id)initWithURL:(NSString *)retrieveURL
		 delegate:(id<GrowlProwlWebViewWindowControllerDelegate>)delegate;
@property (nonatomic, assign, readonly) id<GrowlProwlWebViewWindowControllerDelegate> delegate;
@property (nonatomic, retain, readonly) NSString *retrieveURL;

@end
