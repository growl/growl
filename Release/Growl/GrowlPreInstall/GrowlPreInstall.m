#import <Cocoa/Cocoa.h>
#import "AEVTBuilder.h"

@interface NSWorkspace (ProcessSerialNumberFinder)
- (ProcessSerialNumber)processSerialNumberForApplicationWithIdentifier:(NSString *)identifier;
@end

@implementation NSWorkspace (ProcessSerialNumberFinder)
- (ProcessSerialNumber)processSerialNumberForApplicationWithIdentifier:(NSString *)identifier
{
	ProcessSerialNumber psn = {0, 0};

	NSEnumerator *enumerator = [[self launchedApplications] objectEnumerator];
	NSDictionary *dict;
	while ((dict = [enumerator nextObject])) {
		if ([[dict objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:identifier]) {
			psn.highLongOfPSN = [[dict objectForKey:@"NSApplicationProcessSerialNumberHigh"] longValue];
			psn.lowLongOfPSN  = [[dict objectForKey:@"NSApplicationProcessSerialNumberLow"] longValue];
			break;
		}
	}
	
	return psn;
}
@end

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	NSAppleEventDescriptor *descriptor;
	/* tell application "System Preferences" to quit. The name may be localized, so we can't use applescript directly. */
	descriptor = [AEVT class:kCoreEventClass id:kAEQuitApplication
					  target:[[NSWorkspace sharedWorkspace] processSerialNumberForApplicationWithIdentifier:@"com.apple.systempreferences"],
				  ENDRECORD];
	[descriptor sendWithImmediateReplyWithTimeout:5];	

	/* tell application "GrowlHelperApp" to quit */
	[NSTask launchedTaskWithLaunchPath:@"/usr/bin/killall" arguments:[NSArray arrayWithObject:@"GrowlHelperApp"]];
	[NSTask launchedTaskWithLaunchPath:@"/usr/bin/killall" arguments:[NSArray arrayWithObject:@"GrowlMenu"]];

	/* delete old Growl installations */
	[[NSFileManager defaultManager] removeFileAtPath:[[[NSHomeDirectory()
														stringByAppendingPathComponent:@"Library"]
													   stringByAppendingPathComponent:@"PreferencePanes"] 
													  stringByAppendingPathComponent:@"Growl.prefPane"] handler:nil];

	/* We'll be running sudo'd from the installer, so this will have appropriate permissions */
	[[NSFileManager defaultManager] removeFileAtPath:@"/Library/PreferencePanes/Growl.prefPane" handler:nil];
	

    [pool release];
    return 0;
}
