//
//  GrowlMailUUIDPatcherAppDelegate.m
//  GrowlMailUUIDPatcher
//
//  Created by Rudy Richter on 7/10/10.
//  Copyright 2010 Beware Reactor. All rights reserved.
//

#import "GrowlMailUUIDPatcherAppDelegate.h"

NSString *localGrowlMail = @"~/Library/Mail/Bundles/GrowlMail.mailbundle";
NSString *localDisabledGrowlMail = @"~/Library/Mail/Bundles (Disabled)/GrowlMail.mailbundle";
NSString *globalGrowlMail = @"/Library/Mail/Bundles/GrowlMail.mailbundle";
NSString *globalDisabledGrowlMail = @"/Library/Mail/Bundles (Disabled)/GrowlMail.mailbundle";

@implementation GrowlMailUUIDPatcherAppDelegate

@synthesize window;
@synthesize mailAppUUID;
@synthesize messageFrameworkUUID;
@synthesize	needsUpdate;
@synthesize status;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	
	NSArray *paths = [self growlMailPaths];
	if([paths count])
	{
		[self getUUIDs];
		[self verify:paths];
	}
	else 
	{
		[status setStringValue:@"You don't have GrowlMail installed."];
	}
	
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
		[result addObject:localGrowlMail];
	if([fileManager fileExistsAtPath:localDisabledGrowlMail])
		[result addObject:globalGrowlMail];
	if([fileManager fileExistsAtPath:globalGrowlMail])
		[result addObject:globalGrowlMail];
	if([fileManager fileExistsAtPath:globalDisabledGrowlMail])
		[result addObject:globalGrowlMail];
	
	return result;
}

- (void)verify:(NSArray*)paths
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
	NSArray *paths = [self growlMailPaths];	
	for(NSString *path in paths)
	{		
		NSString *plistPath = [[[path stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Info.plist"] stringByExpandingTildeInPath];
		NSMutableDictionary *infoDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
		
		NSMutableArray *newUUIDs = [[[infoDictionary objectForKey:@"SupportedPluginCompatibilityUUIDs"] mutableCopy] autorelease];
		if(![newUUIDs containsObject:self.mailAppUUID])
			[newUUIDs addObject:self.mailAppUUID];
		if(![newUUIDs containsObject:self.messageFrameworkUUID])
			[newUUIDs addObject:self.messageFrameworkUUID];
		
		[infoDictionary setObject:newUUIDs forKey:@"SupportedPluginCompatibilityUUIDs"];
		[infoDictionary writeToFile:plistPath atomically:YES];
	}
}
@end
