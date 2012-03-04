//
//  GrowlPluginPreferencePane.m
//  Growl
//
//  Created by Daniel Siemer on 3/3/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <GrowlPlugins/GrowlPluginPreferencePane.h>

@interface GrowlPluginPreferencePane ()

@property (nonatomic, retain) NSManagedObject *actionConfiguration;

@end

@implementation GrowlPluginPreferencePane

@synthesize actionConfiguration;
@synthesize configuration;

-(void)setActionConfiguration:(NSManagedObject *)action {
	if(self.actionConfiguration) {
		[actionConfiguration setValue:[[configuration copy] autorelease] forKey:@"configuration"];
		[actionConfiguration release];
	}
	actionConfiguration = [action retain];
	if([action valueForKey:@"configuration"])
		self.configuration = [[[action valueForKey:@"configuration"] mutableCopy] autorelease];
	else
		self.configuration = [NSMutableDictionary dictionary];
	[self updateConfigurationValues];
}

-(void)setConfigurationValue:(id)value forKey:(NSString*)key {
	[configuration setValue:value forKey:key];
	[actionConfiguration setValue:[[configuration copy] autorelease] forKey:@"configuration"];
}

-(void)updateConfigurationValues {
	if([self respondsToSelector:@selector(bindingPaths)]){
		[(NSSet*)[self performSelector:@selector(bindingPaths)] enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
			[self willChangeValueForKey:obj];
			[self didChangeValueForKey:obj];
		}];
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
