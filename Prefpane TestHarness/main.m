
#import <Foundation/Foundation.h>
#import "PrefpaneTester.h"

int main(int argc, char *argv[]) {
#pragma unused(argc, argv)
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSApplication sharedApplication];

	PrefpaneTester *tester = [[PrefpaneTester alloc] init];

	[NSApp run];

	[tester release];
	[pool   release];

	return EXIT_SUCCESS;
}
