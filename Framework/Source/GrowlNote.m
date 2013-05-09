//
//  GrowlNote.m
//  Growl
//
//  Created by Daniel Siemer on 5/7/13.
//  Copyright (c) 2013 The Growl Project. All rights reserved.
//

#import "GrowlNote.h"
#import "GrowlDefines.h"
#import "GrowlDefinesInternal.h"
#import "GrowlApplicationBridge.h"
#import "GrowlApplicationBridge_Private.h"
#import "GrowlMiniDispatch.h"

#import "GrowlGNTPNotificationAttempt.h"
#import "GrowlXPCNotificationAttempt.h"
#import "GrowlApplicationBridgeNotificationAttempt.h"

@interface GrowlNote ()

@property (nonatomic, retain) NSString *noteUUID;
@property (nonatomic, retain) NSDictionary *noteDictionary;

@end

@implementation GrowlNote

@synthesize noteUUID = _noteUUID;

@synthesize noteName = _noteName;
@synthesize title = _title;
@synthesize description = _description;
@synthesize iconData = _iconData;
@synthesize clickContext = _clickContext;
@synthesize sticky = _sticky;
@synthesize priority = _priority;

@synthesize noteDictionary = _noteDictionary;

+ (NSDictionary *) notificationDictionaryByFillingInDictionary:(NSDictionary *)notifDict {
	NSMutableDictionary *mNotifDict = [notifDict mutableCopy];
   
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
   
	//Only include the PID when there's a click context. We do this because NSDNC imposes a 15-MiB limit on the serialized notification, and we wouldn't want to overrun it because of a 4-byte PID.
	if ([mNotifDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT] && ![mNotifDict objectForKey:GROWL_APP_PID]) {
		NSNumber *pidNum = [[NSNumber alloc] initWithInt:[[NSProcessInfo processInfo] processIdentifier]];
      
		[mNotifDict setObject:pidNum
		               forKey:GROWL_APP_PID];
      
		[pidNum release];
	}
   
	return [mNotifDict autorelease];
}

/* Designated initializer */
-(id)initWithDictionary:(NSDictionary*)dictionary {
   dictionary = [GrowlNote notificationDictionaryByFillingInDictionary:dictionary];
   if((self = [super init])){
      self.noteUUID = [[NSProcessInfo processInfo] globallyUniqueString];
      
      self.noteDictionary = dictionary;
      self.noteName = [dictionary valueForKey:GROWL_NOTIFICATION_NAME];
      self.title = [dictionary valueForKey:GROWL_NOTIFICATION_TITLE];
      self.description = [dictionary valueForKey:GROWL_NOTIFICATION_DESCRIPTION];
      self.iconData = [dictionary valueForKey:GROWL_APP_ICON_DATA];
      self.priority = [[dictionary valueForKey:GROWL_NOTIFICATION_PRIORITY] integerValue];
      self.sticky = [[dictionary valueForKey:GROWL_NOTIFICATION_STICKY] boolValue];
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
          identifier:(NSString *)identifier
{
   NSParameterAssert(notifName);	//Notification name is required.
	NSParameterAssert(title || description);	//At least one of title or description is required.
   
	// Build our noteDict from all passed parameters
	NSMutableDictionary *noteDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                    notifName,	 GROWL_NOTIFICATION_NAME,
                                    nil];
   
	if (title)			[noteDict setObject:title forKey:GROWL_NOTIFICATION_TITLE];
	if (description)	[noteDict setObject:description forKey:GROWL_NOTIFICATION_DESCRIPTION];
	if (iconData)		[noteDict setObject:iconData forKey:GROWL_NOTIFICATION_ICON_DATA];
	if (clickContext)	[noteDict setObject:clickContext forKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
	if (priority)		[noteDict setObject:[NSNumber numberWithInteger:priority] forKey:GROWL_NOTIFICATION_PRIORITY];
	if (isSticky)		[noteDict setObject:[NSNumber numberWithBool:isSticky] forKey:GROWL_NOTIFICATION_STICKY];
	if (identifier)   [noteDict setObject:identifier forKey:GROWL_NOTIFICATION_IDENTIFIER];
   
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

   if((self = [self initWithDictionary:noteDict])){
      
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
                identifier:(NSString *)identifier
{
   return [[[GrowlNote alloc] initWithTitle:title
                                description:description
                           notificationName:notifName
                                   iconData:iconData
                                   priority:priority
                                   isSticky:isSticky
                               clickContext:clickContext
                                 identifier:identifier] autorelease];
}

-(void)dealloc {
   [super dealloc];
}

-(void)notify {
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
   
   //All the cases where growl is reachable *should* be covered now
   if ([[GrowlApplicationBridge sharedBridge] registered] && [[GrowlApplicationBridge sharedBridge] _growlIsReachableUpdateCache:NO]) {
      GrowlCommunicationAttempt *firstAttempt = nil;
      GrowlApplicationBridgeNotificationAttempt *secondAttempt = nil;
      
      if([[GrowlApplicationBridge sharedBridge] hasGNTP]){
         //These should be the only way we get marked as having gntp
         if([GrowlXPCCommunicationAttempt canCreateConnection])
            firstAttempt = [[GrowlXPCNotificationAttempt alloc] initWithDictionary:self.noteDictionary];
         else if([[GrowlApplicationBridge sharedBridge] hasNetworkClient])
            firstAttempt = [[GrowlGNTPNotificationAttempt alloc] initWithDictionary:self.noteDictionary];
         
         if(firstAttempt){
            firstAttempt.delegate = (id <GrowlCommunicationAttemptDelegate>)self;
            _firstAttempt = firstAttempt;
         }
      }
      
      if(![[GrowlApplicationBridge sharedBridge] sandboxed]){
         secondAttempt = [[GrowlApplicationBridgeNotificationAttempt alloc] initWithDictionary:self.noteDictionary];
         secondAttempt.delegate = (id <GrowlCommunicationAttemptDelegate>)self;
         
         if(_firstAttempt)
            _firstAttempt.nextAttempt = secondAttempt;
         else
            _secondAttempt = secondAttempt;
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

- (void) _fireMiniDispatch
{
   BOOL defaultOnly = YES;
   if([[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_MIST_DEFAULT_ONLY])
      defaultOnly = [[[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_MIST_DEFAULT_ONLY] boolValue];
   
   if (![[GrowlApplicationBridge sharedBridge] isNotificationDefaultEnabled:self.noteDictionary] && defaultOnly)
      return;
   
   [[[GrowlApplicationBridge sharedBridge] miniDispatch] displayNotification:self.noteDictionary];
}

- (void) _fireAppleNotificationCenter
{
#if defined(MAC_OS_X_VERSION_10_8) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_8
   BOOL defaultOnly = YES;
   if([[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_DEFAULT_ONLY])
      defaultOnly = [[[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_DEFAULT_ONLY] boolValue];
   
   if (![[GrowlApplicationBridge sharedBridge] isNotificationDefaultEnabled:self.noteDictionary] && defaultOnly)
      return;
   
   // If we're not on 10.8, there's no point in doing this.
   if (!NSClassFromString(@"NSUserNotificationCenter"))
      return;
   
   NSMutableDictionary *notificationDict = [[[NSMutableDictionary alloc] init] autorelease];
   if ([self.noteDictionary objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT])
      [notificationDict setObject:[self.noteDictionary objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT] forKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
   if ([self.noteDictionary objectForKey:GROWL_NOTIFICATION_STICKY])
      [notificationDict setObject:[self.noteDictionary objectForKey:GROWL_NOTIFICATION_STICKY] forKey:GROWL_NOTIFICATION_STICKY];
   
   NSUserNotification *appleNotification = [[NSUserNotification alloc] init];
   appleNotification.title = [self.noteDictionary objectForKey:GROWL_NOTIFICATION_TITLE];
   appleNotification.informativeText = [self.noteDictionary objectForKey:GROWL_NOTIFICATION_DESCRIPTION];
   appleNotification.userInfo = notificationDict;
   appleNotification.hasActionButton = NO;
   
   if ([self.noteDictionary objectForKey:GROWL_NOTIFICATION_BUTTONTITLE_ACTION]) {
      appleNotification.hasActionButton = YES;
      appleNotification.actionButtonTitle = [self.noteDictionary objectForKey:GROWL_NOTIFICATION_BUTTONTITLE_ACTION];
   }
   
   if ([self.noteDictionary objectForKey:GROWL_NOTIFICATION_BUTTONTITLE_CANCEL])
      appleNotification.otherButtonTitle = [self.noteDictionary objectForKey:GROWL_NOTIFICATION_BUTTONTITLE_CANCEL];
   
   [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:appleNotification];
   [appleNotification release];
#endif
}

#pragma mark GrowlCommunicationAttemptDelegate

- (void) attemptDidSucceed:(GrowlCommunicationAttempt *)attempt {
   //hrm
}
- (void) attemptDidFail:(GrowlCommunicationAttempt *)attempt {
   
}
- (void) finishedWithAttempt:(GrowlCommunicationAttempt *)attempt {

}
- (void) queueAndReregister:(GrowlCommunicationAttempt *)attempt {
   if(attempt.attemptType != GrowlCommunicationAttemptTypeNotify)
      return;
   
   [[GrowlApplicationBridge sharedBridge] queueNote:self];
   [GrowlApplicationBridge reregisterGrowlNotifications];
}

//Sent after success
- (void) notificationClicked:(GrowlCommunicationAttempt *)attempt context:(id)context {
   id<GrowlApplicationBridgeDelegate> mainDelegate = [GrowlApplicationBridge sharedBridge].delegate;
   if(mainDelegate != nil && [mainDelegate respondsToSelector:@selector(growlNotificationWasClicked:)])
      [mainDelegate growlNotificationWasClicked:context];
}
- (void) notificationTimedOut:(GrowlCommunicationAttempt *)attempt context:(id)context {
   id<GrowlApplicationBridgeDelegate> mainDelegate = [GrowlApplicationBridge sharedBridge].delegate;
   if(mainDelegate != nil && [mainDelegate respondsToSelector:@selector(growlNotificationWasClicked:)])
      [mainDelegate growlNotificationWasClicked:context];
}

@end
