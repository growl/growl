//
//  HWGrowlPluginController.m
//  HardwareGrowler
//
//  Created by Daniel Siemer on 5/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "HWGrowlPluginController.h"

@interface HWGrowlPluginController ()

@property (nonatomic, retain) NSMutableArray *notifiers;
@property (nonatomic, retain) NSMutableArray *monitors;

@end

@implementation HWGrowlPluginController

@synthesize plugins;
@synthesize notifiers;
@synthesize monitors;

-(void)dealloc {
	[plugins release];
	[super dealloc];
}

-(id)init {
	if((self = [super init])){
		self.plugins = [NSMutableArray array];
		self.notifiers = [NSMutableArray array];
		self.monitors = [NSMutableArray array];
		[self loadPlugins];
		
		[GrowlApplicationBridge setGrowlDelegate:self];
		[GrowlApplicationBridge setShouldUseBuiltInNotifications:YES];
		
		if([[NSUserDefaults standardUserDefaults] boolForKey:@"OnLogin"])
			[self fireOnLaunchNotes];
	}
	return self;
}

-(void)loadPlugins {
	NSString *pluginsPath = [[NSBundle mainBundle] builtInPlugInsPath];
	NSArray *pluginBundles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:pluginsPath 
																										  error:nil];
	if(pluginBundles) {
		__block HWGrowlPluginController *blockSelf = self;
		[pluginBundles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			BOOL success = NO;
			NSString *bundlePath = [pluginsPath stringByAppendingPathComponent:obj];
			NSBundle *pluginBundle = [NSBundle bundleWithPath:bundlePath];
			if(pluginBundle && [pluginBundle load]){
				id plugin = [[[pluginBundle principalClass] alloc] init];
				if(plugin){ 
					if([plugin conformsToProtocol:@protocol(HWGrowlPluginProtocol)]){
						success = YES;
						[plugin setDelegate:self];
						[blockSelf.plugins addObject:plugin];
						if([plugin conformsToProtocol:@protocol(HWGrowlPluginNotifierProtocol)])
							[blockSelf.notifiers addObject:plugin];
						if([plugin conformsToProtocol:@protocol(HWGrowlPluginMonitorProtocol)])
							[blockSelf.monitors addObject:plugin];
						
					}else{
						NSLog(@"%@ does not conform to HWGrowlPluginProtocol", NSStringFromClass([pluginBundle principalClass]));
					}
					[plugin release];
				}else{
					NSLog(@"We couldn't instantiate %@ for plugin %@", NSStringFromClass([pluginBundle principalClass]), [pluginBundle bundleIdentifier]);
				}
			}else{
				NSLog(@"%@ is not a bundle or could not be loaded", bundlePath);
			}
		}];
	}
}

-(void)fireOnLaunchNotes {
	[notifiers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if([obj respondsToSelector:@selector(fireOnLaunchNotes)])
			[obj fireOnLaunchNotes];
	}];
}

-(void)notifyWithName:(NSString*)name 
					 title:(NSString*)title
			 description:(NSString*)description
					  icon:(NSData*)iconData
	  identifierString:(NSString*)identifier
		  contextString:(NSString*)context
					plugin:(id)plugin
{
	NSString *contextCombined = nil;
	if(context && [context rangeOfString:@" : "].location != NSNotFound) {
		NSLog(@"found \" : \" in context string %@", context);
	}
	if(context && plugin && [context rangeOfString:@" : "].location == NSNotFound) {
		contextCombined = [NSString stringWithFormat:@"%@ : %@", NSStringFromClass([plugin class]), context];
	}
	
	[GrowlApplicationBridge	notifyWithTitle:title
										 description:description
								  notificationName:name 
											 iconData:iconData
											 priority:0
											 isSticky:NO
										clickContext:contextCombined
										  identifier:identifier];
}

-(void)growlNotificationClosed:(id)clickContext viaClick:(BOOL)click {
	NSArray *components = [clickContext componentsSeparatedByString:@" : "];
	if([components count] < 2)
		return;
	NSString *classString = [components objectAtIndex:0];
	NSString *context = [components objectAtIndex:1];
	
	[notifiers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if([obj isKindOfClass:NSClassFromString(classString)]){
			if([obj respondsToSelector:@selector(noteClosed:byClick:)])
				[obj noteClosed:context byClick:click];
			*stop = YES;
		}
	}];
}

#pragma mark GrowlApplicationBridgeDelegate methods

- (NSDictionary*)registrationDictionaryForGrowl {
	NSMutableArray *allNotes = [NSMutableArray array];
	NSMutableArray *defaultNotes = [NSMutableArray array];
	NSMutableDictionary *descriptions = [NSMutableDictionary dictionary];
	NSMutableDictionary *localizedNames = [NSMutableDictionary dictionary];
	
	[notifiers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		id<HWGrowlPluginNotifierProtocol> notifier = obj;
		[allNotes addObjectsFromArray:[notifier noteNames]];
		[defaultNotes addObjectsFromArray:[notifier defaultNotifications]];
		[descriptions addEntriesFromDictionary:[notifier noteDescriptions]];
		[localizedNames addEntriesFromDictionary:[notifier localizedNames]];
	}];
	
	NSDictionary *regDict = [NSDictionary dictionaryWithObjectsAndKeys:allNotes, GROWL_NOTIFICATIONS_ALL,
									 defaultNotes, GROWL_NOTIFICATIONS_DEFAULT,
									 descriptions, GROWL_NOTIFICATIONS_DESCRIPTIONS,
									 localizedNames, GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES, nil];
	return regDict;
}

- (NSString *) applicationNameForGrowl {
	return @"HardwareGrowler";
}

-(void)growlNotificationTimedOut:(id)clickContext {
	[self growlNotificationClosed:clickContext viaClick:NO];
}

-(void)growlNotificationWasClicked:(id)clickContext {
	[self growlNotificationClosed:clickContext viaClick:YES];
}

@end
