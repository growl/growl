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
	OSType cSysPrefsPane = 'xppb';
	OSType keySysPrefsCurrentPane = 'xpcp';
	NSAppleEventDescriptor *descriptor = [AEVT class:kCoreEventClass id:kAESetData
											  target:psn,
										  [KEY : keyAEData],
										  [RECORD : cObjectSpecifier,
										   [KEY : keyAEKeyForm],      [ENUM : formName],
										   [KEY : keyAEDesiredClass], [TYPE : cSysPrefsPane],
										   [KEY : keyAEKeyData],      [STRING : preferencePaneName],
										   [KEY : keyAEContainer],    [DESC null],
										   ENDRECORD],
										  [KEY : keyDirectObject],
										  [RECORD : cObjectSpecifier,
										   [KEY : keyAEKeyForm],      [ENUM : formPropertyID],
										   [KEY : keyAEDesiredClass], [TYPE : cProperty],
										   [KEY : keyAEKeyData],      [TYPE : keySysPrefsCurrentPane],
										   [KEY : keyAEContainer],    [DESC null],
										   ENDRECORD],
										   ENDRECORD];
	[descriptor sendWithImmediateReply];	
}

@end
