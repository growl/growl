#import <Cocoa/Cocoa.h>
#import "PrefPaneOpener.h"

int main (int argc, const char * argv[]) {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSArray	*arguments = [[NSProcessInfo processInfo] arguments];
	if ([arguments count] < 2) {
		/* First argument is the path to the executable */
		printf("Specify the name of the preference pane to open.");
		[pool release];
		return -1;
	}
	
	NSString *preferencePaneName = [arguments objectAtIndex:1];
	[PrefPaneOpener openPrefPane:preferencePaneName];

    [pool release];
    return 0;
}
