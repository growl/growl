//
//  GrowlWebKitPluginHandler.m
//  Growl
//
//  Created by JKP on 03/11/2005.
//  Copyright 2005–2011 The Growl Project. All rights reserved.
//

#import "GrowlWebKitPluginHandler.h"
#import "GrowlWebKitDisplayPlugin.h"
#import "GrowlPluginController.h"
#import "GrowlWebKitImageProtocol.h"

@implementation GrowlWebKitPluginHandler

+ (GrowlWebKitPluginHandler *)sharedInstance {
    static GrowlWebKitPluginHandler *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (id) init {
	if ((self = [super init])) {
		
		[GrowlWebKitImageProtocol registerProtocol];
	}

	return self;
}

- (BOOL) loadPluginAtPath:(NSString *)path {
	NSBundle *pluginBundle = [[NSBundle alloc] initWithPath:path];
	if (!pluginBundle) {
		NSLog(@"%@ Failed to load: %@",NSStringFromClass([self class]),path);
		[pluginBundle release];
		return NO;
	}

	GrowlWebKitDisplayPlugin *instance = [[GrowlWebKitDisplayPlugin alloc] initWithStyleBundle:pluginBundle];
	if (!instance) {
		NSLog(@"%@ Failed to load: %@ - the bundle did not contain a valid WebKit plugin",
			  NSStringFromClass([self class]),
			  path);
		[pluginBundle release];
		return NO;
	}

	NSDictionary *pluginDict = [[GrowlPluginController sharedController] addPluginInstance:instance fromBundle:pluginBundle];
	if([pluginDict pluginInstance] != instance){
		NSLog(@"this plugin already existed");
	}
	[instance release];
	[pluginBundle release];
	return YES;
}


@end
