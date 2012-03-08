//
//  GrowlPluginPreferencePane.m
//  Growl
//
//  Created by Daniel Siemer on 3/3/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <GrowlPlugins/GrowlPluginPreferencePane.h>

@interface GrowlPluginPreferencePane ()

@property (nonatomic, retain) NSManagedObject *pluginConfiguration;

@end

@implementation GrowlPluginPreferencePane

@synthesize pluginConfiguration;
@synthesize configuration;
@synthesize configurationID = _configurationID;

-(void)setPluginConfiguration:(NSManagedObject *)plugin {
	if(self.pluginConfiguration) {
		[pluginConfiguration setValue:[[configuration copy] autorelease] forKey:@"configuration"];
		[pluginConfiguration release];
	}
	[self willChangeValueForKey:@"pluginConfiguration"];
	pluginConfiguration = [plugin retain];
	[self didChangeValueForKey:@"pluginConfiguration"];
	if([plugin valueForKey:@"configuration"])
		self.configuration = [[[plugin valueForKey:@"configuration"] mutableCopy] autorelease];
	else
		self.configuration = [NSMutableDictionary dictionary];
	
	if(_configurationID)
		[_configurationID release];
	_configurationID = [[plugin valueForKey:@"configID"] copy];
	
	[self updateConfigurationValues];
}

-(void)setConfigurationValue:(id)value forKey:(NSString*)key {
	[configuration setValue:value forKey:key];
	[pluginConfiguration setValue:[[configuration copy] autorelease] forKey:@"configuration"];
}

-(void)updateConfigurationValues {
	if([self respondsToSelector:@selector(bindingKeys)]){
		id set = [self performSelector:@selector(bindingKeys)];
		if(set && [set isKindOfClass:[NSSet class]]){
			[(NSSet*)set enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
				[self willChangeValueForKey:obj];
				[self didChangeValueForKey:obj];
			}];
		}
	}else{
		//NSLog(@"%@ does not respond to bindingKeys", self);
	}
}

- (NSColor *) loadColor:(NSString *)key defaultColor:(NSColor *)defaultColor {
	NSData *data = [self.configuration valueForKey:key];
	NSColor *color;
	if (data && [data isKindOfClass:[NSData class]]) {
		color = [NSUnarchiver unarchiveObjectWithData:data];
	} else {
		color = defaultColor;
	}	
	return color;
}

@end
