//
//  PrefPaneOpener.m
//  OpenGrowlPrefPane
//
//  Created by Evan Schoenberg on 9/1/07.
//

#import "PrefPaneOpener.h"
#import "AEVTBuilder.h"

@implementation PrefPaneOpener

+ (void)openPrefPane:(NSString *)preferencePaneName
{
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
										   [KEY : 'seld'], [STRING  : preferencePaneName],
										   [KEY : 'from'], [DESC null],
										   ENDRECORD],
										  ENDRECORD];
	[descriptor sendWithImmediateReply];	
}

@end
