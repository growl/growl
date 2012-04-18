//
//  GrowlPlugin.m
//  Growl
//
//  Created by Peter Hosey on 2005-06-01.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlPlugin.h"


@implementation GrowlPlugin

@synthesize name = pluginName;
@synthesize author = pluginAuthor;
@synthesize version = pluginVersion;
@synthesize pluginDescription = pluginDesc;
@synthesize pathname = pluginPathName;
@synthesize bundle = pluginBundle;
@synthesize prefDomain;
@synthesize preferencePane;

//designated initialiser.
- (id) initWithName:(NSString *)name author:(NSString *)author version:(NSString *)version pathname:(NSString *)pathname {
	if ((self = [super init])) {
		self.name = name;
		self.author = author;
		self.version = version;
		self.pathname = pathname;
		self.prefDomain = nil;
	}
	return self;
}
/*use this initialiser for plug-ins in bundles. the name, author, version, and
 *	pathname will be obtained from the bundle.
 */
- (id) initWithBundle:(NSBundle *)bundle {
	NSDictionary *infoDict = [bundle infoDictionary];
	self = [self initWithName:[infoDict objectForKey:(NSString *)kCFBundleNameKey]
					   author:[infoDict objectForKey:@"GrowlPluginAuthor"]
					  version:[infoDict objectForKey:(NSString *)kCFBundleVersionKey]
					 pathname:[bundle bundlePath]];
	if (self) {
		self.pluginDescription = [infoDict objectForKey:@"GrowlPluginDescription"];
		self.bundle = bundle;
	}
	return self;
}

- (id) init {
	return [self initWithBundle:[NSBundle bundleForClass:[self class]]];
}

- (void) dealloc {
	[pluginName release];
	[pluginAuthor release];
	[pluginVersion release];
	[pluginDesc release];

	[pluginBundle release];
	[pluginPathName release];

	[prefDomain release];

	[super dealloc];
}

@end
