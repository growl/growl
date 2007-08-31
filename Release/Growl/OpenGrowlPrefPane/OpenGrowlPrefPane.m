#import <Cocoa/Cocoa.h>
#import "AEVTBuilder.h"

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	ProcessSerialNumber psn;
	
	[[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.apple.systempreferences"
														 options:NSWorkspaceLaunchWithoutAddingToRecents
								  additionalEventParamDescriptor:nil
												launchIdentifier:NULL];

	NSEnumerator *enumerator = [[[NSWorkspace sharedWorkspace] launchedApplications] objectEnumerator];
	NSDictionary *dict;
	while ((dict = [enumerator nextObject])) {
		if ([[dict objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:@"com.apple.systempreferences"]) {
			psn.highLongOfPSN = [[dict objectForKey:@"NSApplicationProcessSerialNumberHigh"] longValue];
			psn.lowLongOfPSN  = [[dict objectForKey:@"NSApplicationProcessSerialNumberLow"] longValue];
			break;
		}
	}

	NSAppleEventDescriptor *descriptor = [AEVT class:'misc' id:'mvis'
											  target:psn,
										  [KEY : '----'],
										  [RECORD : 'obj ',
											[KEY : 'form'], [ENUM : 'name'],
											[KEY : 'want'], [TYPE : 'xppb'],
											[KEY : 'seld'], [STRING  : @"Growl"],
											[KEY : 'from'], [DESC null],
											ENDRECORD],
										  ENDRECORD];
	[descriptor sendWithImmediateReply];

    [pool release];
    return 0;
}
