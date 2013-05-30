//
//  GrowlApplicationBridge.m
//  Growl
//
//  Created by Evan Schoenberg on Wed Jun 16 2004.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#import "GrowlApplicationBridge.h"
#import "GrowlApplicationBridge_Private.h"
#include "CFURLAdditions.h"
#import "GrowlDefinesInternal.h"
#import "GrowlPathUtilities.h"
#import "GrowlProcessUtilities.h"
#import "GrowlImageAdditions.h"
#import "GrowlMiniDispatch.h"
#import "GrowlNote.h"
#import "GrowlNote_Private.h"

#import "GrowlApplicationBridgeRegistrationAttempt.h"
#import "GrowlApplicationBridgeNotificationAttempt.h"
#import "GrowlGNTPRegistrationAttempt.h"
#import "GrowlGNTPNotificationAttempt.h"
#import "GrowlXPCCommunicationAttempt.h"
#import "GrowlXPCRegistrationAttempt.h"
#import "GrowlXPCNotificationAttempt.h"

#import "GrowlCodeSignUtilities.h"

#import <ApplicationServices/ApplicationServices.h>

@class GrowlRunningAppObserver;

static dispatch_queue_t notificationQueue_Queue;

@interface GrowlApplicationBridge ()

@property (nonatomic, assign) BOOL isGrowlRunning;
@property (nonatomic, assign) BOOL useNotificationCenterAlways;

@property (nonatomic, assign) BOOL sandboxed;
@property (nonatomic, assign) BOOL hasGNTP;
@property (nonatomic, assign) BOOL hasNetworkClient;
@property (nonatomic, assign) BOOL registered;

@property (nonatomic, retain) GrowlCommunicationAttempt *registrationAttempt;

@end

@implementation GrowlApplicationBridge

@synthesize isGrowlRunning = _isGrowlRunning;
@synthesize useNotificationCenterAlways = _useNotificationCenterAlways;
@synthesize hasGrowlThreeFrameworkSupport = _hasGrowlThreeFrameworkSupport;

@synthesize sandboxed = _sandboxed;
@synthesize hasGNTP = _hasGNTP;
@synthesize hasNetworkClient = _hasNetworkClient;
@synthesize registered = _registered;
@synthesize registerWhenGrowlIsReady = _registerWhenGrowlIsReady;

@synthesize shouldUseBuiltInNotifications = _shouldUseBuiltInNotifications;
@synthesize registrationDictionary = _registrationDictionary;
@synthesize appName = _appName;
@synthesize appIconData = _appIconData;

@synthesize delegate = _delegate;
@synthesize registrationAttempt = _registrationAttempt;

+ (GrowlApplicationBridge*)sharedBridge {
   static GrowlApplicationBridge *_bridge = nil;
   static dispatch_once_t onceToken;
   dispatch_once(&onceToken, ^{
      _bridge = [[GrowlApplicationBridge alloc] init];
   });
   return _bridge;
}

-(id)init {
   if((self = [super init])){
      self.isGrowlRunning = Growl_HelperAppIsRunning();
      [self _checkSandbox];
      
      static dispatch_once_t onceToken;
      dispatch_once(&onceToken, ^{
         notificationQueue_Queue = dispatch_queue_create("com.growl.growlframework.notequeue_queue", 0);
      });
      
      [[NSWorkspace sharedWorkspace] addObserver:self
                                      forKeyPath:@"runningApplications"
                                         options:NSKeyValueObservingOptionNew
                                         context:nil];
      
      NSDistributedNotificationCenter *NSDNC = [NSDistributedNotificationCenter defaultCenter];
      [NSDNC addObserverForName:GROWL_IS_READY
                         object:nil
                          queue:[NSOperationQueue mainQueue]
                     usingBlock:^(NSNotification *note) {
                        //We may have gotten a new version of growl
                        [self _growlIsReachableUpdateCache:YES];
                        
                        //Inform our delegate if it is interested
                        if (self.delegate && [self.delegate respondsToSelector:@selector(growlIsReady)])
                           [self.delegate growlIsReady];
                        
                        //Post a notification locally
                        [[NSNotificationCenter defaultCenter] postNotificationName:GROWL_IS_READY
                                                                            object:nil
                                                                          userInfo:nil];
                        
                        //register (fixes #102: this is necessary if we got here by Growl having just been installed)
                        if (_registerWhenGrowlIsReady) {
                           [self reregisterGrowlNotifications];
                           _registerWhenGrowlIsReady = NO;
                        } else {
                           self.registered = YES;
                           [self _emptyQueue];
                        }
                        
                     }];
      
      [NSDNC addObserverForName:GROWL_DISTRIBUTED_NOTIFICATION_NOTIFICATIONCENTER_ON
                         object:nil
                          queue:[NSOperationQueue mainQueue]
                     usingBlock:^(NSNotification *note) {
                        self.shouldUseBuiltInNotifications = YES;
                     }];;
      
      [NSDNC addObserverForName:GROWL_DISTRIBUTED_NOTIFICATION_NOTIFICATIONCENTER_OFF
                         object:nil queue:[NSOperationQueue mainQueue]
                     usingBlock:^(NSNotification *note) {
                        self.shouldUseBuiltInNotifications = NO;
                     }];
      
      // Query if we're using Notification Center directly, via the Big Magic Switch.
      //
      // Sadly, this will generate an update to everyone else, but there's
      // not a lot of way around that.
      //
      [NSDNC postNotificationName:GROWL_DISTRIBUTED_NOTIFICATION_NOTIFICATIONCENTER_QUERY
                           object:nil
                         userInfo:nil
               deliverImmediately:YES];
   
      if([GrowlXPCCommunicationAttempt canCreateConnection]){
         [[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationWillTerminateNotification
                                                           object:nil
                                                            queue:[NSOperationQueue mainQueue]
                                                       usingBlock:^(NSNotification *note) {
                                                          //Shutdown the XPC
                                                          [GrowlXPCCommunicationAttempt shutdownXPC];
                                                       }];
      }
            
      self.hasGrowlThreeFrameworkSupport = NO;
      [NSDNC postNotificationName:@"GROWL3_FRAMEWORK_SUPPORT_PING"
                           object:nil
                         userInfo:nil
               deliverImmediately:YES];
      [NSDNC addObserverForName:@"GROWL3_FRAMEWORK_SUPPORT"
                         object:nil
                          queue:[NSOperationQueue mainQueue]
                     usingBlock:^(NSNotification *note) {
                        self.hasGrowlThreeFrameworkSupport = YES;
                     }];
      
      self.registrationDictionary = [self bestRegistrationDictionary];
      self.registered = NO;
      if(self.registrationDictionary != nil){
         [self registerWithDictionary:self.registrationDictionary];
      }
   }
   return self;
}

-(void)dealloc {
   [[NSWorkspace sharedWorkspace] removeObserver:self forKeyPath:@"runningApplications"];
   [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
	[super dealloc];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if(object == [NSWorkspace sharedWorkspace] && [keyPath isEqualToString:@"runningApplications"]){
		BOOL newRunning = Growl_HelperAppIsRunning();
		if(self.isGrowlRunning && !newRunning){
         if([GrowlXPCCommunicationAttempt canCreateConnection])
            [GrowlXPCCommunicationAttempt shutdownXPC];
			self.isGrowlRunning = NO;
         self.hasGrowlThreeFrameworkSupport = NO;
		}else if(newRunning && !self.isGrowlRunning){
			self.isGrowlRunning = YES;
         [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"GROWL3_FRAMEWORK_SUPPORT_PING"
                                                                        object:nil
                                                                      userInfo:nil
                                                            deliverImmediately:YES];
		}
	}
}

- (NSMutableArray *) queuedNotes {
	static NSMutableArray *queuedGrowlNotifications = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		queuedGrowlNotifications = [[NSMutableArray alloc] init];
	});
	return queuedGrowlNotifications;
}

- (void) queueNote:(GrowlNote*)note {
	NSMutableArray *queue = [self queuedNotes];
	dispatch_async(notificationQueue_Queue, ^{
		[queue addObject:note];
	});
}

- (void) finishedWithNote:(GrowlNote*)note {
   dispatch_async(notificationQueue_Queue, ^{
		[[self notifications] removeObjectForKey:[note noteUUID]];
	});
}

- (GrowlNote*)noteForUUID:(NSString*)uuid {
   __block GrowlNote *note = nil;
   dispatch_sync(notificationQueue_Queue, ^{
      note = [[self notifications] valueForKey:uuid];
   });
   return note;
}

-(NSMutableDictionary *)notifications {
   static NSMutableDictionary *_notes = nil;
   static dispatch_once_t onceToken;
   dispatch_once(&onceToken, ^{
      _notes = [[NSMutableDictionary alloc] init];
   });
   return _notes;
}

- (void) setDelegate:(id<GrowlApplicationBridgeDelegate>)delegate {
   if (delegate != _delegate) {
      _delegate = delegate;
   }
      
   NSDistributedNotificationCenter *NSDNC = [NSDistributedNotificationCenter defaultCenter];
   
   if(self.registrationDictionary == nil){
      self.registrationDictionary = [self bestRegistrationDictionary];
   }
   
	/* Watch for notification clicks if our delegate responds to the
	 * growlNotificationWasClicked: selector. Notifications will come in on a
	 * unique notification name based on our app name, pid and
	 * GROWL_DISTRIBUTED_NOTIFICATION_CLICKED_SUFFIX.
	 */
	int pid = [[NSProcessInfo processInfo] processIdentifier];
	NSString *growlNotificationClickedName = [[NSString alloc] initWithFormat:@"%@-%d-%@",
                                             self.appName, pid, GROWL_DISTRIBUTED_NOTIFICATION_CLICKED_SUFFIX];
   
	if (self.delegate != nil && [self.delegate respondsToSelector:@selector(growlNotificationWasClicked:)])
		[NSDNC addObserver:self
                selector:@selector(growlNotificationWasClicked:)
                    name:growlNotificationClickedName
                  object:nil];
	else
		[NSDNC removeObserver:self
                       name:growlNotificationClickedName
                     object:nil];
	[growlNotificationClickedName release];
	
	/* We also look for notifications which arne't pid-specific but which are for our application */
	growlNotificationClickedName = [[NSString alloc] initWithFormat:@"%@-%@",
                                   self.appName, GROWL_DISTRIBUTED_NOTIFICATION_CLICKED_SUFFIX];
	if (self.delegate != nil && [self.delegate respondsToSelector:@selector(growlNotificationWasClicked:)])
		[NSDNC addObserver:self
                selector:@selector(growlNotificationWasClicked:)
                    name:growlNotificationClickedName
                  object:nil];
	else
		[NSDNC removeObserver:self
                       name:growlNotificationClickedName
                     object:nil];
	[growlNotificationClickedName release];
   
	NSString *growlNotificationTimedOutName = [[NSString alloc] initWithFormat:@"%@-%d-%@",
                                              self.appName, pid, GROWL_DISTRIBUTED_NOTIFICATION_TIMED_OUT_SUFFIX];
	if (self.delegate != nil && [self.delegate respondsToSelector:@selector(growlNotificationTimedOut:)])
		[NSDNC addObserver:self
                selector:@selector(growlNotificationTimedOut:)
                    name:growlNotificationTimedOutName
                  object:nil];
	else
		[NSDNC removeObserver:self
                       name:growlNotificationTimedOutName
                     object:nil];
	[growlNotificationTimedOutName release];
	
	/* We also look for notifications which arne't pid-specific but which are for our application */
	growlNotificationTimedOutName = [[NSString alloc] initWithFormat:@"%@-%@",
                                    self.appName, GROWL_DISTRIBUTED_NOTIFICATION_TIMED_OUT_SUFFIX];
	if (self.delegate != nil && [self.delegate respondsToSelector:@selector(growlNotificationTimedOut:)])
		[NSDNC addObserver:self
                selector:@selector(growlNotificationTimedOut:)
                    name:growlNotificationTimedOutName
                  object:nil];
	else
		[NSDNC removeObserver:self
                       name:growlNotificationTimedOutName
                     object:nil];
	[growlNotificationTimedOutName release];
   
	[self reregisterGrowlNotifications];
}
+ (void) setGrowlDelegate:(id<GrowlApplicationBridgeDelegate>)inDelegate {
   [[GrowlApplicationBridge sharedBridge] setDelegate:inDelegate];
}

+ (NSObject<GrowlApplicationBridgeDelegate> *) growlDelegate {
	return [[GrowlApplicationBridge sharedBridge] delegate];
}

- (void)setRegistrationDictionary:(NSDictionary *)registrationDictionary {
   if (![self.registrationDictionary isEqualToDictionary:registrationDictionary]){
      registrationDictionary = [self registrationDictionaryByFillingInDictionary:registrationDictionary];
      if(![self.registrationDictionary isEqualToDictionary:registrationDictionary]){
         [_registrationDictionary release];
         _registrationDictionary = [registrationDictionary copy];
         self.appName = [self _applicationNameForGrowlSearchingRegistrationDictionary:self.registrationDictionary];
         self.appIconData = [self _applicationIconDataForGrowlSearchingRegistrationDictionary:self.registrationDictionary];
         [self registerWithDictionary:self.registrationDictionary];
      }
   }
}

#pragma mark -

+ (void) notifyWithTitle:(NSString *)title
			 description:(NSString *)description
		notificationName:(NSString *)notifName
				iconData:(NSData *)iconData
				priority:(int)priority
				isSticky:(BOOL)isSticky
			clickContext:(id)clickContext
{
	[GrowlApplicationBridge notifyWithTitle:title
								description:description
						   notificationName:notifName
								   iconData:iconData
								   priority:priority
								   isSticky:isSticky
							   clickContext:clickContext
								 identifier:nil];
}

/* Send a notification to Growl for display.
 * title, description, and notifName are required.
 * All other id parameters may be nil to accept defaults.
 * priority is 0 by default; isSticky is NO by default.
 */
+ (void) notifyWithTitle:(NSString *)title
			 description:(NSString *)description
		notificationName:(NSString *)notifName
				iconData:(NSData *)iconData
				priority:(int)priority
				isSticky:(BOOL)isSticky
			clickContext:(id)clickContext
			  identifier:(NSString *)identifier
{
   [[GrowlApplicationBridge sharedBridge] notifyWithTitle:title
                                              description:description
                                         notificationName:notifName
                                                 iconData:iconData
                                                 priority:priority
                                                 isSticky:isSticky
                                             clickContext:clickContext
                                               identifier:identifier];
}
- (void) notifyWithTitle:(NSString *)title
             description:(NSString *)description
        notificationName:(NSString *)notifName
                iconData:(NSData *)iconData
                priority:(int)priority
                isSticky:(BOOL)isSticky
            clickContext:(id)clickContext
              identifier:(NSString *)identifier
{
   GrowlNote *note = [GrowlNote noteWithTitle:title
                                  description:description
                             notificationName:notifName
                                     iconData:iconData
                                     priority:priority
                                     isSticky:isSticky
                                 clickContext:clickContext
                            actionButtonTitle:nil
                            cancelButtonTitle:nil
                                   identifier:identifier];
   [self notifyWithNote:note];
}

+ (void) notifyWithDictionary:(NSDictionary *)userInfo {
   [[GrowlApplicationBridge sharedBridge] notifyWithDictionary:userInfo];
}
- (void) notifyWithDictionary:(NSDictionary *)userInfo
{
   GrowlNote *note = [GrowlNote noteWithDictionary:userInfo];
   [self notifyWithNote:note];
}

-(void)notifyWithNote:(GrowlNote *)note {
   dispatch_async(notificationQueue_Queue, ^{
      if(note.delegate == nil && note.self.statusUpdateBlock == NULL)
         note.delegate = self;
      [[self notifications] setObject:note forKey:[note noteUUID]];
      [note notify];      
   });
}

- (void) cancelNoteWithUUID:(NSString*)uuid {
   GrowlNote *note = [self noteForUUID:uuid];
   [note cancelNote];
}

- (BOOL)isNotificationDefaultEnabled:(NSDictionary*)growlDict
{
   NSDictionary *regDict = [self bestRegistrationDictionary];
   //Sanity check, shouldn't happen, just in case
   if(!regDict)
      return NO;
   
   BOOL result = NO;
   id defaultNotes = [regDict valueForKey:GROWL_NOTIFICATIONS_DEFAULT];
   NSString *name = [growlDict valueForKey:GROWL_NOTIFICATION_NAME];
   NSUInteger indexInAll = [[regDict valueForKey:GROWL_NOTIFICATIONS_ALL] indexOfObject:name];
   
   //If its not in all notes, its definitely not a default note
   if(indexInAll != NSNotFound) 
   {
      //If its an index set, see if the index of the name in all notes is in the set
      if([defaultNotes isKindOfClass:[NSIndexSet class]]) 
      {
         if([defaultNotes containsIndex:indexInAll])
            result = YES;
      } //If its an array, it should be either an array of indexes, or an array of names, if there arent any notes, its not there
      else if([defaultNotes isKindOfClass:[NSArray class]] && [defaultNotes count] > 0) 
      {
         //If first one is a number, its a numeric index array of defaults, if its a string, its an array of notification names
         if([[defaultNotes objectAtIndex:0] isKindOfClass:[NSNumber class]]) 
         {
            if([defaultNotes containsObject:[NSNumber numberWithUnsignedInteger:indexInAll]])
               result = YES;
         }
         else if([[defaultNotes objectAtIndex:0] isKindOfClass:[NSString class]]) 
         {
            if([defaultNotes containsObject:name])
               result = YES;
         }
      }
   }
   return result;
}

+ (BOOL)isMistEnabled {
   return [[GrowlApplicationBridge sharedBridge] isMistEnabled];
}
- (BOOL)isMistEnabled
{
    BOOL result = self.shouldUseBuiltInNotifications;
    
    //did the user set the global default to indicate they don't want them
    if([[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_MIST_ENABLE])
       result = [[[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_MIST_ENABLE] boolValue];
    
    //If growl is reachable, mist wont be used
    if([self _growlIsReachableUpdateCache:NO])
       result = NO;
    
    //If on Mountain Lion, Mist won't be used.
    if (NSClassFromString(@"NSUserNotificationCenter"))
       result = NO;

    return result;
}

+ (void)setShouldUseBuiltInNotifications:(BOOL)should {
   [GrowlApplicationBridge sharedBridge].shouldUseBuiltInNotifications = should;
}
+ (BOOL)shouldUseBuiltInNotifications {
    return [GrowlApplicationBridge sharedBridge].shouldUseBuiltInNotifications;
}

#pragma mark -


+ (BOOL) isGrowlInstalled {
   static BOOL warned = NO;
   if(warned){
      warned = YES;
      static dispatch_once_t onceToken;
      dispatch_once(&onceToken, ^{
         NSLog(@"+[GrowlApplicationBridge isGrowlInstalled] is deprecated, returns yes always now.  This warning will only show once");
      });
   }
	return YES;
}


+ (BOOL) isGrowlRunning {
	return [[GrowlApplicationBridge sharedBridge] isGrowlRunning];
}

#pragma mark -

+ (BOOL) registerWithDictionary:(NSDictionary *)regDict {
   return [[GrowlApplicationBridge sharedBridge] registerWithDictionary:regDict];
}
- (BOOL) registerWithDictionary:(NSDictionary *)regDict {
   if(self.registrationAttempt != nil){
      NSLog(@"Attempting to register while an attempt is already running");
   }
   
   //Will register when growl is running and ready
   if(![self _growlIsReachableUpdateCache:NO]){
      _registerWhenGrowlIsReady = YES;
      return NO;
   }
   
	if (regDict)
		regDict = [self registrationDictionaryByFillingInDictionary:regDict];
	else
		regDict = [self bestRegistrationDictionary];
	
	if(!regDict){
		NSLog(@"Cannot register without a registration dictionary!");
		return NO;
	}
   
   self.registrationDictionary = regDict;

   GrowlApplicationBridgeRegistrationAttempt *secondAttempt = nil;
   
   if(self.hasGNTP){
      //These should be the only way we get marked as having gntp
      if([GrowlXPCCommunicationAttempt canCreateConnection])
         self.registrationAttempt = [[[GrowlXPCRegistrationAttempt alloc] initWithDictionary:regDict] autorelease];
      else if(self.hasNetworkClient)
         self.registrationAttempt = [[[GrowlGNTPRegistrationAttempt alloc] initWithDictionary:regDict] autorelease];
      
      if(_registrationAttempt){
         _registrationAttempt.delegate = (id <GrowlCommunicationAttemptDelegate>)self;
      }
   }

   if(!self.sandboxed){
      secondAttempt = [[GrowlApplicationBridgeRegistrationAttempt alloc] initWithDictionary:regDict];
      secondAttempt.delegate = (id <GrowlCommunicationAttemptDelegate>)self;
      if(self.registrationAttempt != nil)
         self.registrationAttempt.nextAttempt = secondAttempt;
      else
         self.registrationAttempt = secondAttempt;
   }

	[self.registrationAttempt begin];

	return YES;
}

+ (void) reregisterGrowlNotifications {
   [[GrowlApplicationBridge sharedBridge] reregisterGrowlNotifications];
}
- (void) reregisterGrowlNotifications {
   self.registered = NO;
	[self registerWithDictionary:nil];
}

+ (void) setWillRegisterWhenGrowlIsReady:(BOOL)flag {
	[[GrowlApplicationBridge sharedBridge] setRegisterWhenGrowlIsReady:flag];
}
+ (BOOL) willRegisterWhenGrowlIsReady {
	return [[GrowlApplicationBridge sharedBridge] registerWhenGrowlIsReady];
}

#pragma mark -

+ (NSDictionary *) registrationDictionaryFromDelegate {
   return [[GrowlApplicationBridge sharedBridge] registrationDictionaryFromDelegate];
}
- (NSDictionary *) registrationDictionaryFromDelegate {
   NSDictionary *regDict = nil;
   
	if (self.delegate && [self.delegate respondsToSelector:@selector(registrationDictionaryForGrowl)])
		regDict = [self.delegate registrationDictionaryForGrowl];
   
//   if(!regDict)
//      NSLog(@"GrowlApplicationBridge: Either no delegate, or it does not respond to registrationDictionaryForGrowl");
   
	return regDict;
}

+ (NSDictionary *) registrationDictionaryFromBundle:(NSBundle *)bundle {
   return [[GrowlApplicationBridge sharedBridge] registrationDictionaryFromBundle:bundle];
}
- (NSDictionary *) registrationDictionaryFromBundle:(NSBundle *)bundle {
   if (!bundle) bundle = [NSBundle mainBundle];
   
	NSDictionary *regDict = nil;
   
	NSString *regDictPath = [bundle pathForResource:@"Growl Registration Ticket" ofType:GROWL_REG_DICT_EXTENSION];
	if (regDictPath) {
		regDict = [NSDictionary dictionaryWithContentsOfFile:regDictPath];
//		if (!regDict)
//			NSLog(@"GrowlApplicationBridge: The bundle at %@ contains a registration dictionary, but it is not a valid property list. Please tell this application's developer.", [bundle bundlePath]);
	}
   
	return regDict;
}

+ (NSDictionary *) bestRegistrationDictionary {
   return [[GrowlApplicationBridge sharedBridge] bestRegistrationDictionary];
}
- (NSDictionary *) bestRegistrationDictionary {
   NSDictionary *registrationDictionary =  [self registrationDictionaryFromDelegate];
   if (registrationDictionary == nil) {
      registrationDictionary = [self registrationDictionaryFromBundle:nil];
      if(registrationDictionary == nil){
         registrationDictionary = self.registrationDictionary;
//         if (registrationDictionary == nil)
//            NSLog(@"GrowlApplicationBridge: The Growl delegate did not supply a registration dictionary, and the app bundle at %@ does not have one. Please tell this application's developer.", [[NSBundle mainBundle] bundlePath]);
      }
   }
	return [self registrationDictionaryByFillingInDictionary:registrationDictionary];
}

#pragma mark -

+ (NSDictionary *) registrationDictionaryByFillingInDictionary:(NSDictionary *)regDict {
	return [[GrowlApplicationBridge sharedBridge] registrationDictionaryByFillingInDictionary:regDict];
}
- (NSDictionary *) registrationDictionaryByFillingInDictionary:(NSDictionary *)regDict {
   return [self registrationDictionaryByFillingInDictionary:regDict restrictToKeys:nil];
}

+ (NSDictionary *) registrationDictionaryByFillingInDictionary:(NSDictionary *)regDict restrictToKeys:(NSSet *)keys {
   return [[GrowlApplicationBridge sharedBridge] registrationDictionaryByFillingInDictionary:regDict restrictToKeys:keys];
}
- (NSDictionary *) registrationDictionaryByFillingInDictionary:(NSDictionary *)regDict restrictToKeys:(NSSet *)keys {
	if (!regDict) return nil;

	NSMutableDictionary *mRegDict = [regDict mutableCopy];

	if ((!keys) || [keys containsObject:GROWL_APP_NAME]) {
		if (![mRegDict objectForKey:GROWL_APP_NAME]) {
			if (!self.appName)
				self.appName = [self _applicationNameForGrowlSearchingRegistrationDictionary:regDict];

			[mRegDict setObject:self.appName
			             forKey:GROWL_APP_NAME];
		}
	}

	if ((!keys) || [keys containsObject:GROWL_APP_ICON_DATA]) {
		if (![mRegDict objectForKey:GROWL_APP_ICON_DATA]) {
			if (!self.appIconData)
				self.appIconData = [self _applicationIconDataForGrowlSearchingRegistrationDictionary:regDict];
			if (self.appIconData)
				[mRegDict setObject:self.appIconData forKey:GROWL_APP_ICON_DATA];
		}
	}

	if ((!keys) || [keys containsObject:GROWL_APP_LOCATION]) {
		if (![mRegDict objectForKey:GROWL_APP_LOCATION]) {
			NSURL *myURL = [[NSBundle mainBundle] bundleURL];
			if (myURL) {
				NSDictionary *file_data = dockDescriptionWithURL(myURL);
				if (file_data) {
					NSDictionary *location = [[NSDictionary alloc] initWithObjectsAndKeys:file_data, @"file-data", nil];
					[mRegDict setObject:location forKey:GROWL_APP_LOCATION];
					[location release];
				} else {
					[mRegDict removeObjectForKey:GROWL_APP_LOCATION];
				}
			}
		}
	}

	if ((!keys) || [keys containsObject:GROWL_NOTIFICATIONS_DEFAULT]) {
		if (![mRegDict objectForKey:GROWL_NOTIFICATIONS_DEFAULT]) {
			NSArray *all = [mRegDict objectForKey:GROWL_NOTIFICATIONS_ALL];
			if (all)
				[mRegDict setObject:all forKey:GROWL_NOTIFICATIONS_DEFAULT];
		}
	}

	if ((!keys) || [keys containsObject:GROWL_APP_ID])
		if (![mRegDict objectForKey:GROWL_APP_ID])
			[mRegDict setObject:(NSString *)CFBundleGetIdentifier(CFBundleGetMainBundle()) forKey:GROWL_APP_ID];

	return [mRegDict autorelease];
}

+ (NSDictionary *) notificationDictionaryByFillingInDictionary:(NSDictionary *)notifDict {
   return [GrowlNote notificationDictionaryByFillingInDictionary:notifDict];
}

+ (NSDictionary *) frameworkInfoDictionary {
	return [[NSBundle bundleForClass:[self class]] infoDictionary];
}

#pragma mark -
#pragma mark Growl URL scheme

+ (BOOL) isGrowlURLSchemeAvailable {
   return [[GrowlApplicationBridge sharedBridge] isGrowlURLSchemeAvailable];
}
- (BOOL) isGrowlURLSchemeAvailable {
   NSURL *growlURLScheme = [[NSWorkspace sharedWorkspace] URLForApplicationToOpenURL:[NSURL URLWithString:@"growl://"]];

   if(growlURLScheme != nil)
      return YES;
   return NO;
}

+ (BOOL) openGrowlPreferences:(BOOL)showApp {
   return [[GrowlApplicationBridge sharedBridge] openGrowlPreferences:showApp];
}
- (BOOL) openGrowlPreferences:(BOOL)showApp {
   if(showApp && !self.appName){
      NSLog(@"Attempt to show application setting without having set the Delegate first");
      return NO;
   }
   NSString *appString = showApp ? [NSString stringWithFormat:@"/applications/%@", self.appName] : @"";
   NSString *urlString = [[NSString stringWithFormat:@"growl://preferences%@", appString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
   NSURL *url = [NSURL URLWithString:urlString];
   return [[NSWorkspace sharedWorkspace] openURL:url];
}

#pragma mark -
#pragma mark Private methods

- (NSString *) _applicationNameForGrowlSearchingRegistrationDictionary:(NSDictionary *)regDict {
	NSString *applicationNameForGrowl = nil;

	if (self.delegate != nil && [self.delegate respondsToSelector:@selector(applicationNameForGrowl)])
		applicationNameForGrowl = [self.delegate applicationNameForGrowl];

	if (!applicationNameForGrowl) {
		applicationNameForGrowl = [regDict objectForKey:GROWL_APP_NAME];

		if (!applicationNameForGrowl)
			applicationNameForGrowl = [[NSProcessInfo processInfo] processName];
	}

	return applicationNameForGrowl;
}
- (NSData *) _applicationIconDataForGrowlSearchingRegistrationDictionary:(NSDictionary *)regDict {
	NSData *iconData = nil;

	if (self.delegate != nil) {
		if ([self.delegate respondsToSelector:@selector(applicationIconForGrowl)])
			iconData = (NSData *)[self.delegate applicationIconForGrowl];
		else if ([self.delegate respondsToSelector:@selector(applicationIconDataForGrowl)])
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
			iconData = [self.delegate applicationIconDataForGrowl];
#pragma clang diagnostic pop
	}

	if (!iconData)
		iconData = [regDict objectForKey:GROWL_APP_ICON_DATA];

	if (iconData && [iconData isKindOfClass:[NSImage class]])
		iconData = [(NSImage *)iconData PNGRepresentation];

	if (!iconData) {
		NSString *path = [[NSBundle mainBundle] bundlePath];
		iconData = [[[NSWorkspace sharedWorkspace] iconForFile:path] PNGRepresentation];
	}

	return iconData;
}

/*Selector called when a growl notification is clicked.  This should never be
 *	called manually, and the calling observer should only be registered if the
 *	delegate responds to growlNotificationWasClicked:.
 */
- (void) growlNotificationWasClicked:(NSNotification *)notification {
   @autoreleasepool {
        NSDictionary *userInfo = [notification userInfo];
        if ([[userInfo objectForKey:GROWL_NOTIFICATION_CLICK_BUTTONUSED] boolValue]) {
           [self.delegate growlNotificationActionButtonClicked:[userInfo objectForKey:GROWL_KEY_CLICKED_CONTEXT]];
        }
        else {
           [self.delegate growlNotificationWasClicked:[[notification userInfo] objectForKey:GROWL_KEY_CLICKED_CONTEXT]];
        }
   }
}
- (void) growlNotificationTimedOut:(NSNotification *)notification {
	@autoreleasepool {
      [self.delegate growlNotificationTimedOut:[[notification userInfo] objectForKey:GROWL_KEY_CLICKED_CONTEXT]];
   }
}

#pragma mark -

- (void) _emptyQueue
{
	NSMutableArray *queue = [self queuedNotes];
	dispatch_async(notificationQueue_Queue, ^{
		if([queue count]){
			[queue enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				if([obj isKindOfClass:[GrowlNote class]])
					[obj notify];
			}];
			[queue removeAllObjects];
		}
	});
}

- (BOOL) _growlIsReachableUpdateCache:(BOOL)update
{
   static BOOL _cached = NO;
   static BOOL _reachable = NO;
   
   BOOL running = [self isGrowlRunning];
   
   //No sense in running version checks repeatedly, but if growl relaunched, we will recheck
   if(_cached && !update){
      if(running)
         return _reachable;
      else
         return NO;
   }
   
   //We dont say _cached = YES here because we haven't done the other checks yet
   if(!running)
      return NO;
   
   //This is a bit of a hack, we check for Growl 1.2.2 and lower by seeing if the running helper app is inside Growl.prefpane
   NSString *runningPath = nil;
   NSArray *runningApplications = [NSRunningApplication runningApplicationsWithBundleIdentifier:GROWL_HELPERAPP_BUNDLE_IDENTIFIER];
   if(runningApplications && [runningApplications count])
      runningPath = [[[runningApplications objectAtIndex:0] bundleURL] absoluteString];
   NSString *prefPaneSubpath = @"Growl.prefpane/Contents/Resources";
   
    if(runningPath) {
        if([runningPath rangeOfString:prefPaneSubpath options:NSCaseInsensitiveSearch].location != NSNotFound){
            self.hasGNTP = NO;
            _reachable = !self.sandboxed;
            if(!_reachable)
                NSLog(@"%@ could not reach Growl, You are running Growl version 1.2.2 or older, and %@ is sandboxed", self.appName, self.appName);
        }else{
            //If we are running 1.3+, and we are sandboxed, do we have network client, or an XPC?
            self.hasGNTP = YES;
            if(self.sandboxed){
                if(self.hasNetworkClient || [GrowlXPCCommunicationAttempt canCreateConnection]){
                    _reachable = YES;
                }else{
                    NSLog(@"%@ could not reach Growl, %@ is sandboxed and does not have the ability to talk to Growl, contact the developer to resolve this", self.appName, self.appName);
                    _reachable = NO;
                }
            }else
                _reachable = YES;
        }
    }
    else {
        NSLog(@"%@ could not reach Growl, it is likely that if you're reading this message that Growl quit at the exact moment necessary to make this possible.", self.appName);
        _reachable = NO;
    }
    _cached = YES;
    return _reachable;
}

- (void) _checkSandbox
{
	static dispatch_once_t onceToken;
   dispatch_once(&onceToken, ^{
      self.sandboxed = [GrowlCodeSignUtilities isSandboxed];
      self.hasNetworkClient = self.sandboxed ? [GrowlCodeSignUtilities hasNetworkClientEntitlement] : YES;
   });
}

#pragma mark GrowlCommunicationAttemptDelegate protocol conformance

- (void) attemptDidSucceed:(GrowlCommunicationAttempt *)attempt {
	if (attempt.attemptType == GrowlCommunicationAttemptTypeRegister) {
		self.registered = YES;
      
      [self _emptyQueue];
	}
}
- (void) attemptDidFail:(GrowlCommunicationAttempt *)attempt {
   if(attempt.nextAttempt != nil){
      self.registrationAttempt = attempt.nextAttempt;
   }else{
      //NSLog(@"Failed all attempts at %@", attempt.attemptType == GrowlCommunicationAttemptTypeNotify ? @"notifying" : @"registering");
      if(attempt.attemptType == GrowlCommunicationAttemptTypeRegister){
         NSMutableArray *queue = [self queuedNotes];
			if([queue count]){
            NSLog(@"We failed at registering with items in our queue waiting to go to growl, falling back to built in notifications");
            dispatch_async(notificationQueue_Queue, ^{
               [queue enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                  dispatch_async(dispatch_get_main_queue(), ^{
                     [obj fallback];
                  });
               }];
            });
            dispatch_async(notificationQueue_Queue, ^{
               [queue removeAllObjects];
            });
         }
      }
      self.registrationAttempt = nil;
   }
}
- (void) finishedWithAttempt:(GrowlCommunicationAttempt *)attempt {
   self.registrationAttempt = nil;
}
- (void) queueAndReregister:(GrowlCommunicationAttempt *)attempt{}
- (void) notificationClicked:(GrowlCommunicationAttempt *)attempt context:(id)context{}
- (void) notificationTimedOut:(GrowlCommunicationAttempt *)attempt context:(id)context{}
- (void) notificationClosed:(GrowlCommunicationAttempt *)attempt context:(id)context {}

-(void)note:(GrowlNote *)note statusUpdate:(GrowlNoteStatus)status {
   if(note.clickContext != nil && self.delegate != nil){
      switch (status) {
         case GrowlNoteCanceled:
         case GrowlNoteNotDisplayed:
         case GrowlNoteTimedOut:
         case GrowlNoteClosed:
            if([self.delegate respondsToSelector:@selector(growlNotificationTimedOut:)])
               [self.delegate growlNotificationTimedOut:[note clickContext]];
            break;
         case GrowlNoteClicked:
         case GrowlNoteOtherClicked:
            if([self.delegate respondsToSelector:@selector(growlNotificationWasClicked:)])
               [self.delegate growlNotificationWasClicked:[note clickContext]];
            break;
         case GrowlNoteActionClicked:
            if([self.delegate respondsToSelector:@selector(growlNotificationActionButtonClicked:)])
               [self.delegate growlNotificationActionButtonClicked:[note clickContext]];
            else if([self.delegate respondsToSelector:@selector(growlNotificationWasClicked:)])
               [self.delegate growlNotificationWasClicked:[note clickContext]];
            break;
         default:
            break;
      }
   }
}

@end
