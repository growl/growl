#import "PrefpaneTester.h"
#import <PreferencePanes/PreferencePanes.h>
#import "generatedBuildPath.h"

@implementation PrefpaneTester

- (void) dealloc {
	[prefPaneObject release];
	[super dealloc];
}

- (void) windowWillClose:(NSNotification *)aNotification {
#pragma unused(aNotification)
	[NSApp terminate:self];
}

- (id) init {
	NSRect aRect;
	NSBundle *prefBundle;
	Class prefPaneClass;
	NSView *prefView;

	if ((self = [super init])) {
		prefBundle = [NSBundle bundleWithPath: GROWL_OBJROOT @"/Growl.prefPane"];

		prefPaneClass = [prefBundle principalClass];
		prefPaneObject = [[prefPaneClass alloc] initWithBundle:prefBundle];

		if ([prefPaneObject loadMainView]) {
			[prefPaneObject willSelect];
			prefView = [prefPaneObject mainView];

			aRect = [prefView frame];
			aRect.origin = NSZeroPoint;
			theWindow = [[NSWindow alloc] initWithContentRect:aRect
													styleMask:NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask|NSResizableWindowMask
													  backing:NSBackingStoreBuffered
														defer:YES];
			[theWindow setDelegate:self];
			[theWindow setContentView:prefView];
			[prefPaneObject didSelect];
			[theWindow makeKeyAndOrderFront:self];
		} else {
			/* loadMainView failed -- handle error */
			NSLog(@"PrefpaneTester -  Error in loadMainView:");
		}
	}

	return self;
}
@end
