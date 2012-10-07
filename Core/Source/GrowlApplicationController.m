//
//  GrowlApplicationController.m
//  Growl
//
//  Created by Karl Adam on Thu Apr 22 2004.
//  Renamed from GrowlController by Peter Hosey on 2005-06-28.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "GrowlApplicationController.h"
#import "GrowlPreferencesController.h"
#import "GrowlNotificationDatabase.h"
#import "GrowlTicketDatabase.h"
#import "GrowlTicketDatabaseApplication.h"
#import "GrowlTicketDatabaseNotification.h"
#import "GrowlTicketDatabaseAction.h"
#import "GrowlTicketDatabaseCompoundAction.h"
#import "GrowlPathway.h"
#import "GrowlPathwayController.h"
#import "GrowlPropertyListFilePathway.h"
#import "GrowlPathUtilities.h"
#import "NSStringAdditions.h"
#import "GrowlPluginController.h"
#import "GrowlIdleStatusObserver.h"
#import "GrowlDefines.h"
#import "GrowlVersionUtilities.h"
#import "GrowlMenu.h"
#import "VCSData.h"
#import "GrowlLog.h"
#import "GrowlNotificationCenter.h"
#import "GrowlImageAdditions.h"
#import "GrowlFirstLaunchWindowController.h"
#import "GrowlPreferencePane.h"
#import "GrowlApplicationsViewController.h"
#import "GrowlDisplaysViewController.h"
#import "GrowlServerViewController.h"
#import "GrowlNotificationHistoryWindow.h"
#import "GNTPForwarder.h"
#import "GNTPSubscriptionController.h"
#import "GrowlNetworkObserver.h"
#import <GrowlPlugins/GrowlNotification.h>
#import <GrowlPlugins/GrowlPlugin.h>
#import <GrowlPlugins/GrowlDisplayPlugin.h>
#import <GrowlPlugins/GrowlActionPlugin.h>
#import <GrowlPlugins/GrowlKeychainUtilities.h>

#include "CFURLAdditions.h"
#import "GrowlImageTransformer.h"

#pragma mark Notification Center Support

#if defined(MAC_OS_X_VERSION_10_8) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_8

@interface GrowlApplicationNotificationCenterDelegate ()

@property (nonatomic, retain) NSMutableDictionary *growlDicts;

@end


@implementation GrowlApplicationNotificationCenterDelegate

- (id)init {
	if((self = [super init])){
		self.growlDicts = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
	NSString *noteKey = [[notification userInfo] valueForKey:@"AppleNotificationID"];
   NSDictionary *growlNotificationDict = [self.growlDicts valueForKey:noteKey];
	if(growlNotificationDict){
		GrowlNotification *growlNotification = [[[GrowlNotification alloc] initWithDictionary:growlNotificationDict configurationDict:nil] autorelease];
		
		[center removeDeliveredNotification:notification];
		
		// Toss the click context back to the hosting app.
		[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION_CLICKED
																			 object:growlNotification
																		  userInfo:nil];
		[self.growlDicts removeObjectForKey:noteKey];
	}
}

- (void)expireNotification:(NSDictionary *)dict
{
   NSUserNotification *notification = [dict objectForKey:@"notification"];
   NSUserNotificationCenter *center = [dict objectForKey:@"center"];
	NSString *noteKey = [[notification userInfo] valueForKey:@"AppleNotificationID"];
   NSDictionary *growlNotificationDict = [self.growlDicts valueForKey:noteKey];
	if(growlNotificationDict){
		GrowlNotification *growlNotification = [[[GrowlNotification alloc] initWithDictionary:growlNotificationDict configurationDict:nil] autorelease];
		
		// Remove the notification
		[center removeDeliveredNotification:notification];
		
		// Send the 'timed out' call to the hosting application
		[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION_TIMED_OUT
																			 object:growlNotification
																		  userInfo:nil];
		[self.growlDicts removeObjectForKey:noteKey];
	}
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
   // If we're not sticky, let's wait about 60 seconds and then remove the notification.
   if (![[[notification userInfo] objectForKey:GROWL_NOTIFICATION_STICKY] boolValue]) {
      // (This should probably be made nicer down the road, but right now this works for a first testing cut.)
      
      // Make sure we're using the same center, though this should always be the default.
      NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:notification,@"notification",center,@"center",nil];
      
      NSInteger lifetime = 120;
      
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
   // mimic normal Growl behavior.  Down the road, we may want to make this logic fancier.
   
   return YES;
}

- (void)dealloc
{
   [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
	self.growlDicts = nil;
   [super dealloc];
}

@end
#endif

@interface GrowlApplicationController (PRIVATE)
- (void) notificationClicked:(NSNotification *)notification;
- (void) notificationTimedOut:(NSNotification *)notification;
- (void) notificationCenterQuery:(NSNotification *)notification;
@end

/*applications that go full-screen (games in particular) are expected to capture
 *	whatever display(s) they're using.
 *we [will] use this to notice, and turn on auto-sticky or something (perhaps
 *	to be decided by the user), when this happens.
 */
#if 0
static BOOL isAnyDisplayCaptured(void) {
	BOOL result = NO;

	CGDisplayCount numDisplays;
	CGDisplayErr err = CGGetActiveDisplayList(/*maxDisplays*/ 0U, /*activeDisplays*/ NULL, &numDisplays);
	if (err != noErr)
		[[GrowlLog sharedController] writeToLog:@"Checking for captured displays: Could not count displays: %li", (long)err];
	else {
		CGDirectDisplayID *displays = malloc(numDisplays * sizeof(CGDirectDisplayID));
		CGGetActiveDisplayList(numDisplays, displays, /*numDisplays*/ NULL);

		if (!displays)
			[[GrowlLog sharedController] writeToLog:@"Checking for captured displays: Could not allocate list of displays: %s", strerror(errno)];
		else {
			for (CGDisplayCount i = 0U; i < numDisplays; ++i) {
				if (CGDisplayIsCaptured(displays[i])) {
					result = YES;
					break;
				}
			}

			free(displays);
		}
	}

	return result;
}
#endif

static struct Version version = { 0U, 0U, 0U, releaseType_vcs, 0U, };

@implementation GrowlApplicationController
@synthesize statusMenu;

+ (GrowlApplicationController *) sharedController {
    static GrowlApplicationController *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (id) init {
	if ((self = [super init])) {
		growlFinishedLaunching = NO;
		urlOnLaunch = nil;
      
      NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
      [appleEventManager setEventHandler:self 
                             andSelector:@selector(handleGetURLEvent:withReplyEvent:) 
                           forEventClass:kInternetEventClass 
                              andEventID:kAEGetURL];
	}

	return self;
}

- (void) dealloc {
	//free your world
	Class pathwayControllerClass = NSClassFromString(@"GrowlPathwayController");
	if (pathwayControllerClass)
		[(id)[pathwayControllerClass sharedController] setServerEnabled:NO];
    [preferencesWindow release]; preferencesWindow = nil;

	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
	
	[growlNotificationCenterConnection invalidate];
	[growlNotificationCenterConnection release]; growlNotificationCenterConnection = nil;
	[growlNotificationCenter           release]; growlNotificationCenter = nil;
	
#if defined(MAC_OS_X_VERSION_10_8) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_8
   [appleNotificationDelegate release]; appleNotificationDelegate = nil;
#endif
   
	[super dealloc];
}

#pragma mark Guts

- (void) showPreview:(NSNotification *) note {
	@autoreleasepool {
		id displayConfig = [note object];
		GrowlDisplayPlugin *displayPlugin = nil;
		if([displayConfig respondsToSelector:@selector(pluginInstanceForConfiguration)])
			displayPlugin = (GrowlDisplayPlugin*)[displayConfig pluginInstanceForConfiguration];
		
		
		if([displayConfig isKindOfClass:[NSSet class]]){
			[(NSSet*)displayConfig enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
				[[NSNotificationCenter defaultCenter] postNotificationName:GrowlPreview object:obj];
			}];
		}else if([displayConfig isKindOfClass:[GrowlTicketDatabaseCompoundAction class]]){
			NSSet *actions = [(GrowlTicketDatabaseCompoundAction*)displayConfig resolvedActionConfigSet];
			[actions enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
				[[NSNotificationCenter defaultCenter] postNotificationName:GrowlPreview object:obj];
			}];
		}else if(displayPlugin && [displayPlugin conformsToProtocol:@protocol(GrowlDispatchNotificationProtocol)]){
			NSString *desc = [[NSString alloc] initWithFormat:NSLocalizedString(@"This is a preview of the %@ display", "Preview message shown when clicking Preview in the system preferences pane. %@ becomes the name of the display style being used."), [displayPlugin name]];
			NSNumber *priority = [[NSNumber alloc] initWithInt:0];
			NSNumber *sticky = [[NSNumber alloc] initWithBool:NO];
			NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:
										 @"Growl",   GROWL_APP_NAME,
										 @"Preview", GROWL_NOTIFICATION_NAME,
										 NSLocalizedString(@"Preview", "Title of the Preview notification shown to demonstrate Growl displays"), GROWL_NOTIFICATION_TITLE,
										 desc,       GROWL_NOTIFICATION_DESCRIPTION,
										 priority,   GROWL_NOTIFICATION_PRIORITY,
										 sticky,     GROWL_NOTIFICATION_STICKY,
										 [NSImage imageNamed:NSImageNameApplicationIcon],  GROWL_NOTIFICATION_ICON_DATA,
										 nil];
			[desc     release];
			[priority release];
			[sticky   release];
			NSMutableDictionary *configCopy = nil;
			if([displayConfig respondsToSelector:@selector(configuration)])
				configCopy = [[[displayConfig configuration] mutableCopy] autorelease];
         if(!configCopy)
            configCopy = [NSMutableDictionary dictionary];
			[configCopy setValue:[NSNumber numberWithLong:[[GrowlPreferencesController sharedController] selectedPosition]]
							  forKey:@"com.growl.positioncontroller.selectedposition"];
			[configCopy setValue:[displayConfig configID] forKey:GROWL_PLUGIN_CONFIG_ID];
			
			void (^displayBlock)(void) = ^{
				[displayPlugin dispatchNotification:info withConfiguration:configCopy];
			};
			if([displayConfig isKindOfClass:[GrowlTicketDatabaseAction class]])
				dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), displayBlock);
			else
				dispatch_async(dispatch_get_main_queue(), displayBlock);
			[info release];
		}else{
			NSLog(@"Invalid object for displaying a preview: %@", displayConfig);
		}
	}
}


- (void) _fireAppleNotificationCenter:(NSDictionary *)growlDict
{
#if defined(MAC_OS_X_VERSION_10_8) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_8
   // If we're not on 10.8, there's no point in doing this.
   if (!NSClassFromString(@"NSUserNotificationCenter"))
      return;
   
   // If the app uses Growl 2.0 framework and already fired this off itself, we
   // can safely ignore this, as the work has been done for us.
   if ([[growlDict objectForKey:GROWL_NOTIFICATION_ALREADY_SHOWN] boolValue])
      return;

   // We want to preserve all the notification state, but we can't pass the icon
   // data in, or OS X will whine about the userinfo being too large.
   NSMutableDictionary *notificationDict = [[growlDict mutableCopy] autorelease];
	[notificationDict removeObjectForKey:GROWL_APP_ICON_DATA];
   [notificationDict removeObjectForKey:GROWL_NOTIFICATION_APP_ICON_DATA];
   [notificationDict removeObjectForKey:GROWL_NOTIFICATION_ICON_DATA];
   
   NSUserNotification *appleNotification = [[NSUserNotification alloc] init];
   appleNotification.title = [growlDict objectForKey:GROWL_APP_NAME];
   appleNotification.subtitle = [growlDict objectForKey:GROWL_NOTIFICATION_TITLE];
   appleNotification.informativeText = [growlDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION];
	
	NSString *noteKey = [[NSProcessInfo processInfo] globallyUniqueString];
	appleNotification.userInfo = [NSDictionary dictionaryWithObject:noteKey forKey:@"AppleNotificationID"];
	
	// If we ever add support for action buttons in Growl (please), we'll want to add those here.
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		appleNotificationDelegate = [[GrowlApplicationNotificationCenterDelegate alloc] init];
	});
	[appleNotificationDelegate.growlDicts setObject:notificationDict forKey:noteKey];
	
	[[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:appleNotificationDelegate];
	[[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:appleNotification];
   [appleNotification release];
#endif
}

#pragma mark Dispatching notifications

-(BOOL)hasAppleScriptTaskClass {
   return NSClassFromString(@"NSUserAppleScriptTask") != nil;
}

-(NSURL*)baseScriptDirectoryURL {
   NSError *urlError = nil;
   NSURL *baseURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationScriptsDirectory
                                                           inDomain:NSUserDomainMask
                                                  appropriateForURL:nil
                                                             create:YES
                                                              error:&urlError];
   if(urlError){
      static dispatch_once_t onceToken;
      dispatch_once(&onceToken, ^{
         NSLog(@"Error retrieving Application Scripts directoy, %@", urlError);
      });
   }
   return urlError ? nil : baseURL;
}

- (NSUserAppleScriptTask*)appleScriptTask {
   NSUserAppleScriptTask* result = nil;
   if([self hasAppleScriptTaskClass]){
      NSURL *baseURL = [self baseScriptDirectoryURL];
      
      if(baseURL){
         NSError *error = nil;
         NSURL *path = [baseURL URLByAppendingPathComponent:@"Rules.scpt"];
         result = [[NSUserAppleScriptTask alloc] initWithURL:path
                                                       error:&error];
         if(error){
            NSLog(@"Error retrieving apple script task");
         }
      }
   }
   return [result autorelease];
}

-(GrowlNotificationResult)dispatchByClassicWithFilledInDict:(NSDictionary*)aDict {   
   GrowlTicketDatabaseNotification *notification = [self notificationTicketForDict:aDict];
   if (![notification isTicketAllowed]) {
      // Either the app isn't registered or the notification is turned off
      // We should do nothing
      //NSLog(@"The user disabled this notification!");
      return GrowlNotificationResultDisabled;
   }
   
   GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];
   
   [self logNotification:[[aDict copy] autorelease]];
   
   if([preferences isForwardingEnabled])
      [self forwardGrowlDictViaNetwork:[[aDict copy] autorelease]];
   
   [self sendGrowlDictToSubscribers:[[aDict copy] autorelease]];
   
   if(![preferences squelchMode])
   {
      [self displayNotificationUsingDefaultDisplay:aDict];
      [self dispatchNotificationToDefaultConfigSet:aDict];
   }
   
   return GrowlNotificationResultPosted;
}

-(NSAppleEventDescriptor*)notificationDescriptor:(NSDictionary*)dict {
   NSString *host = [dict valueForKey:GROWL_NOTIFICATION_GNTP_SENT_BY];
   if(!host || [host isLocalHost])
      host = @"localhost";
   
/*   NSAppleEventDescriptor *noteDesc = [NSAppleEventDescriptor recordDescriptor];
   NSAppleEventDescriptor *list = [NSAppleEventDescriptor listDescriptor];
   NSInteger index = 1;
   [list insertDescriptor:[NSAppleEventDescriptor descriptorWithString:@"host"] atIndex:index++];
   [list insertDescriptor:[NSAppleEventDescriptor descriptorWithString:host] atIndex:index++];
   [list insertDescriptor:[NSAppleEventDescriptor descriptorWithString:@"app_name"] atIndex:index++];
   [list insertDescriptor:[NSAppleEventDescriptor descriptorWithString:[dict valueForKey:GROWL_APP_NAME]] atIndex:index++];
   [list insertDescriptor:[NSAppleEventDescriptor descriptorWithString:@"note_type"] atIndex:index++];
   [list insertDescriptor:[NSAppleEventDescriptor descriptorWithString:[dict valueForKey:GROWL_NOTIFICATION_NAME]] atIndex:index++];
   [list insertDescriptor:[NSAppleEventDescriptor descriptorWithString:@"note_title"] atIndex:index++];
   [list insertDescriptor:[NSAppleEventDescriptor descriptorWithString:[dict valueForKey:GROWL_NOTIFICATION_TITLE]] atIndex:index++];
   [list insertDescriptor:[NSAppleEventDescriptor descriptorWithString:@"note_description"] atIndex:index++];
   [list insertDescriptor:[NSAppleEventDescriptor descriptorWithString:[dict valueForKey:GROWL_NOTIFICATION_DESCRIPTION]] atIndex:index++];
   [noteDesc setDescriptor:list forKeyword:'usrf'];*/
   
   NSAppleEventDescriptor *noteDesc = [NSAppleEventDescriptor recordDescriptor];
   [noteDesc setDescriptor:[NSAppleEventDescriptor descriptorWithString:host] forKeyword:'NtHs'];
   [noteDesc setDescriptor:[NSAppleEventDescriptor descriptorWithString:[dict valueForKey:GROWL_APP_NAME]] forKeyword:'ApNm'];
   [noteDesc setDescriptor:[NSAppleEventDescriptor descriptorWithString:[dict valueForKey:GROWL_NOTIFICATION_NAME]] forKeyword:'NtTp'];
   [noteDesc setDescriptor:[NSAppleEventDescriptor descriptorWithString:[dict valueForKey:GROWL_NOTIFICATION_TITLE]] forKeyword:'Titl'];
   [noteDesc setDescriptor:[NSAppleEventDescriptor descriptorWithString:[dict valueForKey:GROWL_NOTIFICATION_DESCRIPTION]] forKeyword:'Desc'];
 
   return noteDesc;
}

-(GrowlNotificationResult)dispatchByRuleSwithFilledInDict:(NSDictionary*)dict {
   NSUserAppleScriptTask *applescriptTask = [self appleScriptTask];
   if(!applescriptTask)
      return [self dispatchByClassicWithFilledInDict:dict];
      
   int pid = [[NSProcessInfo processInfo] processIdentifier];
   NSAppleEventDescriptor *thisApplication = [NSAppleEventDescriptor descriptorWithDescriptorType:typeKernelProcessID
                                                                                            bytes:&pid
                                                                                           length:sizeof(pid)];
   
   NSAppleEventDescriptor *event = [NSAppleEventDescriptor appleEventWithEventClass:'ascr'
                                                                            eventID:'psbr'
                                                                   targetDescriptor:thisApplication
                                                                           returnID:kAutoGenerateReturnID
                                                                      transactionID:kAnyTransactionID];
   [event setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:@"evaluate_notification"]
                  forKeyword:'snam'];
   
   
   NSAppleEventDescriptor *record = [NSAppleEventDescriptor listDescriptor];
   [record insertDescriptor:[self notificationDescriptor:dict] atIndex:1];
   [event setParamDescriptor:record
                  forKeyword:keyDirectObject];

   __block NSDictionary *copyDict = [dict copy];
   __block GrowlApplicationController *blockSelf = self;
   [applescriptTask executeWithAppleEvent:event
                        completionHandler:^(NSAppleEventDescriptor *result, NSError *completionError) {
                           dispatch_async(dispatch_get_main_queue(), ^{
                              if(!completionError){
                                 if(result && [result descriptorType] == typeAERecord)
                                 {
                                    if([result descriptorForKeyword:'GrEn']){
                                       if(![[result descriptorForKeyword:'GrEn'] booleanValue]){
                                          [copyDict release];
                                          return;
                                       }
                                    }else{
                                       //Check if it is enabled in the UI
                                       GrowlTicketDatabaseNotification *noteTicket = [self notificationTicketForDict:copyDict];
                                       if(![noteTicket isTicketAllowed]){
                                          [copyDict release];
                                          return;
                                       }
                                    }
                                    
                                    BOOL displayed = NO;
                                    if([result descriptorForKeyword:'GrDs']){
                                       NSString *displayName =[[result descriptorForKeyword:'GrDs'] stringValue];
                                       //NSLog(@"Display using: %@", displayName);
                                       if([displayName caseInsensitiveCompare:@"default"] == NSOrderedSame){
                                          //This is handled below by if(!displayed) section
                                       }else if([displayName caseInsensitiveCompare:@"none"] == NSOrderedSame){
                                          //Dont use any! Setting displayed to yes will fool the bit below to use the default display
                                          displayed = YES;
                                       }else if([displayName caseInsensitiveCompare:@"notification-center"] == NSOrderedSame){
                                          //Explicit NC call
                                          [blockSelf _fireAppleNotificationCenter:dict];
                                          displayed = YES;
                                       }else{
                                          //Find this display if we can, otherwise fall back
                                          GrowlTicketDatabasePlugin *pluginConfig = [[GrowlTicketDatabase sharedInstance] actionForName:displayName];
                                          if(pluginConfig && [pluginConfig canFindInstance]){
                                             [blockSelf displayNotification:copyDict
                                                                 withPlugin:(GrowlDisplayPlugin*)[pluginConfig pluginInstanceForConfiguration]
                                                          withConfiguration:[pluginConfig configuration]];
                                             displayed = YES;
                                          }
                                       }
                                    }
                                    if(!displayed && ![[GrowlPreferencesController sharedController] squelchMode]){
                                       [blockSelf displayNotificationUsingDefaultDisplay:copyDict];
                                    }
                                    
                                    BOOL actedUpon = NO;
                                    if([result descriptorForKeyword:'GrAc']){
                                       NSAppleEventDescriptor *actionsDesc = [result descriptorForKeyword:'GrAc'];
                                       if([actionsDesc descriptorType] == typeAEList){
                                          actedUpon = YES;  //Regardless, yes we acted upon it
                                          NSMutableSet *actionNames = [NSMutableSet set];
                                          for(int i = 1; i <= [actionsDesc numberOfItems]; i++){
                                             [actionNames addObject:[[actionsDesc descriptorAtIndex:i] stringValue]];
                                          }
                                          //NSLog(@"actions: %@", actionNames);
                                          //Build up our action set
                                          NSMutableSet *actions = [NSMutableSet setWithCapacity:[actionNames count]];
                                          [actionNames enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                                             GrowlTicketDatabasePlugin *pluginConfig = [[GrowlTicketDatabase sharedInstance] actionForName:obj];
                                             if(pluginConfig && [pluginConfig canFindInstance]){
                                                [actions addObject:pluginConfig];
                                             }
                                          }];
                                          [blockSelf dispatchNotification:copyDict toActions:actions];
                                       }else if([actionsDesc descriptorType] == typeAEText){
                                          NSString *actionName = [actionsDesc stringValue];
                                          //NSLog(@"use action: %@", [actionsDesc stringValue]);
                                          if([actionName caseInsensitiveCompare:@"default"] == NSOrderedSame) {
                                             //This is handled by the if(!actedUpon) below
                                          }else if([actionName caseInsensitiveCompare:@"none"] == NSOrderedSame) {
                                             //Do nothing! Just like the display, this prevents us from taking the default actions
                                             actedUpon = YES;
                                          }else{
                                             GrowlTicketDatabasePlugin *pluginConfig = [[GrowlTicketDatabase sharedInstance] actionForName:actionName];
                                             if(pluginConfig){
                                                [blockSelf dispatchNotification:copyDict toActions:[NSSet setWithObject:pluginConfig]];
                                                actedUpon = YES;
                                             }
                                          }
                                       }
                                    }
                                    if(!actedUpon && ![[GrowlPreferencesController sharedController] squelchMode]){
                                       [blockSelf dispatchNotificationToDefaultConfigSet:copyDict];
                                    }
                                    
                                    if([result descriptorForKeyword:'GrNF']){
                                       if([[result descriptorForKeyword:'GrNF'] booleanValue])
                                          [blockSelf forwardGrowlDictViaNetwork:[[copyDict copy] autorelease]];
                                    }else{
                                       if([[GrowlPreferencesController sharedController] isForwardingEnabled])
                                          [blockSelf forwardGrowlDictViaNetwork:[[copyDict copy] autorelease]];
                                    }
                                    
                                    if([result descriptorForKeyword:'GrNS']){
                                       if([[result descriptorForKeyword:'GrNS'] booleanValue])
                                          [blockSelf sendGrowlDictToSubscribers:[[copyDict copy] autorelease]];
                                    }else{
                                       [blockSelf sendGrowlDictToSubscribers:[[copyDict copy] autorelease]];
                                    }
                                    
                                    if([result descriptorForKeyword:'GrHL']){
                                       if([[result descriptorForKeyword:'GrHL'] booleanValue])
                                          [blockSelf logNotification:copyDict];
                                    }else{
                                       [blockSelf logNotification:copyDict];
                                    }
                                    
                                 }else{
                                    [blockSelf dispatchByClassicWithFilledInDict:copyDict];
                                 }
                              }else{
                                 NSLog(@"completion error: %@", completionError);
                                 [blockSelf dispatchByClassicWithFilledInDict:copyDict];
                              }
                              
                              [copyDict release];
                           });
                        }];
   return GrowlNotificationResultPosted;
}

- (GrowlNotificationResult) dispatchNotificationWithDictionary:(NSDictionary *)note {
   NSDictionary *dict = [self filledInNotificationDictForDict:note];
   if(!dict)
      return GrowlNotificationResultNotRegistered;
   
   if(![self hasAppleScriptTaskClass] && [self appleScriptTask]){
      return [self dispatchByClassicWithFilledInDict:dict];
   }else{
      return [self dispatchByRuleSwithFilledInDict:dict];
   }
   
   [growlNotificationCenter notifyObservers:dict];
}

-(GrowlTicketDatabaseApplication*)appTicketForDict:(NSDictionary*)dict {
   NSString *appName = [dict objectForKey:GROWL_APP_NAME];
   NSString *hostName = [dict objectForKey:GROWL_NOTIFICATION_GNTP_SENT_BY];
   return [[GrowlTicketDatabase sharedInstance] ticketForApplicationName:appName hostName:hostName];
}

-(GrowlTicketDatabaseNotification*)notificationTicketForDict:(NSDictionary*)dict {
   NSString *notificationName = [dict objectForKey:GROWL_NOTIFICATION_NAME];   
   return [[self appTicketForDict:dict] notificationTicketForName:notificationName];
}

-(NSDictionary*)filledInNotificationDictForDict:(NSDictionary*)dict
{
   NSMutableDictionary *aDict = [dict mutableCopy];
   
   GrowlTicketDatabaseApplication *ticket = [self appTicketForDict:dict];
   //NSLog(@"Dispatching notification from %@: %@", appName, notificationName);
   if (!ticket) {
      //NSLog(@"Never heard of this app!");
      return nil;
   }
   
   GrowlTicketDatabaseNotification *notification = [self notificationTicketForDict:dict];
   if (!notification) {
      // Either the app isn't registered or the notification is turned off
      // We should do nothing
      //NSLog(@"The user disabled this notification!");
      return nil;
   }
   
   // Check icon
   Class NSImageClass = [NSImage class];
   Class NSDataClass  = [NSData  class];
   NSData *iconData = nil;
   id sourceIconData = [aDict objectForKey:GROWL_NOTIFICATION_ICON_DATA];
   if (sourceIconData) {
      if ([sourceIconData isKindOfClass:NSImageClass])
         iconData = [(NSImage *)sourceIconData PNGRepresentation];
      else if ([sourceIconData isKindOfClass:NSDataClass])
         iconData = sourceIconData;
   }
   if (!iconData)
      iconData = [notification iconData];
   if(!iconData)
      iconData = [ticket iconData];
   
   if (iconData)
      [aDict setObject:iconData forKey:GROWL_NOTIFICATION_ICON_DATA];
   else{
      static NSData *defaultIconData = nil;
      static dispatch_once_t onceToken;
      dispatch_once(&onceToken, ^{
         defaultIconData = [[[NSImage imageNamed:NSImageNameApplicationIcon] TIFFRepresentation] retain];
      });
      
      [aDict setObject:defaultIconData forKey:GROWL_NOTIFICATION_ICON_DATA];
   }
   
   // If app icon present, convert to NSImage
   iconData = nil;
   sourceIconData = [aDict objectForKey:GROWL_NOTIFICATION_APP_ICON_DATA];
   if (sourceIconData) {
      if ([sourceIconData isKindOfClass:NSImageClass])
         iconData = [(NSImage *)sourceIconData PNGRepresentation];
      else if ([sourceIconData isKindOfClass:NSDataClass])
         iconData = sourceIconData;
   }
   if (iconData)
      [aDict setObject:iconData forKey:GROWL_NOTIFICATION_APP_ICON_DATA];
   else{
      static NSData *defaultIconData = nil;
      static dispatch_once_t onceToken;
      dispatch_once(&onceToken, ^{
         defaultIconData = [[[NSImage imageNamed:NSImageNameApplicationIcon] TIFFRepresentation] retain];
      });
      
      [aDict setObject:defaultIconData forKey:GROWL_NOTIFICATION_APP_ICON_DATA];
   }
   
   // To avoid potential exceptions, make sure we have both text and title
   if (![aDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION])
      [aDict setObject:@"" forKey:GROWL_NOTIFICATION_DESCRIPTION];
   if (![aDict objectForKey:GROWL_NOTIFICATION_TITLE])
      [aDict setObject:@"" forKey:GROWL_NOTIFICATION_TITLE];
   
   //Retrieve and set the the priority of the notification
   int priority = [[notification priority] intValue];
   NSNumber *value;
   if (priority == GrowlPriorityUnset) {
      value = [dict objectForKey:GROWL_NOTIFICATION_PRIORITY];
      if (!value)
         value = [NSNumber numberWithInt:0];
   } else
      value = [NSNumber numberWithInt:priority];
   [aDict setObject:value forKey:GROWL_NOTIFICATION_PRIORITY];
      
   // Retrieve and set the sticky bit of the notification
   int sticky = [[notification sticky] intValue];
   if (sticky >= 0)
      [aDict setObject:[NSNumber numberWithBool:sticky] forKey:GROWL_NOTIFICATION_STICKY];
   
   BOOL saveScreenshot = [[NSUserDefaults standardUserDefaults] boolForKey:GROWL_SCREENSHOT_MODE];
   [aDict setObject:[NSNumber numberWithBool:saveScreenshot] forKey:GROWL_SCREENSHOT_MODE];
   [aDict setObject:[NSNumber numberWithBool:YES] forKey:GROWL_CLICK_HANDLER_ENABLED];
   
   /* Set a unique ID which we can use globally to identify this particular notification if it doesn't have one */
   if (![aDict objectForKey:GROWL_NOTIFICATION_INTERNAL_ID]) {
      CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
      NSString *uuid = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
      [aDict setValue:uuid
               forKey:GROWL_NOTIFICATION_INTERNAL_ID];
      [uuid release];
      CFRelease(uuidRef);
   }

   return aDict;
}

-(void)displayNotificationUsingDefaultDisplay:(NSDictionary*)dict {
   if ([[GrowlPreferencesController sharedController] shouldUseAppleNotifications]) {
      // We ignore display preferences, and use Notification Center instead.
      [self _fireAppleNotificationCenter:dict];
   }
   else {
      GrowlTicketDatabaseApplication *ticket = [self appTicketForDict:dict];
      GrowlTicketDatabaseNotification *notification = [self notificationTicketForDict:dict];
      if (!ticket || !notification) {
         return;
      }
      
      GrowlTicketDatabaseDisplay *resolvedDisplayConfig = [notification resolvedDisplayConfig];
      GrowlDisplayPlugin *display = (GrowlDisplayPlugin*)[resolvedDisplayConfig pluginInstanceForConfiguration];
      NSMutableDictionary *configCopy = [[[resolvedDisplayConfig configuration] mutableCopy] autorelease];
      if(!configCopy)
         configCopy = [NSMutableDictionary dictionary];
      [configCopy setValue:[NSNumber numberWithInt:[ticket resolvedDisplayOrigin]] forKey:@"com.growl.positioncontroller.selectedposition"];
      [configCopy setValue:[resolvedDisplayConfig configID] forKey:GROWL_PLUGIN_CONFIG_ID];
      [self displayNotification:dict withPlugin:display withConfiguration:configCopy];
   }
}

-(void)displayNotification:(NSDictionary*)note withPlugin:(GrowlDisplayPlugin*)plugin withConfiguration:(NSDictionary*)configDict {
   if([plugin conformsToProtocol:@protocol(GrowlDispatchNotificationProtocol)]){
      [plugin dispatchNotification:note withConfiguration:configDict];
   }
}

-(void)dispatchNotificationToDefaultConfigSet:(NSDictionary*)note {
   GrowlTicketDatabaseNotification *notification = [self notificationTicketForDict:note];
   if (!notification)
      return;
   [self dispatchNotification:note toActions:[notification resolvedActionConfigSet]];
}

-(void)dispatchNotification:(NSDictionary*)note toActions:(NSSet*)configSet {
   [configSet enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
      GrowlActionPlugin *action = (GrowlActionPlugin*)[obj pluginInstanceForConfiguration];
      NSDictionary *copyDict = [[note copy] autorelease];
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
         if([action conformsToProtocol:@protocol(GrowlDispatchNotificationProtocol)]){
            NSMutableDictionary *actionConfigCopy = [[[obj configuration] mutableCopy] autorelease];
            if(!actionConfigCopy)
               actionConfigCopy = [NSMutableDictionary dictionary];
            [actionConfigCopy setValue:[obj configID] forKey:GROWL_PLUGIN_CONFIG_ID];
            [(id<GrowlDispatchNotificationProtocol>)action dispatchNotification:copyDict withConfiguration:actionConfigCopy];
         }
      });
   }];
}

-(void)sendGrowlDictToSubscribers:(NSDictionary*)note {
   [[GNTPSubscriptionController sharedController] forwardNotification:note];
}

-(void)forwardGrowlDictViaNetwork:(NSDictionary*)note {
   [[GNTPForwarder sharedController] forwardNotification:note];
}

-(void)logNotification:(NSDictionary*)note {
   [[GrowlNotificationDatabase sharedInstance] logNotificationWithDictionary:note];
}

- (BOOL) registerApplicationWithDictionary:(NSDictionary *)userInfo {
	[[GrowlLog sharedController] writeRegistrationDictionaryToLog:userInfo];

	NSString *appName = [userInfo objectForKey:GROWL_APP_NAME];
   if(!appName){
      NSLog(@"Cannot register an application without a name!");
      return NO;
   }
	BOOL success = [[GrowlTicketDatabase sharedInstance] registerApplication:userInfo];

	if (success) {
      [[NSNotificationCenter defaultCenter] postNotificationName:@"ApplicationRegistered"
                                                          object:nil 
                                                        userInfo:[[userInfo copy] autorelease]];
	}
   return success;
}

#pragma mark Version of Growl

+ (NSString *) growlVersion {
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
}

- (NSDictionary *) versionDictionary {
	if (!versionInfo) {
		NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];

		// Due to the way NSAssert1 works, this will generate an unused variable
		// warning if we compile in release mode.  With -Wall -Werror on, this is
		// Bad Juju.  So we need to use gcc compiler attributes to cancel the error.
		BOOL parseSucceeded __attribute__((unused)) = parseVersionString(versionString, &version);
		NSAssert1(parseSucceeded, @"Could not parse version string: %@", versionString);
		
		if (version.releaseType == releaseType_vcs)
			version.development = (u_int32_t)VCS_REVISION;

		NSNumber *major = [[NSNumber alloc] initWithUnsignedShort:version.major];
		NSNumber *minor = [[NSNumber alloc] initWithUnsignedShort:version.minor];
		NSNumber *incremental = [[NSNumber alloc] initWithUnsignedChar:version.incremental];
		NSNumber *releaseType = [[NSNumber alloc] initWithUnsignedChar:version.releaseType];
		NSNumber *development = [[NSNumber alloc] initWithUnsignedShort:version.development];

		versionInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
			[GrowlApplicationController growlVersion], (NSString *)kCFBundleVersionKey,

			major,                                     @"Major version",
			minor,                                     @"Minor version",
			incremental,                               @"Incremental version",
			releaseTypeNames[version.releaseType],     @"Release type name",
			releaseType,                               @"Release type",
			development,                               @"Development version",

			nil];

		[major       release];
		[minor       release];
		[incremental release];
		[releaseType release];
		[development release];
	}
	return versionInfo;
}

//this method could be moved to Growl.framework, I think.
//pass nil to get GrowlHelperApp's version as a string.
- (NSString *)stringWithVersionDictionary:(NSDictionary *)d {
	if (!d)
		d = [self versionDictionary];

	//0.6
	NSMutableString *result = [NSMutableString stringWithFormat:@"%@.%@",
		[d objectForKey:@"Major version"],
		[d objectForKey:@"Minor version"]];

	//the .1 in 0.6.1
	NSNumber *incremental = [d objectForKey:@"Incremental version"];
	if ([incremental unsignedShortValue])
		[result appendFormat:@".%@", incremental];

	NSString *releaseTypeName = [d objectForKey:@"Release type name"];
	if ([releaseTypeName length]) {
		//"" (release), "b4", " SVN 900"
		[result appendFormat:@"%@%@", releaseTypeName, [d objectForKey:@"Development version"]];
	}

	return result;
}

#pragma mark Accessors

- (IBAction)quitWithWarning:(id)sender
{
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"HideQuitWarning"])
    {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Are you sure you want to quit?", nil)
                                         defaultButton:NSLocalizedString(@"Yes", nil)
                                       alternateButton:NSLocalizedString(@"No", nil)
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"If you quit Growl you will no longer receive notifications.", nil)];
        [alert setShowsSuppressionButton:YES];
        
        NSInteger result = [alert runModal];
        if(result == NSOKButton)
        {
            [[NSUserDefaults standardUserDefaults] setBool:[[alert suppressionButton] state] forKey:@"HideQuitWarning"];
            [NSApp terminate:self];
        }
    }
    else
        [NSApp terminate:self];
}
#pragma mark Notifications (not the Growl kind)

- (void) preferencesChanged:(NSNotification *) note {
	@autoreleasepool {
		//[note object] is the changed key. A nil key means reload our tickets.
		id object = [note object];
		
		if (!note || (object && [object isEqual:GrowlStartServerKey])) {
			Class pathwayControllerClass = NSClassFromString(@"GrowlPathwayController");
			if (pathwayControllerClass)
				[(id)[pathwayControllerClass sharedController] setServerEnabledFromPreferences];
		}
	}
}

- (void) replyToPing:(NSNotification *) note {
	@autoreleasepool {
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_PONG
                                                                       object:nil
                                                                     userInfo:nil
                                                           deliverImmediately:NO];
    }
}

- (void)firstLaunchClosed
{
    if(firstLaunchWindow){
        //[firstLaunchWindow release];
        firstLaunchWindow = nil;
    }
}

- (void) showPreferences
{
   if(!preferencesWindow)
      preferencesWindow = [[GrowlPreferencePane alloc] initWithWindowNibName:@"GrowlPref"];
   
   [NSApp activateIgnoringOtherApps:YES];
   [preferencesWindow showWindow:self];
}

- (void)closeAllNotifications
{
    [[NSNotificationCenter defaultCenter] postNotificationName:GROWL_CLOSE_ALL_NOTIFICATIONS
                                                    object:nil];
}

- (void) toggleRollup
{
    BOOL show = ![[GrowlPreferencesController sharedController] isRollupShown];
    [[GrowlPreferencesController sharedController] setRollupShown:show];
}

- (void) toggleStatusItem:(BOOL)toggle
{
   if(!statusMenu)
      self.statusMenu = [[[GrowlMenu alloc] init] autorelease];
   [statusMenu toggleStatusMenu:toggle];
}

- (void) updateMenu:(NSInteger)state
{
   switch (state) {
      case GrowlStatusMenu:
      case GrowlBothMenus:
         [self toggleStatusItem:YES];
         break;
      case GrowlDockMenu:
      case GrowlNoMenu:
         [self toggleStatusItem:NO];
         break;
      default:
         break;
   }
}

-(void)parseURLString:(NSString*)urlString 
{   
   NSString *shortened = [urlString stringByReplacingOccurrencesOfString:@"growl://" withString:@""];
   NSArray *components = [shortened componentsSeparatedByString:@"/"];
   if([components count] == 0)
      return;
   
   GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];
   if([[components objectAtIndex:0] caseInsensitiveCompare:@"preferences"] == NSOrderedSame){
      [self showPreferences];
      if([components count] > 1){
         NSString *tab = [components objectAtIndex:1];
         if([tab caseInsensitiveCompare:@"general"] == NSOrderedSame) {
            [preferences setSelectedPreferenceTab:0];
         }else if([tab caseInsensitiveCompare:@"applications"] == NSOrderedSame){
            [preferences setSelectedPreferenceTab:1];
            if([components count] > 2){
               NSString *app = [components objectAtIndex:2];
               NSString *host = nil;
               NSString *note = nil;
               if([components count] > 3 && ![[components objectAtIndex:3] isEqualToString:@""])
                  host = [components objectAtIndex:3];
               if([components count] > 4 && ![[components objectAtIndex:4] isEqualToString:@""])
                  note = [components objectAtIndex:4];
               GrowlApplicationsViewController *appsView = [[preferencesWindow prefViewControllers] valueForKey:[GrowlApplicationsViewController nibName]];
               [appsView selectApplication:app hostName:host notificationName:note]; 
            }
         }else if([tab caseInsensitiveCompare:@"displays"] == NSOrderedSame){
            [preferences setSelectedPreferenceTab:2];
            if([components count] > 2){
               NSString *display = [components objectAtIndex:2];
               GrowlDisplaysViewController *displaysView = [[preferencesWindow prefViewControllers] valueForKey:[GrowlDisplaysViewController nibName]];
               [displaysView selectPlugin:display];
            }
         }else if([tab caseInsensitiveCompare:@"network"] == NSOrderedSame){
            [preferences setSelectedPreferenceTab:3];
            if([components count] > 2){
               NSString *forwardSubscribe = [components objectAtIndex:2];
               NSUInteger tabToSelect = NSNotFound;
               if([forwardSubscribe caseInsensitiveCompare:@"forwarding"] == NSOrderedSame){
                  tabToSelect = 0;
               }else if([forwardSubscribe caseInsensitiveCompare:@"subscriptions"] == NSOrderedSame){
                  tabToSelect = 1;
               }else if([forwardSubscribe caseInsensitiveCompare:@"subscribers"] == NSOrderedSame){
                  tabToSelect = 2;
               }
               GrowlServerViewController *networkView = [[preferencesWindow prefViewControllers] valueForKey:[GrowlServerViewController nibName]];
               dispatch_async(dispatch_get_main_queue(), ^{
                  [networkView showNetworkConnectionTab:tabToSelect];
               });
            }
         }else if([tab caseInsensitiveCompare:@"rollup"] == NSOrderedSame){
            [preferences setSelectedPreferenceTab:4];
         }else if([tab caseInsensitiveCompare:@"history"] == NSOrderedSame){
            [preferences setSelectedPreferenceTab:5];
         }else if([tab caseInsensitiveCompare:@"about"] == NSOrderedSame){
            [preferences setSelectedPreferenceTab:6];
         }
      }
   }
}

- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
   NSString *url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
   NSString *escaped = [url stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
   if(!escaped || [escaped isEqualToString:@""])
      return;
   if(![escaped hasPrefix:@"growl://"])
      return;
   
   if(!growlFinishedLaunching){
      if(urlOnLaunch){
         NSLog(@"Replacing URL to handle %@ with %@", urlOnLaunch, escaped);
         [urlOnLaunch release];
      }
      urlOnLaunch = [escaped retain];
      return;
   }else{
      [self parseURLString:escaped];
   }
}

#pragma mark NSApplication Delegate Methods

- (NSMenu*)applicationDockMenu:(NSApplication*)app
{
   return [statusMenu createMenu:YES];
}

- (BOOL) application:(NSApplication *)theApplication openFile:(NSString *)filename {
   BOOL retVal = NO;

	NSString *pathExtension = [filename pathExtension];

	if ([pathExtension isEqualToString:GROWL_REG_DICT_EXTENSION]) {
		//If the auto-quit flag is set, it's probably because we are not the real GHA—we're some other GHA that a broken (pre-1.1.3) GAB opened this file with. If that's the case, find the real one and open the file with it.
		BOOL registerItOurselves = YES;
		NSString *realHelperAppBundlePath = nil;

		//But, just to make sure we don't infinitely loop, make sure this isn't our own bundle.
		NSString *ourBundlePath = [[NSBundle mainBundle] bundlePath];
		realHelperAppBundlePath = [[GrowlPathUtilities runningHelperAppBundle] bundlePath];
		if (![ourBundlePath isEqualToString:realHelperAppBundlePath])
			registerItOurselves = NO;

		if (registerItOurselves) {
			//We are the real GHA.
			//Have the property-list-file pathway process this registration dictionary file.
			GrowlPropertyListFilePathway *pathway = [GrowlPropertyListFilePathway standardPathway];
			[pathway application:theApplication openFile:filename];
            retVal = YES;
		} else {
			//We're definitely not the real GHA, so pass it to the real GHA to be registered.
			[[NSWorkspace sharedWorkspace] openFile:filename
									withApplication:realHelperAppBundlePath];
		}
	} else {
		GrowlPluginController *controller = [GrowlPluginController sharedController];
		//the set returned by GrowlPluginController is case-insensitive. yay!
		if ([[controller registeredPluginTypes] containsObject:pathExtension]) {
			[controller installPluginFromPath:filename];

			retVal = YES;
		}
	}
	return retVal;
}

- (void) applicationWillFinishLaunching:(NSNotification *)aNotification {
	NSFileManager *fs = [NSFileManager defaultManager];

	NSString *destDir, *subDir;
	NSArray *searchPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, /*expandTilde*/ YES);

	destDir = [searchPath objectAtIndex:0U]; //first == last == ~/Library
	destDir = [destDir stringByAppendingPathComponent:@"Application Support"];
	destDir = [destDir stringByAppendingPathComponent:@"Growl"];

	subDir  = [destDir stringByAppendingPathComponent:@"Plugins"];
	[fs createDirectoryAtPath:subDir withIntermediateDirectories:YES attributes:nil error:nil];
}

#if defined(BETA) && BETA
#define DAYSTOEXPIRY 21
- (NSCalendarDate *)dateWithString:(NSString *)str {
	str = [str stringByReplacingOccurrencesOfString:@"  " withString:@" "];
	NSArray *dateParts = [str componentsSeparatedByString:@" "];
	int month = 1;
	NSString *monthString = [dateParts objectAtIndex:0];
	if ([monthString isEqualToString:@"Feb"]) {
		month = 2;
	} else if ([monthString isEqualToString:@"Mar"]) {
		month = 3;
	} else if ([monthString isEqualToString:@"Apr"]) {
		month = 4;
	} else if ([monthString isEqualToString:@"May"]) {
		month = 5;
	} else if ([monthString isEqualToString:@"Jun"]) {
		month = 6;
	} else if ([monthString isEqualToString:@"Jul"]) {
		month = 7;
	} else if ([monthString isEqualToString:@"Aug"]) {
		month = 8;
	} else if ([monthString isEqualToString:@"Sep"]) {
		month = 9;
	} else if ([monthString isEqualToString:@"Oct"]) {
		month = 10;
	} else if ([monthString isEqualToString:@"Nov"]) {
		month = 11;
	} else if ([monthString isEqualToString:@"Dec"]) {
		month = 12;
	}
	
	NSString *dateString = [NSString stringWithFormat:@"%@-%d-%@ 00:00:00 +0000", [dateParts objectAtIndex:2], month, [dateParts objectAtIndex:1]];
	return [NSCalendarDate dateWithString:dateString];
}

- (BOOL)expired
{
    BOOL result = YES;
    
    NSCalendarDate* nowDate = [self dateWithString:[NSString stringWithUTF8String:__DATE__]];
    NSCalendarDate* expiryDate = [nowDate dateByAddingTimeInterval:(60*60*24* DAYSTOEXPIRY)];
    
    if ([expiryDate earlierDate:[NSDate date]] != expiryDate)
        result = NO;
    
    return result;
}

- (void)expiryCheck
{
    if([self expired])
    {
        [NSApp activateIgnoringOtherApps:YES];
        NSInteger alert = NSRunAlertPanel(@"This Beta Has Expired", [NSString stringWithFormat:@"Please download a new version to keep using %@.", [[NSProcessInfo processInfo] processName]], @"Quit", nil, nil);
        if (alert == NSOKButton) 
        {
            [NSApp terminate:self];
        }
    }
}
#endif

- (void) checkForCorruption
{
    //check to see if any of the path components in our path include prefPane
    for(NSString *component in [[[NSBundle mainBundle] bundlePath] pathComponents])
    {
        if([component rangeOfString:@"prefPane"].location != NSNotFound)
        {
            NSInteger alert = NSRunAlertPanel(
                                              NSLocalizedString(@"Corrupt install detected", @"we've detected a corrupt install in this currently running binary"),
                                              NSLocalizedString(@"We've detected that the Mac App Store left you with a corrupt install.  Please follow the instructions the button takes you to in order to remedy the situation.", @"corrupt install alert"), 
                                              NSLocalizedString(@"Read Instructions and Quit", @"button for reading the instructions for fixing your install"), nil, nil);
            if (alert == NSOKButton) 
            {
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://growl.info/growlinstallcorrupt"]];
                [NSApp terminate:self];
}
        }
    }
}
//Post a notification when we are done launching so the application bridge can inform participating applications
- (void) applicationDidFinishLaunching:(NSNotification *)aNotification {
#if defined(BETA) && BETA
	[self expiryCheck];
#endif

    [self checkForCorruption];

	// initialize GrowlPreferencesController before observing GrowlPreferencesChanged
	GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];
	[GrowlNetworkObserver sharedObserver];
	[GNTPForwarder sharedController];
	[GNTPSubscriptionController sharedController];
   
	//register value transformer
	id transformer = [[[GrowlImageTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"GrowlImageTransformer"];
	
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	[nc addObserver:self
			 selector:@selector(preferencesChanged:)
				  name:GrowlPreferencesChanged
				object:nil];
	[nc addObserver:self
			 selector:@selector(showPreview:)
				  name:GrowlPreview
				object:nil];
	[nc addObserver:self
			 selector:@selector(replyToPing:)
				  name:GROWL_PING
				object:nil];
	
	[nc addObserver:self
			 selector:@selector(notificationClicked:)
				  name:GROWL_NOTIFICATION_CLICKED
				object:nil];
	[nc addObserver:self
			 selector:@selector(notificationTimedOut:)
				  name:GROWL_NOTIFICATION_TIMED_OUT
				object:nil];
	
	[self versionDictionary];
	
   NSDistributedNotificationCenter *dnc = [NSDistributedNotificationCenter defaultCenter];
   [dnc addObserver:self
           selector:@selector(notificationCenterQuery:)
               name:GROWL_DISTRIBUTED_NOTIFICATION_NOTIFICATIONCENTER_QUERY
             object:nil];
   
	NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"GrowlDefaults" withExtension:@"plist"];
	NSDictionary *defaultDefaults = [NSDictionary dictionaryWithContentsOfURL:fileURL];
	if (defaultDefaults) {
		[preferences registerDefaults:defaultDefaults];
	}
	
	//This class doesn't exist in the prefpane.
	Class pathwayControllerClass = NSClassFromString(@"GrowlPathwayController");
	if (pathwayControllerClass)
		[pathwayControllerClass sharedController];
	
	[self preferencesChanged:nil];
	
	[GrowlIdleStatusObserver sharedObserver];
	
	// create and register GrowlNotificationCenter
	growlNotificationCenter = [[GrowlNotificationCenter alloc] init];
	growlNotificationCenterConnection = [[NSConnection alloc] initWithReceivePort:[NSPort port] sendPort:nil];
	//[growlNotificationCenterConnection enableMultipleThreads];
	[growlNotificationCenterConnection setRootObject:growlNotificationCenter];
	if (![growlNotificationCenterConnection registerName:@"GrowlNotificationCenter"])
		NSLog(@"WARNING: could not register GrowlNotificationCenter for interprocess access");
	
	[GrowlPluginController sharedController];
	[[GrowlNotificationDatabase sharedInstance] setupMaintenanceTimers];
	[[GrowlTicketDatabase sharedInstance] upgradeFromTicketFiles];
	
	if([GrowlFirstLaunchWindowController shouldRunFirstLaunch]){
		[[GrowlPreferencesController sharedController] setBool:NO forKey:GrowlFirstLaunch];
		firstLaunchWindow = [[GrowlFirstLaunchWindowController alloc] init];
		[NSApp activateIgnoringOtherApps:YES];
		[firstLaunchWindow showWindow:self];
		[[firstLaunchWindow window] makeKeyWindow];
	}
	
	
   NSInteger menuState = [[GrowlPreferencesController sharedController] menuState];
   switch (menuState) {
      case GrowlDockMenu:
      case GrowlBothMenus:
         [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
      default:
         //No need to do anything, we hide in the shadows
         break;
   }
   [self updateMenu:menuState];
   
   [[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_IS_READY
	                                                               object:nil
	                                                             userInfo:nil
	                                                   deliverImmediately:YES];
   
   // Now we check if we have notification center
   if (NSClassFromString(@"NSUserNotificationCenter")) {
      // We do!  Are we supposed to use it?
      NSString *notificationCenterEnabledNotice = GROWL_DISTRIBUTED_NOTIFICATION_NOTIFICATIONCENTER_OFF;

      if ([preferences shouldUseAppleNotifications]) {
         notificationCenterEnabledNotice = GROWL_DISTRIBUTED_NOTIFICATION_NOTIFICATIONCENTER_ON;
      }
      
      [[NSDistributedNotificationCenter defaultCenter] postNotificationName:notificationCenterEnabledNotice
                                                                     object:nil
                                                                   userInfo:nil
                                                         deliverImmediately:YES];
   }
   
	growlFinishedLaunching = YES;
   
   if(urlOnLaunch){
      [self parseURLString:urlOnLaunch];
      [urlOnLaunch release];
      urlOnLaunch = nil;
   }
}

//Same as applicationDidFinishLaunching, called when we are asked to reopen (that is, we are already running)
//We return yes, so we can handle activating the right window.
- (BOOL) applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
   GrowlNotificationDatabase *db = [GrowlNotificationDatabase sharedInstance];
   //If we have notes in the rollup, and the rollup isn't visible, bring that up first
   //Else, just bring up preferences
   if([db notificationsWhileAway] && ![[[db historyWindow] window] isVisible])
      [[GrowlPreferencesController sharedController] setRollupShown:YES];
   else
      [self showPreferences];
    return YES;
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
	return NO;
}

#pragma mark Growl Application Bridge delegate

/*click feedback comes here first. GAB picks up the DN and calls our
 *	-growlNotificationWasClicked:/-growlNotificationTimedOut: with it if it's a
 *	GHA notification.
 */
- (void)growlNotificationDict:(NSDictionary *)growlNotificationDict didCloseViaNotificationClick:(BOOL)viaClick onLocalMachine:(BOOL)wasLocal
{
	static BOOL isClosingFromRemoteClick = NO;
	/* Don't post a second close notification on the local machine if we close a notification from this method in
	 * response to a click on a remote machine.
	 */
	if (isClosingFromRemoteClick)
		return;
	
	id clickContext = [growlNotificationDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
   id callbackTarget = [growlNotificationDict objectForKey:GROWL_NOTIFICATION_CALLBACK_URL_TARGET];
   if(callbackTarget && viaClick) {
      NSURL *callbackURL = nil;
      if([callbackTarget isKindOfClass:[NSURL class]]){
         callbackURL = callbackTarget;
      }else if([callbackTarget isKindOfClass:[NSString class]]){
         callbackURL = [NSURL URLWithString:callbackTarget];
      }
      
      if(callbackURL)
         [[NSWorkspace sharedWorkspace] openURL:callbackURL];
   } else if (clickContext) {
//		NSString *suffix, *growlNotificationClickedName;
//		NSDictionary *clickInfo;
//		
//		NSString *appName = [growlNotificationDict objectForKey:GROWL_APP_NAME];
//      NSString *hostName = [growlNotificationDict objectForKey:GROWL_NOTIFICATION_GNTP_SENT_BY];
//		GrowlApplicationTicket *ticket = [ticketController ticketForApplicationName:appName hostName:hostName];
//		
//		if (viaClick && [ticket clickHandlersEnabled]) {
//			suffix = GROWL_DISTRIBUTED_NOTIFICATION_CLICKED_SUFFIX;
//		} else {
//			/*
//			 * send GROWL_NOTIFICATION_TIMED_OUT instead, so that an application is
//			 * guaranteed to receive feedback for every notification.
//			 */
//			suffix = GROWL_DISTRIBUTED_NOTIFICATION_TIMED_OUT_SUFFIX;
//		}
//		
//		//Build the application-specific notification name
//		NSNumber *pid = [growlNotificationDict objectForKey:GROWL_APP_PID];
//		if (pid)
//			growlNotificationClickedName = [[NSString alloc] initWithFormat:@"%@-%@-%@",
//											appName, pid, suffix];
//		else
//			growlNotificationClickedName = [[NSString alloc] initWithFormat:@"%@%@",
//											appName, suffix];
//		clickInfo = [NSDictionary dictionaryWithObject:clickContext
//												forKey:GROWL_KEY_CLICKED_CONTEXT];
//		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:growlNotificationClickedName
//																	   object:nil
//																	 userInfo:clickInfo
//														   deliverImmediately:YES];
//		[growlNotificationClickedName release];
	}
	
	if (!wasLocal) {
		isClosingFromRemoteClick = YES;
		[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_CLOSE_NOTIFICATION
															object:[growlNotificationDict objectForKey:GROWL_NOTIFICATION_INTERNAL_ID]];
		isClosingFromRemoteClick = NO;
	}
}

@end

#pragma mark -

@implementation GrowlApplicationController (PRIVATE)

#pragma mark Click feedback from displays

- (void) notificationClicked:(NSNotification *)notification {
	GrowlNotification *growlNotification = [notification object];
		
	[self growlNotificationDict:[growlNotification dictionaryRepresentation] didCloseViaNotificationClick:YES onLocalMachine:YES];
}

- (void) notificationTimedOut:(NSNotification *)notification {
	GrowlNotification *growlNotification = [notification object];
	
	[self growlNotificationDict:[growlNotification dictionaryRepresentation] didCloseViaNotificationClick:NO onLocalMachine:YES];
}

- (void) notificationCenterQuery:(NSNotification *)notification {
   NSString *notificationCenterEnabledNotice = GROWL_DISTRIBUTED_NOTIFICATION_NOTIFICATIONCENTER_OFF;
   
   if (NSClassFromString(@"NSUserNotificationCenter")) {
      // We have notification center!  Are we supposed to use it?
      
      if ([[GrowlPreferencesController sharedController] shouldUseAppleNotifications]) {
         notificationCenterEnabledNotice = GROWL_DISTRIBUTED_NOTIFICATION_NOTIFICATIONCENTER_ON;
      }
   }

   // Inform applications.  Unfortunately, this means telling everyone, but
   // it's the only way to guarantee an app gets this information when querying.
   [[NSDistributedNotificationCenter defaultCenter] postNotificationName:notificationCenterEnabledNotice
                                                                  object:nil
                                                                userInfo:nil
                                                      deliverImmediately:YES];
}

@end
