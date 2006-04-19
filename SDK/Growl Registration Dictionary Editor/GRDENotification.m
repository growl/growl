//
//  GRDENotification.m
//  Growl Registration Dictionary Editor
//
//  Created by Peter Hosey on 2006-04-15.
//  Copyright 2006 Peter Hosey. All rights reserved.
//

#import "GRDENotification.h"

#import "GRDEDocument.h"

#import "GRDENotificationDictionaryKeys.h"

@implementation GRDENotification

+ (NSString *)notificationNameFromDictionaryRepresentation:(NSDictionary *)dict {
	return [dict objectForKey:GRDE_NOTIFICATION_NAME_KEY];
}

#pragma mark -

- init {
	if((self = [super init])) {
		enabled = YES;
		name = [@"" retain];
	}
	return self;
}
- (void)dealloc {
	[document release];
	[name release];
	[humanReadableName release];
	[description release];

	[super dealloc];
}

- initWithDictionaryRepresentation:(NSDictionary *)dict {
	if((self = [self init])) {
		[self setName:[dict objectForKey:GRDE_NOTIFICATION_NAME_KEY]];
		[self setEnabled:[[dict objectForKey:GRDE_NOTIFICATION_ENABLED_KEY] boolValue]];
		[self setHumanReadableName:[dict objectForKey:GRDE_NOTIFICATION_HUMANREADABLENAME_KEY]];
		[self setHumanReadableDescription:[dict objectForKey:GRDE_NOTIFICATION_DESCRIPTION_KEY]];
	}
	return self;
}
- (NSDictionary *)dictionaryRepresentation {
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:4U];
	[result setObject:name forKey:GRDE_NOTIFICATION_NAME_KEY];
	[result setObject:[NSNumber numberWithBool:enabled] forKey:GRDE_NOTIFICATION_ENABLED_KEY];
	if(humanReadableName)
		[result setObject:humanReadableName forKey:GRDE_NOTIFICATION_HUMANREADABLENAME_KEY];
	if(description)
		[result setObject:description forKey:GRDE_NOTIFICATION_DESCRIPTION_KEY];
	return [[result copy] autorelease];
}

#pragma mark Accessors

- (GRDEDocument *)document {
	return document;
}
- (void)setDocument:(GRDEDocument *)newDocument {
	[document release];
	document = [newDocument retain];
}

- (NSString *)name {
	return name;
}
- (void)setName:(NSString *)newName {
	if(!newName) newName = @"";

	NSUndoManager *mgr = [document undoManager];
	[mgr registerUndoWithTarget:self selector:@selector(setName:) object:name];
	[mgr setActionName:NSLocalizedString(@"Change Notification Name", /*comment*/ nil)];

	[name release];
	name = [newName copy];
}
- (NSString *)humanReadableName {
	return humanReadableName;
}
- (void)setHumanReadableName:(NSString *)newName {
	NSUndoManager *mgr = [document undoManager];
	[mgr registerUndoWithTarget:self selector:@selector(setHumanReadableName:) object:humanReadableName];
	[mgr setActionName:NSLocalizedString(@"Change Notification Human-readable Name", /*comment*/ nil)];

	[humanReadableName release];
	humanReadableName = [newName copy];
}
- (NSString *)humanReadableDescription {
	return description;
}
- (void)setHumanReadableDescription:(NSString *)newDesc {
	NSUndoManager *mgr = [document undoManager];
	[mgr registerUndoWithTarget:self selector:@selector(setHumanReadableDescription:) object:description];
	[mgr setActionName:NSLocalizedString(@"Change Notification Description", /*comment*/ nil)];

	[description release];
	description = [newDesc copy];
}

- (BOOL)isEnabled {
	return enabled;
}
- (void)setEnabled:(BOOL)flag {
	NSUndoManager *mgr = [document undoManager];
	[[mgr prepareWithInvocationTarget:self] setEnabled:enabled];
	[mgr setActionName:NSLocalizedString(@"Change Notification Enabled-by-default Flag", /*comment*/ nil)];

	enabled = flag;
}

#pragma mark Debugging

- (NSString *)description {
	NSMutableString *str = [NSMutableString stringWithFormat:@"<Notification %p, %@abled, with name %@", self, enabled ? @"en" : @"dis", name];
	if(humanReadableName)
		[str appendFormat:@", human-readable name %@", humanReadableName];
	if(description)
		[str appendFormat:@", description %@", description];
	[str appendString:@">"];
	return [[str copy] autorelease];
}

@end
