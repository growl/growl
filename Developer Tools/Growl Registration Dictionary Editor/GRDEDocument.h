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
	NSMutableArray *notifications;
	NSMutableSet *notificationNames;
	IBOutlet NSArrayController *arrayController; //Bound to notifications
	IBOutlet NSTableView *tableView; //Fed by arrayController

	NSMutableDictionary *dictionaryRepresentation;
	NSPropertyListFormat plistFormat;

	BOOL wasReadFromGrowlTicket;
	//This is set to NO when the user tries to change a notification's name to one already possessed by another notification in the same document. When that happens, the table view delegate method -selectionShouldChange: sets it back to YES before returning NO.
	BOOL selectionChangeAllowed;
}

#pragma mark Actions

- (IBAction)insertNewNotification:sender;

#pragma mark Accessors

- (NSString *)applicationName;
- (void)setApplicationName:(NSString *)newName;
- (NSString *)bundleIdentifier;
- (void)setBundleIdentifier:(NSString *)newID;

- (NSMutableArray *)notifications;
- (void)setNotifications:(NSArray *)array;

- (unsigned)countOfNotifications;
- (GRDENotification *)objectInNotificationsAtIndex:(unsigned)idx;
- (void)getNotifications:(out GRDENotification **)outDicts range:(NSRange)range;

- (void)replaceObjectInNotificationsAtIndex:(unsigned)idx withObject:(GRDENotification *)dict;
- (void)insertObject:(GRDENotification *)dict inNotificationsAtIndex:(unsigned)idx;
- (void)removeObjectFromNotificationsAtIndex:(unsigned)idx;

- (NSSet *)notificationNames;

@end
