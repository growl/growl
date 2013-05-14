//
//  GrowlApplicationBridge.m
//  Growl
//
//  Created by Evan Schoenberg on Wed Jun 16 2004.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#import "GrowlApplicationBridge.h"
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

//used primarily by GIP, but could be useful elsewhere.
static BOOL		registerWhenGrowlIsReady = NO;

static BOOL    attemptingToRegister = NO;

static dispatch_queue_t notificationQueue_Queue;

@interface GrowlApplicationBridge ()

@property (nonatomic, assign) BOOL isGrowlRunning;
@property (nonatomic, assign) BOOL useNotificationCenterAlways;

@property (nonatomic, assign) BOOL sandboxed;
@property (nonatomic, assign) BOOL hasGNTP;
@property (nonatomic, assign) BOOL hasNetworkClient;
@property (nonatomic, assign) BOOL registered;

@property (nonatomic, retain) GrowlMiniDispatch *miniDispatch;

@end

@implementation GrowlApplicationBridge

@synthesize isGrowlRunning = _isGrowlRunning;
@synthesize useNotificationCenterAlways = _useNotificationCenterAlways;

@synthesize sandboxed = _sandboxed;
@synthesize hasGNTP = _hasGNTP;
@synthesize hasNetworkClient = _hasNetworkClient;
@synthesize registered = _registered;

@synthesize shouldUseBuiltInNotifications = _shouldUseBuiltInNotifications;
@synthesize registrationDictionary = _registrationDictionary;
@synthesize appName = _appName;
@synthesize appIconData = _appIconData;

@synthesize delegate = _delegate;
@synthesize miniDispatch = _miniDispatch;

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
      
      notificationQueue_Queue = dispatch_queue_create("com.growl.growlframework.notequeue_queue", 0);
      
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
                        if (registerWhenGrowlIsReady) {
                           [self reregisterGrowlNotifications];
                           registerWhenGrowlIsReady = NO;
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
      
      if(NSClassFromString(@"NSUserNotificationCenter") == nil) {
         self.miniDispatch = [[[GrowlMiniDispatch alloc] init] autorelease];
      }else {
#pragma mark FIX THIS TO BE BETTER
         [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
      }
      
      
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
			[GrowlXPCCommunicationAttempt shutdownXPC];
			self.isGrowlRunning = NO;
		}else if(newRunning){
			self.isGrowlRunning = YES;
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
   
   self.miniDispatch.delegate = delegate;
   
   NSDistributedNotificationCenter *NSDNC = [NSDistributedNotificationCenter defaultCenter];
      
	//Cache the appName from the delegate or the process name
	self.appName = [self _applicationNameForGrowlSearchingRegistrationDictionary:self.registrationDictionary];
	if (!self.appName) {
		NSLog(@"%@", @"GrowlApplicationBridge: Cannot register because the application name was not supplied and could not be determined");
		return;
	}
   
	/* Cache the appIconData from the delegate if it responds to the
	 * applicationIconDataForGrowl selector, or the application if not
	 */
	self.appIconData = [self _applicationIconDataForGrowlSearchingRegistrationDictionary:self.registrationDictionary];
   
	if([GrowlXPCCommunicationAttempt canCreateConnection]){
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			[[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationWillTerminateNotification
																			  object:nil
																				queue:[NSOperationQueue mainQueue]
																		 usingBlock:^(NSNotification *note) {
																			 //Shutdown the XPC
																			 [GrowlXPCCommunicationAttempt shutdownXPC];
																		 }];
		});
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
   
   // Query if we're using Notification Center directly, via the Big Magic Switch.
   //
   // Sadly, this will generate an update to everyone else, but there's
   // not a lot of way around that.
   //
   [NSDNC postNotificationName:GROWL_DISTRIBUTED_NOTIFICATION_NOTIFICATIONCENTER_QUERY
                        object:nil
                      userInfo:nil deliverImmediately:YES];
   
   if(self.registrationDictionary == nil){
      self.registrationDictionary = [self bestRegistrationDictionary];
      if(self.registrationDictionary != nil){
         [self registerWithDictionary:self.registrationDictionary];
      }
   }
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
   if (useNotificationCenter && !self.useNotificationCenterAlways) {
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
   if (useNotificationCenter && (self.useNotificationCenterAlways ||
                                 [[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ALWAYS])) {
      if (![[NSUserDefaults standardUserDefaults] boolForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ALWAYS]) {
         [noteDict setObject:[NSNumber numberWithBool:YES] forKey:GROWL_NOTIFICATION_ALREADY_SHOWN];
      }
   }
   
	[self notifyWithDictionary:noteDict];
	[noteDict release];
}

+ (void) notifyWithDictionary:(NSDictionary *)userInfo {
   [[GrowlApplicationBridge sharedBridge] notifyWithDictionary:userInfo];
}
- (void) notifyWithDictionary:(NSDictionary *)userInfo
{
   GrowlNote *note = [GrowlNote noteWithDictionary:userInfo];
   note.delegate = self;
   [self notifyWithNote:note];
}

-(void)notifyWithNote:(GrowlNote *)note {
   dispatch_async(notificationQueue_Queue, ^{
      [[self notifications] setObject:note forKey:[note noteUUID]];
      [note notify];      
   });
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
   if(attemptingToRegister){
      NSLog(@"Attempting to register while an attempt is already running");
   }
   
   //Will register when growl is running and ready
   if(![self _growlIsReachableUpdateCache:NO]){
      registerWhenGrowlIsReady = YES;
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

   attemptingToRegister = YES;
   
   self.registrationDictionary = regDict;

   GrowlApplicationBridgeRegistrationAttempt *secondAttempt = nil;
   
   if(self.hasGNTP){
      //These should be the only way we get marked as having gntp
      if([GrowlXPCCommunicationAttempt canCreateConnection])
         _registrationAttempt = [[GrowlXPCRegistrationAttempt alloc] initWithDictionary:regDict];
      else if(self.hasNetworkClient)
         _registrationAttempt = [[GrowlGNTPRegistrationAttempt alloc] initWithDictionary:regDict];
      
      if(_registrationAttempt){
         _registrationAttempt.delegate = (id <GrowlCommunicationAttemptDelegate>)self;
      }
   }

   if(!self.sandboxed){
      secondAttempt = [[GrowlApplicationBridgeRegistrationAttempt alloc] initWithDictionary:regDict];
      secondAttempt.applicationName = [self _applicationNameForGrowlSearchingRegistrationDictionary:regDict];
      secondAttempt.delegate = (id <GrowlCommunicationAttemptDelegate>)self;
      if(_registrationAttempt != nil)
         _registrationAttempt.nextAttempt = secondAttempt;
      else
         _registrationAttempt = secondAttempt;
   }

	[_registrationAttempt begin];

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
	registerWhenGrowlIsReady = flag;
}
+ (BOOL) willRegisterWhenGrowlIsReady {
	return registerWhenGrowlIsReady;
}

#pragma mark -

+ (NSDictionary *) registrationDictionaryFromDelegate {
   return [[GrowlApplicationBridge sharedBridge] registrationDictionaryFromDelegate];
}
- (NSDictionary *) registrationDictionaryFromDelegate {
   NSDictionary *regDict = nil;
   
	if (self.delegate && [self.delegate respondsToSelector:@selector(registrationDictionaryForGrowl)])
		regDict = [self.delegate registrationDictionaryForGrowl];
   
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
//      if (registrationDictionary == nil)
//         NSLog(@"GrowlApplicationBridge: The Growl delegate did not supply a registration dictionary, and the app bundle at %@ does not have one. Please tell this application's developer.", [[NSBundle mainBundle] bundlePath]);
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
      self.hasNetworkClient = [GrowlCodeSignUtilities hasNetworkClientEntitlement];
   });
}

#pragma mark GrowlCommunicationAttemptDelegate protocol conformance

- (void) attemptDidSucceed:(GrowlCommunicationAttempt *)attempt {
	if (attempt.attemptType == GrowlCommunicationAttemptTypeRegister) {
		self.registered = YES;
      attemptingToRegister = NO;
      
      [self _emptyQueue];
	}
}
- (void) attemptDidFail:(GrowlCommunicationAttempt *)attempt {
   if(attempt.nextAttempt == nil){
      //NSLog(@"Failed all attempts at %@", attempt.attemptType == GrowlCommunicationAttemptTypeNotify ? @"notifying" : @"registering");
      if(attempt.attemptType == GrowlCommunicationAttemptTypeRegister){
         attemptingToRegister = NO;
			
			/* If we have queued notes and we failed to register, 
			 * send them to Apple's notification center or to 
          * Mist.
          *
			 * Regardless, remove all dicts from the queue. 
			 * If we cant register, we probably can't send the notes to Growl.
			 */
         
         BOOL useNotificationCenter = (NSClassFromString(@"NSUserNotificationCenter") != nil);
         if (useNotificationCenter) {
            // If we don't have the global 'always use' on, we check the user defaults.
            if (!self.shouldUseBuiltInNotifications) {
               if ([[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ENABLE])
                  useNotificationCenter = [[NSUserDefaults standardUserDefaults] boolForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ENABLE];
            }
         }

         // If we always send to notification center, we don't need a fallback display as we've already done that.
         BOOL needsFallback = YES;
         if (useNotificationCenter && [[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ALWAYS])
            needsFallback = ![[NSUserDefaults standardUserDefaults] boolForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ALWAYS];
         
			NSMutableArray *queue = [self queuedNotes];
			if([queue count]){
            if (needsFallback) {
               if(useNotificationCenter){
                  NSLog(@"We failed at registering with items in our queue waiting to go to growl, sending them to OS X notification center instead");
                  dispatch_async(notificationQueue_Queue, ^{
                     [queue enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        if([obj isKindOfClass:[GrowlNote class]]){
                           dispatch_async(dispatch_get_main_queue(), ^{
                              [obj _fireAppleNotificationCenter];
                           });
                        }
                     }];
                  });
               }
               else if([self isMistEnabled]){
                  NSLog(@"We failed at registering with items in our queue waiting to go to growl, sending them to Mist instead");
                  dispatch_async(notificationQueue_Queue, ^{
                     [queue enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        if([obj isKindOfClass:[GrowlNote class]]){
                           dispatch_async(dispatch_get_main_queue(), ^{
                              [obj _fireMiniDispatch];
                           });
                        }
                     }];
                  });
               }
            }
            
				dispatch_async(notificationQueue_Queue, ^{
					[queue removeAllObjects];
				});
			}
      }
   }
   if([_registrationAttempt isEqual:attempt]){
      [_registrationAttempt release];
      _registrationAttempt = nil;
   }
}
- (void) finishedWithAttempt:(GrowlCommunicationAttempt *)attempt{
   if([attempt isEqual:_registrationAttempt]){
      [_registrationAttempt release];
      _registrationAttempt = nil;
   }
}
- (void) queueAndReregister:(GrowlCommunicationAttempt *)attempt{}
- (void) notificationClicked:(GrowlCommunicationAttempt *)attempt context:(id)context{}
- (void) notificationTimedOut:(GrowlCommunicationAttempt *)attempt context:(id)context{}

-(void)noteClicked:(GrowlNote*)note {
   if(self.delegate != nil && [self.delegate respondsToSelector:@selector(growlNotificationTimedOut:)])
      [self.delegate growlNotificationTimedOut:[note clickContext]];
}
-(void)noteTimedOut:(GrowlNote*)note {
   if(self.delegate != nil && [self.delegate respondsToSelector:@selector(growlNotificationTimedOut:)])
      [self.delegate growlNotificationTimedOut:[note clickContext]];
}

#pragma mark NSUserNotificationCenterDelegate

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
   @autoreleasepool {
      id clickContext = [[notification userInfo] objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
      
      if(notification.activationType == NSUserNotificationActivationTypeActionButtonClicked) {
         if(clickContext && [self.delegate respondsToSelector:@selector(growlNotificationActionButtonClicked:)])
            [self.delegate growlNotificationActionButtonClicked:clickContext];
         else if(clickContext && [self.delegate respondsToSelector:@selector(growlNotificationWasClicked:)])
            [self.delegate growlNotificationWasClicked:clickContext];
      }
      else if (notification.activationType == NSUserNotificationActivationTypeContentsClicked) {
         if(clickContext && [self.delegate respondsToSelector:@selector(growlNotificationWasClicked:)])
            [self.delegate growlNotificationWasClicked:clickContext];
      }
      else {
         if(clickContext && [self.delegate respondsToSelector:@selector(growlNotificationTimedOut:)])
            [self.delegate growlNotificationTimedOut:clickContext];
      }
      // Remove the notification, so it doesn't sit around forever.
      [center removeDeliveredNotification:notification];
   }
}

- (void)expireNotification:(NSDictionary *)dict
{
   NSUserNotification *notification = [dict objectForKey:@"notification"];
   NSUserNotificationCenter *center = [dict objectForKey:@"center"];
   
   // Remove the notification
   [center removeDeliveredNotification:notification];
   
   // Send the 'timed out' call to the hosting application
   id clickContext = [[notification userInfo] objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
   if(clickContext && [self.delegate respondsToSelector:@selector(growlNotificationTimedOut:)])
      [self.delegate growlNotificationTimedOut:clickContext];
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
   // If we're not sticky, let's wait about 60 seconds and then remove the notification.
   if (![[[notification userInfo] objectForKey:GROWL_NOTIFICATION_STICKY] boolValue]) {
      // (This should probably be made nicer down the road, but right now this works for a first testing cut.)
      
      // Make sure we're using the same center, though this should always be the default.
      NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:notification,@"notification",center,@"center",nil];
      
      NSInteger lifetime = 120;
      if ([[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_DURATION]) {
         lifetime = [[NSUserDefaults standardUserDefaults] integerForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_DURATION];
      }
      
      // If the duration is set to 0, we never manually expire notifications
      if (lifetime) {
         [self performSelector:@selector(expireNotification:) withObject:dict afterDelay:lifetime];
      }
      
      [dict release];
   }
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
   // This will be called if the notification is being omitted.  This happens in
   // two cases: first, if the application is already focused, and second if
   // the computer is in a DND mode.  For now, we're going to just return YES to
   // mimic Growl behavior; the program can sort out when/if it wants to show
   // notifications.  Down the road, we may want to make this logic fancier.
   
   return YES;
}

@end
