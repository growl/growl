#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class PRWebViewWindowController;
@protocol PRWebViewWindowControllerDelegate <NSObject>
- (void)webView:(PRWebViewWindowController *)webView didFailWithError:(NSError *)error;
- (void)webViewDidSucceed:(PRWebViewWindowController *)webView;
@end

@interface PRWebViewWindowController : NSWindowController
@property (assign) IBOutlet WebView *webView;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;

- (id)initWithURL:(NSString *)retrieveURL
		 delegate:(id<PRWebViewWindowControllerDelegate>)delegate;
@property (nonatomic, assign, readonly) id<PRWebViewWindowControllerDelegate> delegate;
@property (nonatomic, retain, readonly) NSString *retrieveURL;

@end
