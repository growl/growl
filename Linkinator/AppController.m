#import "AppController.h"


@implementation AppController

#pragma mark Whee

- (void) awakeFromNib {
	
	
	docsURL = [[NSURL alloc] initWithString:@"http://growl.info/documentation/"];
	versionURL = [[NSURL alloc] initWithString:@"http://growl.info/documentation/version_history.php"];
	moreStylesURL = [[NSURL alloc] initWithString:@"http://resexcellence.com/growl/"];
	[NSApp setDelegate:self];
}

#pragma mark Destroy when done

- (void) dealloc {
	[docsURL release];
	[versionURL release];
	[moreStylesURL release];
	[super dealloc];
}

#pragma mark NSWorkspace button launching stuff
- (IBAction)docsURL:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:docsURL];
}

- (IBAction)versionURL:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:versionURL];
}

- (IBAction)moreStylesURL:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:moreStylesURL];
}


#pragma mark Quit on close

-(BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}



@end
