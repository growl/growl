//
//  GrowlNote.h
//  Growl
//
//  Created by Daniel Siemer on 5/7/13.
//  Copyright (c) 2013 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GrowlCommunicationAttempt.h"

@interface GrowlNote : NSObject <GrowlCommunicationAttemptDelegate> {
   NSString *_noteUUID;
   
   NSString *_noteName;
   NSString *_title;
   NSString *_description;
   NSData *_iconData;
   id _clickContext;
   BOOL _sticky;
   NSInteger _priority;
   
   NSDictionary *_noteDictionary;
   
   @private
   BOOL _notify;
   GrowlCommunicationAttempt *_firstAttempt;
   GrowlCommunicationAttempt *_secondAttempt;
}

@property (nonatomic, readonly) NSString *noteUUID;

@property (nonatomic, retain) NSString *noteName;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSData *iconData;
@property (nonatomic, retain) id clickContext;
@property (nonatomic, assign) BOOL sticky;
@property (nonatomic, assign) NSInteger priority;

//Direct access to this isn't allowed?
@property (nonatomic, readonly) NSDictionary *noteDictionary;

+ (NSDictionary *) notificationDictionaryByFillingInDictionary:(NSDictionary *)notifDict;

-(id)initWithDictionary:(NSDictionary*)dictionary;
+(GrowlNote*)noteWithDictionary:(NSDictionary*)dict;
-(id)initWithTitle:(NSString *)title
       description:(NSString *)description
  notificationName:(NSString *)notifName
          iconData:(NSData *)iconData
          priority:(NSInteger)priority
          isSticky:(BOOL)isSticky
      clickContext:(id)clickContext
        identifier:(NSString *)identifier;
+(GrowlNote*)noteWithTitle:(NSString *)title
               description:(NSString *)description
          notificationName:(NSString *)notifName
                  iconData:(NSData *)iconData
                  priority:(NSInteger)priority
                  isSticky:(BOOL)isSticky
              clickContext:(id)clickContext
                identifier:(NSString *)identifier;

@end
