//
//  GrowlNote.m
//  Growl
//
//  Created by Daniel Siemer on 5/7/13.
//  Copyright (c) 2013 The Growl Project. All rights reserved.
//

#import "GrowlNote.h"
#import "GrowlDefines.h"
#import "GrowlApplicationBridge.h"
#import "GrowlApplicationBridge_Private.h"
#import "GrowlMiniDispatch.h"

#import "GrowlGNTPNotificationAttempt.h"
#import "GrowlXPCNotificationAttempt.h"
#import "GrowlApplicationBridgeNotificationAttempt.h"

@interface GrowlNote ()

@property (nonatomic, retain) NSString *noteUUID;
@property (nonatomic, retain) NSDictionary *otherKeysDict;

@property (nonatomic, retain) GrowlCommunicationAttempt *firstAttempt;
@property (nonatomic, retain) GrowlCommunicationAttempt *secondAttempt;

@property (nonatomic, retain) NSUserNotification *appleNotification;

@end

@implementation GrowlNote

@synthesize delegate = _delegate;
@synthesize statusUpdateBlock = _statusUpdateBlock;

@synthesize noteUUID = _noteUUID;

@synthesize noteName = _noteName;
@synthesize title = _title;
@synthesize description = _description;
@synthesize iconData = _iconData;
@synthesize clickContext = _clickContext;
@synthesize clickCallbackURL = _clickCallbackURL;
@synthesize overwriteIdentifier = _overwriteIdentifier;
@synthesize sticky = _sticky;
@synthesize priority = _priority;

@synthesize otherKeysDict = _otherKeysDict;
@synthesize firstAttempt = _firstAttempt;
@synthesize secondAttempt = _secondAttempt;

@synthesize appleNotification = _appleNotification;

+ (NSDictionary *) notificationDictionaryByFillingInDictionary:(NSDictionary *)notifDict {
	NSMutableDictionary *mNotifDict = (notifDict != nil) ? [notifDict mutableCopy] : [[NSMutableDictionary alloc] init];
   
	if (![mNotifDict objectForKey:GROWL_APP_NAME]) {
		if ([[GrowlApplicationBridge sharedBridge] appName]) {
			[mNotifDict setObject:[[GrowlApplicationBridge sharedBridge] appName]
			               forKey:GROWL_APP_NAME];
		}
	}
   
	if (![mNotifDict objectForKey:GROWL_APP_ICON_DATA]) {      
		if ([[GrowlApplicationBridge sharedBridge] appIconData]) {
			[mNotifDict setObject:[[GrowlApplicationBridge sharedBridge] appIconData]
			               forKey:GROWL_APP_ICON_DATA];
		}
	}
   
   NSNumber *pidNum = [[NSNumber alloc] initWithInt:[[NSProcessInfo processInfo] processIdentifier]];
   [mNotifDict setObject:pidNum
                  forKey:GROWL_APP_PID];
   [pidNum release];
   
	return [mNotifDict autorelease];
}

+ (NSArray*)ivarKeys {
   static NSArray *_ivarKeys = nil;
   static dispatch_once_t onceToken;
   dispatch_once(&onceToken, ^{
      _ivarKeys = [@[GROWL_NOTIFICATION_NAME,
                   GROWL_NOTIFICATION_TITLE,
                   GROWL_NOTIFICATION_DESCRIPTION,
                   GROWL_NOTIFICATION_ICON_DATA,
                   GROWL_NOTIFICATION_CLICK_CONTEXT,
                   GROWL_NOTIFICATION_CALLBACK_URL_TARGET,
                   GROWL_NOTIFICATION_IDENTIFIER,
                   GROWL_NOTIFICATION_PRIORITY,
                   GROWL_NOTIFICATION_STICKY] retain];
   });
   return _ivarKeys;
}
+ (NSDictionary *)notificationDictionaryByRemovingIvarKeys:(NSDictionary*)notifDict {
   NSMutableArray *keysToKeep = [[[notifDict allKeys] mutableCopy] autorelease];
   [keysToKeep removeObjectsInArray:[self ivarKeys]];
   return [notifDict dictionaryWithValuesForKeys:keysToKeep];
}


/* Designated initializer, internal only */
-(id)initWithDictionary:(NSDictionary *)dictionary
                  title:(NSString *)title
            description:(NSString *)description
       notificationName:(NSString *)notifName
               iconData:(NSData *)iconData
               priority:(NSInteger)priority
               isSticky:(BOOL)isSticky
           clickContext:(id)clickContext
      actionButtonTitle:(NSString *)actionTitle
      cancelButtonTitle:(NSString *)cancelTitle
             identifier:(NSString *)identifier
{
   BOOL useDict = dictionary != nil;
   NSMutableDictionary *noteDict = [[[GrowlNote notificationDictionaryByFillingInDictionary:dictionary] mutableCopy] autorelease];
   if((self = [super init])){
      self.noteUUID = [[NSProcessInfo processInfo] globallyUniqueString];
      
      self.noteName = useDict ? [noteDict valueForKey:GROWL_NOTIFICATION_NAME] : notifName;
      self.title = useDict ? [noteDict valueForKey:GROWL_NOTIFICATION_TITLE] : title;
      self.description = useDict ? [noteDict valueForKey:GROWL_NOTIFICATION_DESCRIPTION] : description;
      self.iconData = useDict ? [noteDict valueForKey:GROWL_NOTIFICATION_ICON_DATA] : iconData;
      self.clickContext = useDict ? [noteDict valueForKey:GROWL_NOTIFICATION_CLICK_CONTEXT] : clickContext;
      self.overwriteIdentifier = useDict ? [noteDict valueForKey:GROWL_NOTIFICATION_IDENTIFIER] : identifier;
      
      if(useDict) self.clickCallbackURL = [noteDict valueForKey:GROWL_NOTIFICATION_CALLBACK_URL_TARGET];
      
      if(useDict && [noteDict valueForKey:GROWL_NOTIFICATION_PRIORITY] != nil)
         self.priority = [[noteDict valueForKey:GROWL_NOTIFICATION_PRIORITY] integerValue];
      else
         self.priority = priority;
      
      if(useDict && [noteDict valueForKey:GROWL_NOTIFICATION_STICKY] != nil)
         self.sticky = [[noteDict valueForKey:GROWL_NOTIFICATION_STICKY] boolValue];
      else
         self.sticky = isSticky;
      
      BOOL useNotificationCenter = (NSClassFromString(@"NSUserNotificationCenter") != nil);
      
      // Do we have notification center disabled?
      if (useNotificationCenter && ![[GrowlApplicationBridge sharedBridge] useNotificationCenterAlways]) {
         if ([[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ENABLE]) {
            useNotificationCenter = [[NSUserDefaults standardUserDefaults] boolForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ENABLE];
         }
      }
      
      // If we have notification center on, we must set this accordingly.
      //
      // Ideally, this would be set by the notification center delivery callback, but as we
      // are not guaranteed instant delivery, by that point the GNTP packet may already
      // have been built.  As such, we need to set it here instead.
      //
      if (useNotificationCenter && ([[GrowlApplicationBridge sharedBridge] useNotificationCenterAlways] ||
                                    [[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ALWAYS]))
      {
         if (![[NSUserDefaults standardUserDefaults] boolForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ALWAYS]) {
            [noteDict setObject:[NSNumber numberWithBool:YES] forKey:GROWL_NOTIFICATION_ALREADY_SHOWN];
         }
      }
      
      self.otherKeysDict = [GrowlNote notificationDictionaryByRemovingIvarKeys:noteDict];
   }
   return self;

}

-(id)initWithDictionary:(NSDictionary*)dictionary {
   NSParameterAssert([dictionary valueForKey:GROWL_NOTIFICATION_NAME]);	//Notification name is required.
	NSParameterAssert([dictionary valueForKey:GROWL_NOTIFICATION_TITLE] ||
                     [dictionary valueForKey:GROWL_NOTIFICATION_DESCRIPTION]);	//At least one of title or description is required.

   if((self = [self initWithDictionary:dictionary
                                 title:nil
                           description:nil
                      notificationName:nil
                              iconData:nil
                              priority:0
                              isSticky:NO
                          clickContext:nil
                     actionButtonTitle:nil
                     cancelButtonTitle:nil
                            identifier:nil]))
   {
   }
   return self;
}
+(GrowlNote*)noteWithDictionary:(NSDictionary *)dict {
   return [[[GrowlNote alloc] initWithDictionary:dict] autorelease];
}

- (id) initWithTitle:(NSString *)title
         description:(NSString *)description
    notificationName:(NSString *)notifName
            iconData:(NSData *)iconData
            priority:(NSInteger)priority
            isSticky:(BOOL)isSticky
        clickContext:(id)clickContext
   actionButtonTitle:(NSString *)actionTitle
   cancelButtonTitle:(NSString *)cancelTitle
          identifier:(NSString *)identifier
{
   NSParameterAssert(notifName);	//Notification name is required.
	NSParameterAssert(title || description);	//At least one of title or description is required.
   
   if((self = [self initWithDictionary:nil
                                 title:title
                           description:description
                      notificationName:notifName
                              iconData:iconData
                              priority:priority
                              isSticky:isSticky
                          clickContext:clickContext
                     actionButtonTitle:actionTitle
                     cancelButtonTitle:cancelTitle
                            identifier:identifier]))
   {
   }
   return self;
}
+(GrowlNote*)noteWithTitle:(NSString *)title
               description:(NSString *)description
          notificationName:(NSString *)notifName
                  iconData:(NSData *)iconData
                  priority:(NSInteger)priority
                  isSticky:(BOOL)isSticky
              clickContext:(id)clickContext
         actionButtonTitle:(NSString *)actionTitle
         cancelButtonTitle:(NSString *)cancelTitle
                identifier:(NSString *)identifier
{
   return [[[GrowlNote alloc] initWithTitle:title
                                description:description
                           notificationName:notifName
                                   iconData:iconData
                                   priority:priority
                                   isSticky:isSticky
                               clickContext:clickContext
                          actionButtonTitle:actionTitle
                          cancelButtonTitle:cancelTitle
                                 identifier:identifier] autorelease];
}

-(void)dealloc {
   [_statusUpdateBlock release];
   _statusUpdateBlock = nil;
   [_noteName release];
   _noteName = nil;
   [_title release];
   _title = nil;
   [_description release];
   _description = nil;
   [_iconData release];
   _iconData = nil;
   [_clickContext release];
   _clickContext = nil;
   [_otherKeysDict release];
   _otherKeysDict = nil;
   [_appleNotification release];
   _appleNotification = nil;
   [super dealloc];
}

-(NSDictionary*)noteDictionary {
   NSMutableDictionary *buildDict = [[self.otherKeysDict mutableCopy] autorelease];
   
   [buildDict setObject:self.noteUUID forKey:GROWL_NOTIFICATION_INTERNAL_ID];
   if (self.noteName)         [buildDict setObject:self.noteName forKey:GROWL_NOTIFICATION_NAME];
   if (self.title)            [buildDict setObject:self.title forKey:GROWL_NOTIFICATION_TITLE];
   if (self.description)      [buildDict setObject:self.description forKey:GROWL_NOTIFICATION_DESCRIPTION];
   if (self.iconData)         [buildDict setObject:self.iconData forKey:GROWL_NOTIFICATION_ICON_DATA];
   if (self.clickContext)     [buildDict setObject:self.clickContext forKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
   if (self.clickCallbackURL) [buildDict setObject:self.clickCallbackURL forKey:GROWL_NOTIFICATION_CALLBACK_URL_TARGET];
   if (self.overwriteIdentifier) [buildDict setObject:self.overwriteIdentifier forKey:GROWL_NOTIFICATION_IDENTIFIER];
   if (self.priority != 0)    [buildDict setObject:@(self.priority) forKey:GROWL_NOTIFICATION_PRIORITY];
   if (self.sticky)           [buildDict setObject:@(self.sticky) forKey:GROWL_NOTIFICATION_STICKY];
   
   return [[buildDict copy] autorelease];
}

-(void)notify {
   if(self.firstAttempt != nil){
      NSLog(@"ERROR! Should not be in -notify while -notify is already running");
      return;
   }
   
   BOOL useNotificationCenter = (NSClassFromString(@"NSUserNotificationCenter") != nil);
   BOOL alwaysCopyNC = NO;
   
   // Do we have notification center disabled?  (Only valid if it hasn't been turned on directly in Growl.)
   if (![[GrowlApplicationBridge sharedBridge] useNotificationCenterAlways]) {
      if (useNotificationCenter && [[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ENABLE])
         useNotificationCenter = [[NSUserDefaults standardUserDefaults] boolForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ENABLE];
   }
   
   // If we have notification center set to always-on, we must send.
   if (useNotificationCenter && ([[GrowlApplicationBridge sharedBridge] useNotificationCenterAlways]
                                 || [[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ALWAYS])) {
      alwaysCopyNC = ([[GrowlApplicationBridge sharedBridge] useNotificationCenterAlways] ||
                      ![[NSUserDefaults standardUserDefaults] boolForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ALWAYS]);
      if (alwaysCopyNC) {
         [self _fireAppleNotificationCenter];
      }
   }
   
   NSDictionary *noteDictionary = self.noteDictionary;
   //All the cases where growl is reachable *should* be covered now
   if ([[GrowlApplicationBridge sharedBridge] registered] && [[GrowlApplicationBridge sharedBridge] _growlIsReachableUpdateCache:NO]) {
      GrowlCommunicationAttempt *firstAttempt = nil;
      GrowlApplicationBridgeNotificationAttempt *secondAttempt = nil;
      
      if([[GrowlApplicationBridge sharedBridge] hasGNTP]){
         //These should be the only way we get marked as having gntp
         if([GrowlXPCCommunicationAttempt canCreateConnection])
            firstAttempt = [[GrowlXPCNotificationAttempt alloc] initWithDictionary:noteDictionary];
         else if([[GrowlApplicationBridge sharedBridge] hasNetworkClient])
            firstAttempt = [[GrowlGNTPNotificationAttempt alloc] initWithDictionary:noteDictionary];
         
         if(firstAttempt){
            firstAttempt.delegate = (id <GrowlCommunicationAttemptDelegate>)self;
            self.firstAttempt = firstAttempt;
            [firstAttempt release];
         }
      }
      
      if(![[GrowlApplicationBridge sharedBridge] sandboxed]){
         secondAttempt = [[GrowlApplicationBridgeNotificationAttempt alloc] initWithDictionary:noteDictionary];
         secondAttempt.delegate = (id <GrowlCommunicationAttemptDelegate>)self;
         
         if(_firstAttempt)
            self.secondAttempt.nextAttempt = secondAttempt;
         else
            self.firstAttempt = secondAttempt;
         [secondAttempt release];
      }
      
      //We should always have a first attempt if Growl is reachable
      if(_firstAttempt)
         [_firstAttempt begin];
   }else{
      if ([[GrowlApplicationBridge sharedBridge] _growlIsReachableUpdateCache:NO])
      {
         [[GrowlApplicationBridge sharedBridge] queueNote:self];
         //Protections in registerWithDictionary save this
         [GrowlApplicationBridge registerWithDictionary:nil];
      } else {
         // If we do the always-send-to-notification-center, we don't need a fallback.
         if (!alwaysCopyNC) {
            if (useNotificationCenter) {
               [self _fireAppleNotificationCenter];
            }
            else if([GrowlApplicationBridge isMistEnabled]){
               dispatch_async(dispatch_get_main_queue(), ^(void) {
                  [self _fireMiniDispatch];
               });
            }
         }
      }
   }
}

- (void) cancelNote {
   if(self.appleNotification) {
#if defined(MAC_OS_X_VERSION_10_8) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_8
      [[NSUserNotificationCenter defaultUserNotificationCenter] removeDeliveredNotification:self.appleNotification];
#endif
   }
   [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"GROWL_NOTIFICATION_CANCEL_REQUESTED"
                                                                  object:self.noteUUID];
}

- (void) _fireMiniDispatch
{
   NSDictionary *noteDictionary = self.noteDictionary;
   BOOL defaultOnly = YES;
   if([[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_MIST_DEFAULT_ONLY])
      defaultOnly = [[[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_MIST_DEFAULT_ONLY] boolValue];
   
   if (![[GrowlApplicationBridge sharedBridge] isNotificationDefaultEnabled:noteDictionary] && defaultOnly)
      return;
   
   [[[GrowlApplicationBridge sharedBridge] miniDispatch] displayNotification:noteDictionary];
}

- (void) _fireAppleNotificationCenter
{
#if defined(MAC_OS_X_VERSION_10_8) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_8
   NSDictionary *dict = self.noteDictionary;
   
   BOOL defaultOnly = YES;
   if([[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_DEFAULT_ONLY])
      defaultOnly = [[[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_DEFAULT_ONLY] boolValue];
   
   if (![[GrowlApplicationBridge sharedBridge] isNotificationDefaultEnabled:dict] && defaultOnly)
      return;
   
   // If we're not on 10.8, there's no point in doing this.
   if (!NSClassFromString(@"NSUserNotificationCenter"))
      return;
   
   NSMutableDictionary *notificationDict = [[[NSMutableDictionary alloc] init] autorelease];
   if ([dict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT])
      [notificationDict setObject:[dict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT] forKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
   if ([dict objectForKey:GROWL_NOTIFICATION_STICKY])
      [notificationDict setObject:[dict objectForKey:GROWL_NOTIFICATION_STICKY] forKey:GROWL_NOTIFICATION_STICKY];
   
   [notificationDict setObject:self.noteUUID forKey:@"APPLE_GROWL_NOTE_UUID"];
   
   NSUserNotification *appleNotification = [[NSUserNotification alloc] init];
   appleNotification.title = [dict objectForKey:GROWL_NOTIFICATION_TITLE];
   appleNotification.informativeText = [dict objectForKey:GROWL_NOTIFICATION_DESCRIPTION];
   appleNotification.userInfo = notificationDict;
   appleNotification.hasActionButton = NO;
   
   if ([dict objectForKey:GROWL_NOTIFICATION_BUTTONTITLE_ACTION]) {
      appleNotification.hasActionButton = YES;
      appleNotification.actionButtonTitle = [dict objectForKey:GROWL_NOTIFICATION_BUTTONTITLE_ACTION];
   }
   
   if ([dict objectForKey:GROWL_NOTIFICATION_BUTTONTITLE_CANCEL])
      appleNotification.otherButtonTitle = [dict objectForKey:GROWL_NOTIFICATION_BUTTONTITLE_CANCEL];
   
   [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:appleNotification];
   self.appleNotification = appleNotification;
   [appleNotification release];
#endif
}

#pragma mark GrowlCommunicationAttemptDelegate

- (void) attemptDidSucceed:(GrowlCommunicationAttempt *)attempt {
   //hrm
}
- (void) attemptDidFail:(GrowlCommunicationAttempt *)attempt {
   BOOL fallback = [attempt nextAttempt] == nil;
   if([attempt isEqual:self.firstAttempt]){
      self.firstAttempt = nil;
   }else if([attempt isEqual:self.secondAttempt]){
      self.secondAttempt = nil;
   }
   
   if(fallback) {
      //figure out which to use
   }
}
- (void) finishedWithAttempt:(GrowlCommunicationAttempt *)attempt {
   [[GrowlApplicationBridge sharedBridge] finishedWithNote:self];
}
- (void) queueAndReregister:(GrowlCommunicationAttempt *)attempt {
   if(attempt.attemptType != GrowlCommunicationAttemptTypeNotify)
      return;
   
   [[GrowlApplicationBridge sharedBridge] queueNote:self];
   [GrowlApplicationBridge reregisterGrowlNotifications];
}

- (void) stoppedAttempts:(GrowlCommunicationAttempt *)attempt {
   self.firstAttempt = nil;
   self.secondAttempt = nil;
}

//Sent after success
- (void) notificationClicked:(GrowlCommunicationAttempt *)attempt context:(id)context {
   if(self.statusUpdateBlock){
      self.statusUpdateBlock(GrowlNoteClicked, self);
   }else if(self.delegate){
      [self.delegate note:self statusUpdate:GrowlNoteClicked];
   }
   
}
- (void) notificationTimedOut:(GrowlCommunicationAttempt *)attempt context:(id)context {
   if(self.statusUpdateBlock){
      self.statusUpdateBlock(GrowlNoteTimedOut, self);
   }else if(self.delegate){
      [self.delegate note:self statusUpdate:GrowlNoteTimedOut];
   }
}

@end
