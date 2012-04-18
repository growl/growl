//
//  GrowlHistoryNotification.m
//  Growl
//
//  Created by Daniel Siemer on 8/17/10.
//  Copyright 2010 The Growl Project. All rights reserved.
//

#import "GrowlHistoryNotification.h"
#import "GrowlDefines.h"
#import "GrowlDefinesInternal.h"
#import "GrowlImageCache.h"
#import "NSStringAdditions.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation GrowlHistoryNotification
@dynamic AppID;
@dynamic ApplicationName;
@dynamic Description;
@dynamic Name;
@dynamic Time;
@dynamic Title;
@dynamic Priority;
@dynamic Identifier;
@dynamic Image;
@dynamic deleteUponReturn;
@dynamic showInRollup;
@dynamic GrowlDictionary;

-(void)setWithNoteDictionary:(NSDictionary*)noteDict
{
    NSString *appName = [noteDict objectForKey:GROWL_APP_ID];
    NSString *host = [noteDict valueForKey:GROWL_NOTIFICATION_GNTP_SENT_BY];
    NSString *appHost;
    BOOL isLocalHost = NO;
    
    if ([host hasSuffix:@".local"]) {
        host = [host substringToIndex:([host length] - [@".local" length])];
    }
    if(!host){
        isLocalHost = YES;
    }else {
        isLocalHost = [host isLocalHost];
    }
    if(isLocalHost){
        appHost = appName;
    }else {
        appHost = [NSString stringWithFormat:@"%@ - %@", host, appName];
    }
    
   self.AppID = appHost;
   self.ApplicationName = [noteDict objectForKey:GROWL_APP_NAME];
   self.Description = [noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION];
   self.Name = [noteDict objectForKey:GROWL_NOTIFICATION_NAME];
   self.Time = [NSDate date];
   self.Title = [noteDict objectForKey:GROWL_NOTIFICATION_TITLE];
   self.Priority = [noteDict objectForKey:GROWL_NOTIFICATION_PRIORITY];
   
   /* Done so that when a notification lacks a regular identifier for coaelescing,
    * it is given a unique signature in the database so it isnt coalesced over
    */
   if([noteDict objectForKey:GROWL_NOTIFICATION_IDENTIFIER])
      self.Identifier = [noteDict objectForKey:GROWL_NOTIFICATION_IDENTIFIER];
   else 
      self.Identifier = [noteDict objectForKey:GROWL_NOTIFICATION_INTERNAL_ID];
   
   //Check for the image;
   NSFetchRequest *request = [[[NSFetchRequest alloc] initWithEntityName:@"Image"] autorelease];
   
   NSData *imageData = [noteDict objectForKey:GROWL_NOTIFICATION_ICON_DATA];
   NSString *hash = [self hashForData:imageData];

   NSPredicate *predicate = [NSPredicate predicateWithFormat:@"Checksum == %@", hash];
   [request setPredicate:predicate];
   
   NSError *error = nil;
   NSArray *cacheResult = [[self managedObjectContext] executeFetchRequest:request error:&error];
   if(error){
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
      return;
   }
   
   if ([cacheResult count] > 0) {
      self.Image = [cacheResult objectAtIndex:0];
   }else{
      GrowlImageCache *newCache = [NSEntityDescription insertNewObjectForEntityForName:@"Image" 
                                                                inManagedObjectContext:[self managedObjectContext]];
      [newCache setImage:imageData andHash:hash];
      self.Image = newCache;
   }
   
   NSMutableDictionary *mutableDict = [[noteDict mutableCopyWithZone:nil] autorelease];
   [mutableDict removeObjectForKey:GROWL_NOTIFICATION_ICON_DATA];
   [mutableDict removeObjectForKey:GROWL_APP_ICON_DATA];
   self.GrowlDictionary = mutableDict;
}

-(NSString*)hashForData:(NSData*)data
{
	NSString *identifier = nil;
    unsigned char *digest = malloc(sizeof(unsigned char)*CC_MD5_DIGEST_LENGTH);
    if(digest)
    {
        CC_MD5([data bytes], (unsigned int)[data length], digest);
        identifier = [NSString stringWithFormat: @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                           digest[0], digest[1], 
                           digest[2], digest[3],
                           digest[4], digest[5],
                           digest[6], digest[7],
                           digest[8], digest[9],
                           digest[10], digest[11],
                           digest[12], digest[13],
                           digest[14], digest[15]];
        free(digest);
    }
	return identifier;
}

- (BOOL)validateGrowlDictionary:(id *)valueRef error:(NSError **)outError 
{
   // Insert custom validation logic here.
   return [(NSObject*)*valueRef isKindOfClass:[NSDictionary class]];
}

@end

