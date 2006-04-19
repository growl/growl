//
//  GRDENotification.h
//  Growl Registration Dictionary Editor
//
//  Created by Peter Hosey on 2006-04-15.
//  Copyright 2006 Peter Hosey. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GRDEDocument;

@interface GRDENotification : NSObject {
	GRDEDocument *document;

	NSString *name, *humanReadableName, *description;
	BOOL enabled;
}

+ (NSString *)notificationNameFromDictionaryRepresentation:(NSDictionary *)dict;

#pragma mark -

- initWithDictionaryRepresentation:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

#pragma mark Accessors

- (GRDEDocument *)document;
- (void)setDocument:(GRDEDocument *)newDocument;

- (NSString *)name;
- (void)setName:(NSString *)newName;
- (NSString *)humanReadableName;
- (void)setHumanReadableName:(NSString *)newName;
- (NSString *)humanReadableDescription;
- (void)setHumanReadableDescription:(NSString *)newDesc;

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)flag;

@end
