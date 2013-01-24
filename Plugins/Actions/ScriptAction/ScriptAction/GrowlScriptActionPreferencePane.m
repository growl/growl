//
//  GrowlScriptActionPreferencePane.m
//  ScriptAction
//
//  Created by Daniel Siemer on 10/8/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//
//  This class represents your plugin's preference pane.  There will be only one instance, but possibly many configurations
//  In order to access a configuration values, use the NSMutableDictionary *configuration for getting them. 
//  In order to change configuration values, use [self setConfigurationValue:forKey:]
//  This ensures that the configuration gets saved into the database properly.

#import "GrowlScriptActionPreferencePane.h"
#import <GrowlPlugins/GrowlUserScriptTaskUtilities.h>
#import <GrowlPlugins/GrowlDefines.h>

//These are to get them into the localizable strings file for ScriptAction
//Dont like this, but failing to think of the right solution right now
#define hostFake		NSLocalizedString(@"Host", @"Token display string for host")
#define appFake		NSLocalizedString(@"Application", @"Token display string for application name")
#define nameFake		NSLocalizedString(@"Name", @"Token display string for notification name")
#define titleFake		NSLocalizedString(@"Title", @"Token display string for notification title")
#define descFake		NSLocalizedString(@"Description", @"Token display string for notification description")
#define priorityFake NSLocalizedString(@"Priority", @"Token display string for notification priority")
#define stickyFake	NSLocalizedString(@"Sticky", @"Token display string for notification sticky")
#define iconFake		NSLocalizedString(@"Icon Data", @"Token display string for icon data")

@interface GrowlScriptActionPreferencePane ()

@property (nonatomic, assign) IBOutlet NSTableView	*actionsTableView;
@property (nonatomic, assign) IBOutlet NSTokenField *tokenField;
@property (nonatomic, retain) NSArray *actions;

@property (nonatomic, retain) NSString *scriptListTitle;
@property (nonatomic, retain) NSString *unixArgumentLabel;

-(void)setActionName:(NSString *)actionName;
-(NSString*)actionName;

@end

@implementation GrowlScriptActionPreferencePane

-(id)initWithBundle:(NSBundle *)bundle {
	if((self = [super initWithBundle:bundle])){
      self.scriptListTitle = NSLocalizedStringFromTableInBundle(@"Scripts", @"Localizable", bundle, @"List of scripts in the script action");
		self.unixArgumentLabel = NSLocalizedStringFromTableInBundle(@"UNIX Arguments", @"Localizable", bundle, @"Token field for UNIX arguments");
	}
	return self;
}

-(void)dealloc {
   self.actionName = nil;
	self.actions = nil;
	[_scriptListTitle release];
	_scriptListTitle = nil;
	[_unixArgumentLabel release];
	_unixArgumentLabel = nil;
	[super dealloc];
}

-(NSString*)mainNibName {
	return @"ScriptActionPrefPane";
}

/* This returns the set of keys the preference pane needs updated via bindings 
 * This is called by GrowlPluginPreferencePane when it has had its configuration swapped
 * Since we really only need a fixed set of keys updated, use dispatch_once to create the set
 */
- (NSSet*)bindingKeys {
	static NSSet *keys = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		keys = [[NSSet setWithObjects:@"actions", @"actionName", @"isUnixTask", nil] retain];
	});
	return keys;
}

/* This method is called when our configuration values have been changed 
 * by switching to a new configuration.  This is where we would update certain things
 * that are unbindable.  Call the super version in order to ensure bindingKeys is also called and used.
 * Uncomment the method to use.
 */

-(void)updateConfigurationValues {
	[self updateActionList];
	[super updateConfigurationValues];
	if((!self.actionName || ![self.actions containsObject:[self actionName]]) && [self.actions count] > 0){
		[self setActionName:[self.actions objectAtIndex:0U]];
	}
   [self.actionsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[self.actions indexOfObject:[self actionName]]]
                      byExtendingSelection:NO];
	NSArray *arguments = [self.configuration valueForKey:@"ScriptActionUnixArguments"];
	if(!arguments)
		arguments = [self defaultArgumentsArray];
	[self.tokenField setObjectValue:arguments];
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification	{
	NSInteger selectedRow = [self.actionsTableView selectedRow];
	if(selectedRow >= 0 && (NSUInteger)selectedRow < [self.actions count]){
		NSString *actionName = [self.actions objectAtIndex:selectedRow];
		if([[self actionName] caseInsensitiveCompare:actionName] != NSOrderedSame){
         if([self respondsToSelector:@selector(_setDisplayName:)]){
            [self performSelector:@selector(_setDisplayName:) withObject:actionName];
         }
			[self setActionName:actionName];
		}
	}
}

-(NSString*)actionName {
   return [self.configuration valueForKey:@"ScriptActionFileName"];
}

-(void)setActionName:(NSString *)newName {
	[self willChangeValueForKey:@"isUnixTask"];
   [self setConfigurationValue:newName forKey:@"ScriptActionFileName"];
	[self didChangeValueForKey:@"isUnixTask"];
}

-(void)updateActionList {
	NSMutableArray *actionNames = [NSMutableArray array];
	NSArray *contents = [GrowlUserScriptTaskUtilities contentsOfScriptDirectory];
	[contents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if(![[obj pathExtension] isEqualToString:@"workflow"] &&
			![[obj lastPathComponent] isEqualToString:@"Rules.scpt"])
		{
			[actionNames addObject:[obj lastPathComponent]];
		}
	}];
	self.actions = actionNames;
}

-(BOOL)isUnixTask {
	BOOL result = NO;
	if([self actionName]){
		NSUserScriptTask *task = [GrowlUserScriptTaskUtilities scriptTaskForFile:[self actionName]];
		if([task isKindOfClass:[NSUserUnixTask class]])
			result = YES;
	}
	return result;
}

#pragma mark Token field support

-(NSArray*)defaultArgumentsArray {
	static NSArray *_arguments = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_arguments = [@[@"GNTP Notification Sent-By",
						  GROWL_APP_NAME,
						  GROWL_NOTIFICATION_NAME,
						  GROWL_NOTIFICATION_TITLE,
						  GROWL_NOTIFICATION_DESCRIPTION,
						  GROWL_NOTIFICATION_PRIORITY,
						  GROWL_NOTIFICATION_STICKY,
						  GROWL_NOTIFICATION_ICON_DATA] retain];
	});
	return _arguments;
}
#define GrowlScriptActionLocalizedString(string,comment) NSLocalizedStringFromTableInBundle(string, @"Localizable", [NSBundle bundleForClass:[self class]], comment) 
-(NSDictionary*)keysToTokenDisplayStrings {
	static NSDictionary *_dict = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_dict = [@{@"GNTP Notification Sent-By" : GrowlScriptActionLocalizedString(@"Host", @"Token display string for host"),
					GROWL_APP_NAME : GrowlScriptActionLocalizedString(@"Application", @"Token display string for application name"),
					GROWL_NOTIFICATION_NAME : GrowlScriptActionLocalizedString(@"Name", @"Token display string for notification name"),
					GROWL_NOTIFICATION_TITLE : GrowlScriptActionLocalizedString(@"Title", @"Token display string for notification title"),
					GROWL_NOTIFICATION_DESCRIPTION : GrowlScriptActionLocalizedString(@"Description", @"Token display string for notification description"),
					GROWL_NOTIFICATION_PRIORITY : GrowlScriptActionLocalizedString(@"Priority", @"Token display string for notification priority"),
					GROWL_NOTIFICATION_STICKY : GrowlScriptActionLocalizedString(@"Sticky", @"Token display string for notification sticky"),
					GROWL_NOTIFICATION_ICON_DATA : GrowlScriptActionLocalizedString(@"Icon Data", @"Token display string for icon data")
					} retain];
	});
	return _dict;
}

- (id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString {
	__block NSString *result = nil;
	[[self keysToTokenDisplayStrings] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		if([obj caseInsensitiveCompare:editingString] == NSOrderedSame){
			result = [key retain];
		}
	}];
	return [result autorelease];
}

- (NSArray *)tokenField:(NSTokenField *)tokenField
completionsForSubstring:(NSString *)substring
			  indexOfToken:(NSInteger)tokenIndex
	 indexOfSelectedItem:(NSInteger *)selectedIndex
{
	NSMutableArray *result = [NSMutableArray array];
	[[[self keysToTokenDisplayStrings] allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if([obj rangeOfString:substring options:NSAnchoredSearch | NSCaseInsensitiveSearch].location != NSNotFound){
			[result addObject:obj];
		}
	}];
	[result sortUsingSelector:@selector(caseInsensitiveCompare:)];
	return result;
}

- (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject
{
	NSString *result = nil;
	NSDictionary *conversion = [self keysToTokenDisplayStrings];
	if([conversion valueForKey:representedObject])
		result = [conversion valueForKey:representedObject];
	return result;
}

- (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(NSUInteger)index
{
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:[tokens count]];
	[tokens enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if([[[self keysToTokenDisplayStrings] allKeys] containsObject:obj])
			[result addObject:obj];
	}];
	dispatch_async(dispatch_get_main_queue(), ^{
		[self saveArguments];
	});
	return result;
}

-(void)saveArguments {
	NSArray *tokens = [_tokenField objectValue];
	if(!tokens)
		tokens = [NSArray array];
	[self setConfigurationValue:tokens forKey:@"ScriptActionUnixArguments"];
}

@end
