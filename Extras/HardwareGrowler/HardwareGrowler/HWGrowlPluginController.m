//
//  HWGrowlPluginController.m
//  HardwareGrowler
//
//  Created by Daniel Siemer on 5/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "HWGrowlPluginController.h"

@interface HWGrowlPluginController ()

@property (nonatomic, retain) NSMutableArray *plugins;

@end

@implementation HWGrowlPluginController

@synthesize plugins;

-(void)dealloc {
	[plugins release];
	[super dealloc];
}

-(id)init {
	if((self = [super init])){
		self.plugins = [NSMutableArray array];
		[self loadPlugins];
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

@end
