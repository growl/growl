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

@interface GrowlScriptActionPreferencePane ()

@property (nonatomic, assign) IBOutlet NSTableView	*actionsTableView;
@property (nonatomic, retain) NSArray *actions;
-(void)setActionName:(NSString *)actionName;
-(NSString*)actionName;

@end

@implementation GrowlScriptActionPreferencePane

-(id)initWithBundle:(NSBundle *)bundle {
	if((self = [super initWithBundle:bundle])){
      
	}
	return self;
}

-(void)dealloc {
   self.actionName = nil;
	self.actions = nil;
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
		keys = [[NSSet setWithObjects:@"actions", @"actionName", nil] retain];
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
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification	{
	NSInteger selectedRow = [self.actionsTableView selectedRow];
	if(selectedRow >= 0 && (NSUInteger)selectedRow < [self.actions count]){
		NSString *actionName = [self.actions objectAtIndex:selectedRow];
		if([[self actionName] caseInsensitiveCompare:actionName] != NSOrderedSame){
         if([self respondsToSelector:@selector(pluginConfiguration)]){
            NSManagedObject *pluginConfiguration = [self performSelector:@selector(pluginConfiguration)];
            [pluginConfiguration setValue:actionName forKey:@"displayName"];
         }
			[self setActionName:actionName];
		}
	}
}

-(NSString*)actionName {
   return [self.configuration valueForKey:@"ScriptActionFileName"];
}

-(void)setActionName:(NSString *)newName {
   [self setConfigurationValue:newName forKey:@"ScriptActionFileName"];
}

-(NSURL*)baseScriptDirectoryURL {
   NSError *urlError = nil;
   NSURL *baseURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationScriptsDirectory
                                                           inDomain:NSUserDomainMask
                                                  appropriateForURL:nil
                                                             create:YES
                                                              error:&urlError];
   if(urlError){
      static dispatch_once_t onceToken;
      dispatch_once(&onceToken, ^{
         NSLog(@"Error retrieving Application Scripts directoy, %@", urlError);
      });
   }
   return urlError ? nil : baseURL;
}

-(void)updateActionList {
	NSMutableArray *actionNames = [NSMutableArray array];
	
   NSURL *scriptURL = [self baseScriptDirectoryURL];
   if(scriptURL){
      NSError *error = nil;
      NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:scriptURL
                                                        includingPropertiesForKeys:nil
                                                                           options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                             error:&error];
      if(!error){
         [contents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if(![[obj pathExtension] isEqualToString:@"workflow"] &&
               ![[obj lastPathComponent] isEqualToString:@"Rules.scpt"])
            {
               [actionNames addObject:[obj lastPathComponent]];
            }
         }];
      }else{
         NSLog(@"Unable to get contents, %@", error);
      }
   }
   
	self.actions = actionNames;
}


@end
