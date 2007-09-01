#import <Cocoa/Cocoa.h>
#import "PrefPaneOpener.h"

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	[PrefPaneOpener openPrefPane:@"Growl"];

    [pool release];
    return 0;
}
