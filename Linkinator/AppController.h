/* AppController */

#import <Cocoa/Cocoa.h>

@interface AppController : NSObject
{
	NSURL	*docsURL;
	NSURL	*versionURL;
	NSURL	*moreStylesURL;
}

- (IBAction)docsURL:(id)sender;
- (IBAction)versionURL:(id)sender;
- (IBAction)moreStylesURL:(id)sender;


@end
