//
//  DisplayPluginsWithDefaultArrayController.m
//  Growl
//
//  Created by Evan Schoenberg on 8/18/07.
//

#import "DisplayPluginsWithDefaultArrayController.h"

@implementation DisplayPluginsWithDefaultArrayController

- (NSArray *)arrangedObjects
{
	NSMutableArray *arrangedObjects = [[[super arrangedObjects] mutableCopy] autorelease];

	//Add a null name/identifier pair. DisplayPluginNameWithDefaultTransformer can turn this into appropriate display as needed
	[arrangedObjects insertObject:[NSDictionary dictionaryWithObjectsAndKeys:
													[NSNull null], @"CFBundleName", 
													[NSNull null], @"CFBundleIdentifier",
													nil]
						  atIndex:0U];
	
	return arrangedObjects;	
}

@end
