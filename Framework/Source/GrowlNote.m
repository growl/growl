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

@property (nonatomic, assign) NSInteger status;

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

@synthesize status = _status;

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
      self.status = NSIntegerMax;
      _localDisplayed = NO;
      
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
      
      BOOL useNotificationCenter = [GrowlMiniDispatch copyNotificationCenter];
      if(useNotificationCenter){
         [noteDict setObject:@YES forKey:GROWL_NOTIFICATION_ALREADY_SHOWN];
      }
      
      self.otherKeysDict = [GrowlNote notificationDictionaryByRemovingIvarKeys:noteDict];
      
      NSDistributedNotificationCenter *NSDNC = [NSDistributedNotificationCenter defaultCenter];
      [NSDNC addObserver:self
                selector:@selector(nsdncNoteUpdate:)
                    name:GROWL3_NOTIFICATION_CLICK
                  object:self.noteUUID
       suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
      [NSDNC addObserver:self
                selector:@selector(nsdncNoteUpdate:)
                    name:GROWL3_NOTIFICATION_TIMEOUT
                  object:self.noteUUID
       suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
      [NSDNC addObserver:self
                selector:@selector(nsdncNoteUpdate:)
                    name:GROWL3_NOTIFICATION_CLOSED
                  object:self.noteUUID
      suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
      [NSDNC addObserver:self
                selector:@selector(nsdncNoteUpdate:)
                    name:GROWL3_NOTIFICATION_NOT_DISPLAYED
                  object:self.noteUUID
      suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
      [NSDNC addObserver:self
                selector:@selector(nsdncNoteUpdate:)
                    name:GROWL3_NOTIFICATION_SHOW_NOTIFICATION_CENTER
                  object:self.noteUUID
       suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
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
   [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
   [_statusUpdateBlock release];
   _statusUpdateBlock = nil;
   [_noteUUID release];
   _noteUUID = nil;
   [_otherKeysDict release];
   _otherKeysDict = nil;
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
   [_clickCallbackURL release];
   _clickCallbackURL = nil;
   [_overwriteIdentifier release];
   _overwriteIdentifier = nil;
   [_otherKeysDict release];
   _otherKeysDict = nil;
   [_firstAttempt release];
   _firstAttempt = nil;
   [_secondAttempt release];
   _secondAttempt = nil;
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
   
   BOOL localRequired = NO;
   BOOL copyLocal = [GrowlMiniDispatch copyNotificationCenter];
   
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
         localRequired = YES;
      }
   }
   
   //If we haven't already been displayed locally, and we either need to copy or cant reach growl, fire here
   //We could have already displayed locally if we were told to notify, copied, failed to notify due to registration
   if(!_localDisplayed && (copyLocal || localRequired)){
      _localDisplayed = [[GrowlMiniDispatch sharedDispatch] displayNotification:self force:NO];
      
      //If local was required, and we couldn't display, handle our status update as not displayed
      if(!_localDisplayed && localRequired){
         [self handleStatusUpdate:GrowlNoteNotDisplayed];
      }
   }
}

- (void) cancelNote {
   [[GrowlMiniDispatch sharedDispatch] cancelNotification:self];
   [[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL3_NOTIFICATION_CANCEL_REQUESTED
                                                                  object:self.noteUUID
                                                                userInfo:nil
                                                      deliverImmediately:YES];
   [self handleStatusUpdate:GrowlNoteCanceled];
}

- (void) fallback {
   //Fallback doesn't force it, default enabled still stands
   if(!_localDisplayed)
      _localDisplayed = [[GrowlMiniDispatch sharedDispatch] displayNotification:self force:NO];
}

-(void)nsdncNoteUpdate:(NSNotification*)note {
   if([[note name] isEqualToString:GROWL3_NOTIFICATION_CLICK]){
      [self handleStatusUpdate:GrowlNoteClicked];
   }else if([[note name] isEqualToString:GROWL3_NOTIFICATION_TIMEOUT]){
      [self handleStatusUpdate:GrowlNoteTimedOut];
   }else if([[note name] isEqualToString:GROWL3_NOTIFICATION_CLOSED]){
      [self handleStatusUpdate:GrowlNoteClosed];
   }else if([[note name] isEqualToString:GROWL3_NOTIFICATION_NOT_DISPLAYED]){
      [self handleStatusUpdate:GrowlNoteNotDisplayed];
   }else if([[note name] isEqualToString:GROWL3_NOTIFICATION_SHOW_NOTIFICATION_CENTER]){
      //We have been told to display this note using our fallback system, force it to happen regardless of default enabled
      _localDisplayed = [[GrowlMiniDispatch sharedDispatch] displayNotification:self force:YES];
   }
}

-(void)handleStatusUpdate:(GrowlNoteStatus)status {
   [self handleStatusUpdate:status checkLifecycle:YES];
}

-(void)handleStatusUpdate:(GrowlNoteStatus)status checkLifecycle:(BOOL)check {
   if(self.status < NSIntegerMax)
      return;
   self.status = status;
   dispatch_async(dispatch_get_main_queue(), ^{
      if(self.statusUpdateBlock != NULL){
         self.statusUpdateBlock(status, self);
      }else if(self.delegate != nil && [self.delegate respondsToSelector:@selector(note:statusUpdate:)]){
         [self.delegate note:self statusUpdate:status];
      }
      if(check)
         [self checkLifecycle];
   });
}
   
-(void)checkLifecycle {
   if([[GrowlApplicationBridge sharedBridge] hasGrowlThreeFrameworkSupport]){
      /* We delay because Growl.framework 3 support
       * might tell us after the attempt finishes to use NSUNC
       */
      [GrowlNote cancelPreviousPerformRequestsWithTarget:self
                                                selector:@selector(_delayedCheckLifecycle)
                                                  object:nil];
      [self performSelector:@selector(_delayedCheckLifecycle)
                 withObject:nil
                 afterDelay:2.0
                    inModes:@[NSRunLoopCommonModes]];
   }else{
      //No Growl.framework 3 support
      [self _delayedCheckLifecycle];
   }
}
-(void)_delayedCheckLifecycle {
   BOOL finished = (self.status < NSIntegerMax);
   if(!finished && ![[GrowlApplicationBridge sharedBridge] hasGrowlThreeFrameworkSupport]){
      if(self.firstAttempt == nil &&
         self.secondAttempt == nil &&
         [[[GrowlMiniDispatch sharedDispatch] windowDictionary] objectForKey:self.noteUUID] == nil)
      {
         //We got here because we had our socket timeout against an old growl
         //And NC or Mist was not in use, send timed out
         if(self.status == NSIntegerMax)
            [self handleStatusUpdate:GrowlNoteTimedOut checkLifecycle:NO];
         finished = YES;
      }else{
         NSLog(@"Not finished, NSUNC or mist is still up");
      }
   }
   
   if(finished){
      [[GrowlApplicationBridge sharedBridge] finishedWithNote:self];
   }
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
      [self fallback];
   }
}
- (void) finishedWithAttempt:(GrowlCommunicationAttempt *)attempt {
   [self checkLifecycle];
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
   [self checkLifecycle];
}

//Sent after success
- (void) notificationClosed:(GrowlCommunicationAttempt *)attempt context:(id)context {
   [self handleStatusUpdate:GrowlNoteClosed];
}
- (void) notificationClicked:(GrowlCommunicationAttempt *)attempt context:(id)context {
   [self handleStatusUpdate:GrowlNoteClicked];   
}
- (void) notificationTimedOut:(GrowlCommunicationAttempt *)attempt context:(id)context {
   [self handleStatusUpdate:GrowlNoteTimedOut];
}
- (void) notificationWasNotDisplayed:(GrowlCommunicationAttempt *)attempt {
   [self handleStatusUpdate:GrowlNoteNotDisplayed];
}

@end
