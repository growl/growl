//
//  GrowlMailUUIDPatcherAppDelegate.m
//  GrowlMailUUIDPatcher
//
//  Created by Rudy Richter on 7/10/10.
//  Copyright 2010 Beware Reactor. All rights reserved.
//

#import "GrowlMailUUIDPatcherAppDelegate.h"

NSString *localGrowlMail = @"~/Library/Mail/Bundles/GrowlMail.mailbundle";
NSString *localDisabled = @"~/Library/Mail/Bundles (Disabled)/";
NSString *localDisabledGrowlMail = @"~/Library/Mail/Bundles (Disabled)/GrowlMail.mailbundle";
NSString *globalGrowlMail = @"/Library/Mail/Bundles/GrowlMail.mailbundle";
NSString *globalDisabledGrowlMail = @"/Library/Mail/Bundles (Disabled)/GrowlMail.mailbundle";
NSString *mailAppBundleID = @"com.apple.mail";

@implementation GrowlMailUUIDPatcherAppDelegate

@synthesize window;
@synthesize mailAppUUID;
@synthesize messageFrameworkUUID;
@synthesize	needsUpdate;
@synthesize status;
@synthesize paths;
@synthesize updateButton;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	
	self.paths = [self growlMailPaths];
	if([paths count])
	{
		[self getUUIDs];
		[self verify];
	}
	else 
	{
		[status setStringValue:@"You don't have GrowlMail installed."];
	}
	
}

- (void)dealloc
{
	//release our retained property values
	self.paths = nil;
	self.messageFrameworkUUID = nil;
	self.mailAppUUID = nil;
	
	[super dealloc];
}

- (void)getUUIDs
{
	NSBundle *appBundle = [NSBundle bundleWithPath:@"/Applications/Mail.app"];
	NSBundle *frameworkBundle = [NSBundle bundleWithPath:@"/System/Library/Frameworks/Message.framework"];
	
	self.mailAppUUID = [[appBundle infoDictionary] valueForKey:@"PluginCompatibilityUUID"];
	self.messageFrameworkUUID = [[frameworkBundle infoDictionary] valueForKey:@"PluginCompatibilityUUID"];
}

- (NSArray*)growlMailPaths
{
	NSMutableArray *result = [NSMutableArray array];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if([fileManager fileExistsAtPath:[localGrowlMail stringByExpandingTildeInPath]])
		[result addObject:[localGrowlMail stringByExpandingTildeInPath]];
	if([fileManager fileExistsAtPath:[localDisabled stringByExpandingTildeInPath]] && ![fileManager fileExistsAtPath:[localDisabledGrowlMail stringByExpandingTildeInPath]])
	{		
		NSString *disabled = [@"~/Library/Mail/Bundles (Disabled %ld)/" stringByExpandingTildeInPath];

		for(NSInteger i = 1; i < 20; i++)
		{
			NSString *disabledPath = [NSString stringWithFormat:disabled, i];
			NSString *disabledGrowlMailPath = [disabledPath stringByAppendingPathComponent:@"GrowlMail.mailBundle"];
			if([fileManager fileExistsAtPath:disabledPath] && [fileManager fileExistsAtPath:disabledGrowlMailPath])
				localDisabledGrowlMail = [disabledGrowlMailPath retain];
		}
	}
	
	if([fileManager fileExistsAtPath:[localDisabledGrowlMail stringByExpandingTildeInPath]])
		[result addObject:[localDisabledGrowlMail stringByExpandingTildeInPath]];
	if([fileManager fileExistsAtPath:globalGrowlMail])
		[result addObject:globalGrowlMail];
	if([fileManager fileExistsAtPath:globalDisabledGrowlMail])
		[result addObject:globalDisabledGrowlMail];
	
	return result;
}

- (void)verify
{
	for(NSString *path in paths)
	{
		if(![self checkPlist:path])
		{
			NSString *update = [needsUpdate stringValue];
			update = [update stringByAppendingString:[NSString stringWithFormat:@"%@ needs to be updated\n", path]];
			[needsUpdate setStringValue:update];
		}
	}
	
	if(![[needsUpdate stringValue] length])
	{
		[updateButton setEnabled:NO];
		for(NSString *path in paths)
		{
			NSString *update = [needsUpdate stringValue];
			update = [update stringByAppendingString:[NSString stringWithFormat:@"%@ is up to date\n", path]];
			[needsUpdate setStringValue:update];
		}
	}
}

- (BOOL)checkPlist:(NSString*)path
{
	NSBundle *mailBundle = [NSBundle bundleWithPath:path];
	
	BOOL hasApp = NO;
	BOOL hasFramework = NO;
	
	NSArray *uuidArray = [[mailBundle infoDictionary] objectForKey:@"SupportedPluginCompatibilityUUIDs"];
	
	for(NSString *uuid in uuidArray)
	{
		if([uuid isEqualToString:self.mailAppUUID])
			hasApp = YES;
		if([uuid isEqualToString:self.messageFrameworkUUID])
			hasFramework = YES;
	}
	
	return (hasApp && hasFramework);
}

- (IBAction)updatePlist:(id)sender
{
	for(NSString *path in paths)
	{		
		NSString *plistPath = [[[path stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Info.plist"] stringByExpandingTildeInPath];
		NSMutableDictionary *infoDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
		
		NSMutableArray *newUUIDs = [[[infoDictionary objectForKey:@"SupportedPluginCompatibilityUUIDs"] mutableCopy] autorelease];
		if(!newUUIDs)
			newUUIDs = [NSMutableArray array];
		
		if(![newUUIDs containsObject:self.mailAppUUID])
			[newUUIDs addObject:self.mailAppUUID];
		if(![newUUIDs containsObject:self.messageFrameworkUUID])
			[newUUIDs addObject:self.messageFrameworkUUID];
		
		[infoDictionary setObject:newUUIDs forKey:@"SupportedPluginCompatibilityUUIDs"];
		BOOL success = [infoDictionary writeToFile:plistPath atomically:YES];
		
		if(success)
		{
			NSError *error = nil;
			if([path isEqualTo:[localDisabledGrowlMail stringByExpandingTildeInPath]])
				[[NSFileManager defaultManager] moveItemAtPath:path toPath:[localGrowlMail stringByExpandingTildeInPath] error:&error];
			if([path isEqualToString:globalDisabledGrowlMail])
				[[NSFileManager defaultManager] moveItemAtPath:path toPath:globalGrowlMail error:&error];
			
			if(!error && [self mailIsRunning])
				if([[NSAlert alertWithMessageText:@"GrowlMail has been updated" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"GrowlMail has been updated, relaunch Mail.app now."] runModal] == NSAlertDefaultReturn)
					[self relaunchMail];
		}
	}
}

- (BOOL)mailIsRunning
{
	BOOL result = NO;
	NSArray *applications = [[NSWorkspace sharedWorkspace] runningApplications];
	for(NSRunningApplication *application in applications)
	{
		if([[application bundleIdentifier] isEqualToString:mailAppBundleID])
		{	
			result = YES;
			break;
		}
	}
	return result;
}

- (void)relaunchMail
{
	NSArray *applications = [[NSWorkspace sharedWorkspace] runningApplications];
	for(NSRunningApplication *application in applications)
	{
		if([[application bundleIdentifier] isEqualToString:mailAppBundleID])
		{	
			[application retain];
			[application addObserver:self forKeyPath:@"terminated" options:NSKeyValueObservingOptionNew context:self];
			if([application terminate])
			{
				[application removeObserver:self forKeyPath:@"terminated"];
				[application release];
				[[NSWorkspace sharedWorkspace] performSelector:@selector(launchApplication:) withObject:@"Mail.app" afterDelay:2.0f];
			}
		}
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if([keyPath isEqualToString:@"terminated"])
	{
		[object removeObserver:self forKeyPath:@"terminated"];
		[[NSWorkspace sharedWorkspace] openURL:[object bundleURL]];
		[object release];
	}
}
@end
