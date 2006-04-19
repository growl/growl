//
//  GRDEDocument.h
//  Growl Registration Dictionary Editor
//
//  Created by Peter Hosey on 2006-04-15.
//  Copyright 2006 Peter Hosey. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@class GRDENotification;

@interface GRDEDocument : NSDocument
{
	NSString *applicationName, *bundleIdentifier;
	NSMutableArray *notificationDictionaries;
	NSMutableSet *notificationNames;
	IBOutlet NSArrayController *arrayController; //Bound to notificationDictionaries
	IBOutlet NSTableView *tableView; //Fed by arrayController

	NSMutableDictionary *dictionaryRepresentation;
	NSPropertyListFormat plistFormat;
}

#pragma mark Actions

- (IBAction)insertNewNotification:sender;

#pragma mark Accessors

- (NSString *)applicationName;
- (void)setApplicationName:(NSString *)newName;
- (NSString *)bundleIdentifier;
- (void)setBundleIdentifier:(NSString *)newID;

- (NSMutableArray *)notificationDictionaries;
- (void)setNotificationDictionaries:(NSArray *)array;

- (unsigned)countOfNotificationDictionaries;
- (GRDENotification *)objectInNotificationDictionariesAtIndex:(unsigned)idx;
- (void)getNotificationDictionaries:(out GRDENotification **)outDicts range:(NSRange)range;

- (void)replaceObjectInNotificationDictionariesAtIndex:(unsigned)idx withObject:(GRDENotification *)dict;
- (void)insertObject:(GRDENotification *)dict inNotificationDictionariesAtIndex:(unsigned)idx;
- (void)removeObjectFromNotificationDictionariesAtIndex:(unsigned)idx;

@end
