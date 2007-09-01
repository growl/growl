//
//  PrefPaneOpener.m
//  OpenGrowlPrefPane
//
//  Created by Evan Schoenberg on 9/1/07.
//

#import "PrefPaneOpener.h"
#import "AEVTBuilder.h"

/*!
 * @class PrefPaneOpener
 * @brief Opens a specified preference pane in the System Preferences
 *
 * This is equivalent to the applescript:
 *		tell application "System Preferences" to set current pane to pane "preferencePaneName"
 * except it works with any localization, not just English.  Applescript has no way of talking to an application
 * with a specified bundle ID.
 */
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
	
	/* tell application "System Preferences" to set current pane to pane "preferencePaneName" */
	NSAppleEventDescriptor *descriptor = [AEVT class:'core' id:'setd'
											  target:psn,
										  [KEY : 'data'],
										  [RECORD : 'obj ',
										   [KEY : 'form'], [ENUM : 'name'],
										   [KEY : 'want'], [TYPE : 'xppb'],
										   [KEY : 'seld'], [STRING  : preferencePaneName],
										   [KEY : 'from'], [DESC null],
										   ENDRECORD],
										  [KEY : '----'],
										  [RECORD : 'obj ',
										   [KEY : 'form'], [ENUM : 'prop'],
										   [KEY : 'want'], [TYPE : 'prop'],
										   [KEY : 'seld'], [TYPE  : 'xpcp'],
										   [KEY : 'from'], [DESC null],
										   ENDRECORD],
										   ENDRECORD];
	[descriptor sendWithImmediateReply];	
}

@end
