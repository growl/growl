//
//  GrowlTicketDatabaseApplication.m
//  Growl
//
//  Created by Daniel Siemer on 2/22/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlTicketDatabaseApplication.h"
#import "GrowlApplicationTicket.h"
#import "GrowlTicketDatabaseNotification.h"
#import "GrowlDefines.h"
#include "CFURLAdditions.h"

@implementation GrowlTicketDatabaseApplication

@dynamic appID;
@dynamic appPath;

-(void)setWithApplicationTicket:(GrowlApplicationTicket*)ticket {
   self.enabled = [NSNumber numberWithBool:[ticket ticketEnabled]];
   self.iconData = [ticket iconData];
   self.loggingEnabled = [NSNumber numberWithBool:[ticket loggingEnabled]];
   self.name = ticket.applicationName;
   self.positionType = [NSNumber numberWithInteger:[ticket positionType]];
   self.selectedPosition = [NSNumber numberWithInteger:[ticket selectedPosition]];
   self.appID = ticket.appID;
   self.appPath = ticket.appPath;
	
	[super importDisplayOrActionForName:[ticket displayPluginName]];
   
   [[ticket notifications] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      GrowlTicketDatabaseNotification *note = [NSEntityDescription insertNewObjectForEntityForName:@"GrowlNotificationTicket"
                                                                            inManagedObjectContext:[self managedObjectContext]];
      [note setParent:self];
      [note setWithNotificationTicket:obj];
      [note setDefaultEnabled:[NSNumber numberWithBool:[[ticket defaultNotifications] containsObject:obj]]];
   }];
}

-(void)registerWithDictionary:(NSDictionary *)regDict {
   self.iconData = [regDict objectForKey:GROWL_APP_ICON_DATA];
   self.name = [regDict objectForKey:GROWL_APP_NAME];
   self.appID = [regDict objectForKey:GROWL_APP_ID];
   self.positionType = [NSNumber numberWithInteger:0];	
   self.selectedPosition = [NSNumber numberWithInteger:0];
   
   BOOL doLookup = YES;
   NSString *fullPath = nil;
   id location = [regDict objectForKey:GROWL_APP_LOCATION];
   if (location) {
      if ([location isKindOfClass:[NSDictionary class]]) {
         NSDictionary *file_data = [(NSDictionary *)location objectForKey:@"file-data"];
         NSURL *url = fileURLWithDockDescription(file_data);
         if (url) {
            fullPath = [url path];
         }
      } else if ([location isKindOfClass:[NSString class]]) {
         fullPath = location;
         if (![[NSFileManager defaultManager] fileExistsAtPath:fullPath])
            fullPath = nil;
      } else if ([location isKindOfClass:[NSNumber class]]) {
         doLookup = [location boolValue];
      }
   }
   if (!fullPath && doLookup) {
      if (self.appID) {
         CFURLRef appURL = NULL;
         OSStatus err = LSFindApplicationForInfo(kLSUnknownCreator,
                                                 (CFStringRef)self.appID,
                                                 /*inName*/ NULL,
                                                 /*outAppRef*/ NULL,
                                                 &appURL);
         if (err == noErr) {
            fullPath = [(NSString *)CFURLCopyPath(appURL) autorelease];
            CFRelease(appURL);
         }
      }
      if (!fullPath)
         fullPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:self.name];
   }
   self.appPath = fullPath;
   
   NSDictionary *humanReadableNames = [regDict objectForKey:GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES];
   NSDictionary *notificationDescriptions = [regDict objectForKey:GROWL_NOTIFICATIONS_DESCRIPTIONS];
   
   //Get all the notification names and the data about them
   NSArray *allNotificationNames = [regDict objectForKey:GROWL_NOTIFICATIONS_ALL];
   NSAssert1(allNotificationNames, @"Ticket dictionaries must contain a list of all their notifications (application name: %@)", appName);
   
   id inDefaults = [regDict objectForKey:GROWL_NOTIFICATIONS_DEFAULT];
   if (!inDefaults) inDefaults = allNotificationNames;
   
   [allNotificationNames enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {      
      GrowlTicketDatabaseNotification *note = [NSEntityDescription insertNewObjectForEntityForName:@"GrowlNotificationTicket"
                                                                            inManagedObjectContext:[self managedObjectContext]];

      [note setParent:self];
      
      NSString *name;
      if ([obj isKindOfClass:[NSString class]]) {
         name = obj;
         note.name = obj;
      }
      //Set the human readable name if we were supplied one
      note.humanReadableName = [humanReadableNames objectForKey:name];
      note.ticketDescription = [notificationDescriptions objectForKey:name];

		note.sticky = [NSNumber numberWithInt:NSMixedState];
      
      if([inDefaults isKindOfClass:[NSArray class]]){
         if([inDefaults count] > 0){
            if([[inDefaults objectAtIndex:0U] isKindOfClass:[NSNumber class]]){
               NSUInteger found = [inDefaults indexOfObjectPassingTest:^BOOL(id innerObj, NSUInteger innerIdx, BOOL *stopInner) {
                  if(idx == [innerObj unsignedIntegerValue])
                     return YES;
                  return NO;
               }];
               note.defaultEnabled = [NSNumber numberWithBool:(found != NSNotFound) ? YES : NO];
            }else{
               note.defaultEnabled = [NSNumber numberWithBool:[inDefaults containsObject:note.name]];
            }
         }else{
            
         }
      }else if([inDefaults isKindOfClass:[NSIndexSet class]]){
         note.defaultEnabled = [NSNumber numberWithBool:[inDefaults containsIndex:idx]];
      }else{
         note.defaultEnabled = [NSNumber numberWithBool:YES];
      }
   }];
}

-(void)reregisterWithDictionary:(NSDictionary *)regDict {
   
}

-(GrowlTicketDatabaseNotification*)notificationTicketForName:(NSString*)noteName {
   __block GrowlTicketDatabaseNotification* note = nil;
   [self.children enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
      if([[obj name] isEqualToString:noteName]){
         note = obj;
         *stop = YES;
      }
   }];
   return note;
}

- (NSComparisonResult) caseInsensitiveCompare:(GrowlTicketDatabaseApplication *)aTicket {
   NSString *selfHost = self.parent.name;
   NSString *aTicketHost = aTicket.parent.name;
   if(!selfHost && !aTicketHost){
      return [[self name] caseInsensitiveCompare:[aTicket name]];
   }else if(selfHost && !aTicketHost){
      return NSOrderedDescending;
   }else if(!selfHost && aTicketHost){
      return NSOrderedAscending;
   }else { // if(selfHost && aTicketHost){
      if([selfHost caseInsensitiveCompare:aTicketHost] == NSOrderedSame)
         return [[self name] caseInsensitiveCompare:[aTicket name]];
      else
         return [selfHost caseInsensitiveCompare:aTicketHost];
   }
}


@end
