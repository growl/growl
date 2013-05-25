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
#import "GrowlTicketDatabaseDisplay.h"
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
#import "GrowlXPCCommunicationAttempt.h"
#import <GrowlPlugins/GrowlNotification.h>
#import <GrowlPlugins/GrowlPlugin.h>
#import <GrowlPlugins/GrowlDisplayPlugin.h>
#import <GrowlPlugins/GrowlActionPlugin.h>
#import <GrowlPlugins/GrowlKeychainUtilities.h>
#import <GrowlPlugins/GrowlUserScriptTaskUtilities.h>

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
      NSString *notificationType = GROWL_NOTIFICATION_CLICKED;
      
      if(notification.activationType == NSUserNotificationActivationTypeActionButtonClicked) {
         // Action button clicked
         NSMutableDictionary *temporaryNotificationDict = [growlNotificationDict mutableCopy];
         [temporaryNotificationDict setObject:[NSNumber numberWithBool:YES] forKey:GROWL_NOTIFICATION_CLICK_BUTTONUSED];
      }
      else if (notification.activationType == NSUserNotificationActivationTypeNone) {
         // Cancel button clicked *or* the item was removed from Notification Center with the (X) button,
         // so we'll handle this case as a timeout.
         notificationType = GROWL_NOTIFICATION_TIMED_OUT;
      }
      
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
		NSLog(@"Checking for captured displays: Could not count displays: %li", (long)err);
	else {
		CGDirectDisplayID *displays = malloc(numDisplays * sizeof(CGDirectDisplayID));
		CGGetActiveDisplayList(numDisplays, displays, /*numDisplays*/ NULL);

		if (!displays)
			NSLog(writeToLog:@"Checking for captured displays: Could not allocate list of displays: %s", strerror(errno));
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

   //If the note came from a 3.0 framework, and it hasn't already been displayed, tell it to display
	BOOL dispatchedToBark = [self sendNotificationDict:growlDict feedbackOfType:@"GROWL3_NOTIFICATION_SHOW_NOTIFICATION_CENTER"];
   
	//Here we have a choice to make, use Bark, or our own NC implementation. Bark is better due to icon thing
	GrowlTicketDatabasePlugin *barkPluginConfig = [[GrowlTicketDatabase sharedInstance] pluginConfigForBundleID:@"us.pandamonia.Bark"];
	if(!dispatchedToBark &&
      barkPluginConfig &&
      [barkPluginConfig pluginInstanceForConfiguration]){
		[self dispatchNotification:growlDict toActions:[NSSet setWithObject:barkPluginConfig]];
		dispatchedToBark = YES;
	}
	if(!dispatchedToBark){
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
		appleNotification.hasActionButton = NO;
		
		if ([growlDict objectForKey:GROWL_NOTIFICATION_BUTTONTITLE_ACTION]) {
			appleNotification.hasActionButton = YES;
			appleNotification.actionButtonTitle = [growlDict objectForKey:GROWL_NOTIFICATION_BUTTONTITLE_ACTION];
		}
		
		if ([growlDict objectForKey:GROWL_NOTIFICATION_BUTTONTITLE_CANCEL])
			appleNotification.otherButtonTitle = [growlDict objectForKey:GROWL_NOTIFICATION_BUTTONTITLE_CANCEL];
		
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			appleNotificationDelegate = [[GrowlApplicationNotificationCenterDelegate alloc] init];
		});
		[appleNotificationDelegate.growlDicts setObject:notificationDict forKey:noteKey];
		
		[[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:appleNotificationDelegate];
		[[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:appleNotification];
		[appleNotification release];
	}
#endif
}

#pragma mark Dispatching notifications

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
      [self displayNotificationUsingDefaultDisplayInDefaultPosition:aDict];
      [self dispatchNotificationToDefaultConfigSet:aDict];
   }
   
   return GrowlNotificationResultPosted;
}

-(GrowlNotificationResult)dispatchByRuleSwithFilledInDict:(NSDictionary*)dict {
   NSUserAppleScriptTask *applescriptTask = [GrowlUserScriptTaskUtilities rulesScriptTask];
   if(!applescriptTask)
      return [self dispatchByClassicWithFilledInDict:dict];
      
   int pid = [[NSProcessInfo processInfo] processIdentifier];
   NSAppleEventDescriptor *thisApplication = [NSAppleEventDescriptor descriptorWithDescriptorType:typeKernelProcessID
                                                                                            bytes:&pid
                                                                                           length:sizeof(pid)];
   //GrRuNtEv
   NSAppleEventDescriptor *event = [NSAppleEventDescriptor appleEventWithEventClass:'GrRu'
                                                                            eventID:'NtEv'
                                                                   targetDescriptor:thisApplication
                                                                           returnID:kAutoGenerateReturnID
                                                                      transactionID:kAnyTransactionID];
   [event setDescriptor:[GrowlUserScriptTaskUtilities appleEventDescriptorForNotification:dict] forKeyword:'NtPa'];

   BOOL logRuleResult = [[GrowlPreferencesController sharedController] rulesLoggingEnabled];
   //NSDate *startDate = [NSDate date];
   __block NSDictionary *copyDict = [dict copy];
   __block GrowlApplicationController *blockSelf = self;
   [applescriptTask executeWithAppleEvent:event
                        completionHandler:^(NSAppleEventDescriptor *result, NSError *completionError) {
                           dispatch_async(dispatch_get_main_queue(), ^{
                              NSMutableString *ruleLogString = logRuleResult ? [NSMutableString stringWithString:@"RuleResult for note:"] : nil;
                              if(logRuleResult){
                                 //[ruleLogString appendFormat:@"Rule evaluation took: %.3f seconds", -[startDate timeIntervalSinceNow]];
                                 NSString *host = [dict valueForKey:GROWL_NOTIFICATION_GNTP_SENT_BY];
                                 if(!host || [host isLocalHost])
                                    host = @"localhost";
                                 [ruleLogString appendFormat:@"\nhost: %@", host];
                                 [ruleLogString appendFormat:@"\napp: %@", [dict valueForKey:GROWL_APP_NAME]];
                                 [ruleLogString appendFormat:@"\ntype: %@", [dict valueForKey:GROWL_NOTIFICATION_NAME]];
                                 [ruleLogString appendFormat:@"\ntitle: %@", [dict valueForKey:GROWL_NOTIFICATION_TITLE]];
                                 [ruleLogString appendFormat:@"\ndescription: %@", [dict valueForKey:GROWL_NOTIFICATION_DESCRIPTION]];
                                 [ruleLogString appendFormat:@"\nsticky: %@\n", [[dict valueForKey:GROWL_NOTIFICATION_STICKY] boolValue] ? @"YES" : @"NO"];
                              }
                              if(!completionError){
                                 if(result && [result descriptorType] == typeAERecord)
                                 {
												NSAppleEventDescriptor *enabled = [result descriptorForKeyword:'GrEN'];
                                    if(enabled &&
													[GrowlUserScriptTaskUtilities isAppleEventDescriptorBoolean:enabled] &&
													![[result descriptorForKeyword:'GrEN'] booleanValue])
												{
													if(logRuleResult){
														[ruleLogString appendFormat:@"\nRule result returned enabled set to no"];
														NSLog(ruleLogString);
													}
													[copyDict release];
													return;
                                    }else{
                                       //Check if it is enabled in the UI
                                       GrowlTicketDatabaseNotification *noteTicket = [self notificationTicketForDict:copyDict];
                                       if(![noteTicket isTicketAllowed]){
                                          if(logRuleResult){
                                             [ruleLogString appendFormat:@"\nRule result did not return enabled, note disabled in UI"];
                                             NSLog(ruleLogString);
                                          }
                                          [copyDict release];
                                          return;
                                       }
                                    }
                                    
                                    if([result descriptorForKeyword:'NtRt']){
                                       NSMutableDictionary *mutableCopy = [copyDict mutableCopy];
                                       NSString *title = nil;
                                       NSString *description = nil;
                                       NSData *iconData = nil;
                                       NSAppleEventDescriptor *notification = [result descriptorForKeyword:'NtRt'];
                                       NSAppleEventDescriptor *sticky = [notification descriptorForKeyword:'Stic'];
													NSInteger priority = GrowlPriorityUnset;
													
                                       if([notification descriptorForKeyword:'Titl']){
                                          title = [[notification descriptorForKeyword:'Titl'] stringValue];
                                       }
                                       if([notification descriptorForKeyword:'Desc']){
                                          description = [[notification descriptorForKeyword:'Desc'] stringValue];
                                       }
                                       if([notification descriptorForKeyword:'Icon']){
                                          iconData = [[notification descriptorForKeyword:'Icon'] data];
                                       }
													if([notification descriptorForKeyword:'Prio']){
														switch ([[notification descriptorForKeyword:'Prio'] enumCodeValue]) {
															case 'PrVL':
																priority = GrowlPriorityVeryLow;
																break;
															case 'PrMo':
																priority = GrowlPriorityLow;
																break;
															case 'PrHi':
																priority = GrowlPriorityHigh;
																break;
															case 'PrEm':
																priority = GrowlPriorityEmergency;
																break;
															case 'PrNo':
															default:
																priority = GrowlPriorityNormal;
																break;
														}
													}
                                       
                                       BOOL changed = NO;
                                       if((title && ![title isEqualToString:@""]) ||
                                          (description && ![description isEqualToString:@""]) ||
                                          (iconData && [iconData length] != 0) ||
                                          (sticky && [GrowlUserScriptTaskUtilities isAppleEventDescriptorBoolean:sticky]) ||
														priority != GrowlPriorityUnset)
                                       {
                                          if(title && ![title isEqualToString:[copyDict valueForKey:GROWL_NOTIFICATION_TITLE]]){
                                             [mutableCopy setObject:title forKey:GROWL_NOTIFICATION_TITLE];
                                             changed = YES;
                                             if(logRuleResult){
                                                [ruleLogString appendFormat:@"\nModified title to: %@", title];
                                             }
                                          }
                                          if(description && ![description isEqualToString:[copyDict valueForKey:GROWL_NOTIFICATION_DESCRIPTION]]){
                                             [mutableCopy setObject:description forKey:GROWL_NOTIFICATION_DESCRIPTION];
                                             changed = YES;
                                             if(logRuleResult){
                                                [ruleLogString appendFormat:@"\nModified description to: %@", description];
                                             }
                                          }
                                          if(iconData && ![iconData isEqualToData:[copyDict valueForKey:GROWL_NOTIFICATION_ICON_DATA]]){
                                             NSImage *imageFromData = [[[NSImage alloc] initWithData:iconData] autorelease];
                                             if(imageFromData != nil){
                                                [mutableCopy setObject:iconData forKey:GROWL_NOTIFICATION_ICON_DATA];
                                                changed = YES;
                                                if(logRuleResult){
                                                   [ruleLogString appendFormat:@"\nModified icon"];
                                                }
                                             }else{
                                                NSLog(@"Unable to validate image data!");
                                             }
                                          }
                                          if(sticky && [sticky booleanValue] != [[copyDict valueForKey:GROWL_NOTIFICATION_STICKY] boolValue]){
                                             [mutableCopy setObject:[NSNumber numberWithBool:[sticky booleanValue]] forKey:GROWL_NOTIFICATION_STICKY];
                                             changed = YES;
                                             if(logRuleResult){
                                                [ruleLogString appendFormat:@"\nModified sticky to: %@", sticky ? @"YES" : @"NO"];
                                             }
                                          }
														if(priority != GrowlPriorityUnset && priority != [[copyDict valueForKey:GROWL_NOTIFICATION_PRIORITY] integerValue]){
															changed = YES;
															[mutableCopy setObject:[NSNumber numberWithInteger:priority] forKey:GROWL_NOTIFICATION_STICKY];
															if(logRuleResult){
                                                [ruleLogString appendFormat:@"\nModified priority to: %ld", priority];
                                             }
														}
                                          
                                          if(changed){
                                             [copyDict release];
                                             copyDict = [mutableCopy copy];
                                          }
                                       }
                                       
                                       [mutableCopy release];
                                    }
                                    
                                    GrowlPositionOrigin origin = GrowlNoOrigin;
                                    if([result descriptorForKeyword:'Orig']){
                                       NSAppleEventDescriptor *originDesc = [result descriptorForKeyword:'Orig'];
                                       NSString *locationString = nil;
                                       if([originDesc descriptorType] == typeEnumerated){
                                          switch ([originDesc enumCodeValue]) {
                                             case 'PoNO':
                                                origin = GrowlNoOrigin;
                                                locationString = @"no origin (use default)";
                                                break;
                                             case 'PoTL':
                                                origin = GrowlTopLeftCorner;
                                                locationString = @"top left";
                                                break;
                                             case 'PoBR':
                                                origin = GrowlBottomRightCorner;
                                                locationString = @"bottom right";
                                                break;
                                             case 'PoTR':
                                             default:
                                                origin = GrowlTopRightCorner;
                                                locationString = @"top right";
                                                break;
                                             case 'PoBL':
                                                origin = GrowlBottomLeftCorner;
                                                locationString = @"bottom left";
                                                break;
                                          }
                                          if(logRuleResult){
                                             [ruleLogString appendFormat:@"\nModified start position to: %@", locationString];
                                          }
                                       }
                                    }
                                    
                                    BOOL displayed = NO;
                                    if([result descriptorForKeyword:'GrDs']){
                                       NSAppleEventDescriptor *displayDesc = [result descriptorForKeyword:'GrDs'];
                                       if([displayDesc descriptorType] == typeEnumerated){
                                          switch ([displayDesc enumCodeValue]) {
                                             case 'DLNo': //None
                                                if(logRuleResult){
                                                   [ruleLogString appendFormat:@"\nDo not display visually"];
                                                }
                                                displayed = YES;
                                                [self sendNotificationDict:copyDict feedbackOfType:@"GROWL3_NOTIFICATION_NOT_DISPLAYED"];
                                                break;
                                             case 'DLDf': //Default explicit or not for note, handled below
                                             default:
                                                break;
                                             case 'DLGD': //Global default
                                                if(logRuleResult){
                                                   [ruleLogString appendFormat:@"\nDisplay using global default"];
                                                }
                                                [blockSelf displayNotification:copyDict
                                                             usingPluginConfig:[[GrowlTicketDatabase sharedInstance] defaultDisplayConfig]
                                                                    atPosition:origin];
                                                displayed = YES;
                                                break;
                                          }
                                       }else if([displayDesc descriptorType] == typeUnicodeText){
                                          NSString *displayName =[[result descriptorForKeyword:'GrDs'] stringValue];
                                          //NSLog(@"Display using: %@", displayName);
                                          if([displayName caseInsensitiveCompare:@"notification-center"] == NSOrderedSame){
                                             //Explicit NC call
                                             if(logRuleResult){
                                                [ruleLogString appendFormat:@"\nDisplay using notification-center"];
                                             }
                                             [blockSelf _fireAppleNotificationCenter:dict];
                                             displayed = YES;
                                          }else{
                                             //Find this display if we can, otherwise fall back
                                             GrowlTicketDatabasePlugin *pluginConfig = [[GrowlTicketDatabase sharedInstance] actionForName:displayName];
                                             if([pluginConfig isKindOfClass:[GrowlTicketDatabaseDisplay class]]){
                                                if(logRuleResult){
                                                   [ruleLogString appendFormat:@"\nDisplay using config: %@", displayName];
                                                }
                                                [blockSelf displayNotification:copyDict
                                                             usingPluginConfig:(GrowlTicketDatabaseDisplay*)pluginConfig
                                                                    atPosition:origin];
                                                displayed = YES;
                                             }else{
                                                if(logRuleResult){
                                                   [ruleLogString appendFormat:@"\nDisplay config: %@ not a display config, will use default", displayName];
                                                }
                                             }
                                          }
                                       }
                                    }
                                    if(!displayed && ![[GrowlPreferencesController sharedController] squelchMode]){
                                       if(logRuleResult){
                                          [ruleLogString appendFormat:@"\nDisplay using default for note type"];
                                       }
                                       [blockSelf displayNotificationUsingDefaultDisplay:copyDict atPosition:origin];
                                    }
                                    
                                    BOOL actedUpon = NO;
                                    if([result descriptorForKeyword:'GrAc']){
                                       NSAppleEventDescriptor *actionsDesc = [result descriptorForKeyword:'GrAc'];
                                       //NSLog(@"%@", actionsDesc);
                                       if([actionsDesc descriptorType] == typeEnumerated){
                                          switch ([actionsDesc enumCodeValue]) {
                                             case 'DLNo': //None
                                                if(logRuleResult){
                                                   [ruleLogString appendFormat:@"\nDo not do any actions"];
                                                }
                                                actedUpon = YES;
                                                break;
                                             case 'DLDf': //Default explicit or not for note, handled below
                                             default:
                                                break;
                                             case 'DLGD': //Global Default
                                                if(logRuleResult){
                                                   [ruleLogString appendFormat:@"\nDo Global Default action set"];
                                                }
                                                [self dispatchNotification:copyDict
                                                                 toActions:[[GrowlTicketDatabase sharedInstance] defaultActionConfigSet]];
                                                actedUpon = YES;
                                                break;
                                          }
                                       }else if([actionsDesc descriptorType] == typeAEList){
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
                                             if([pluginConfig isKindOfClass:[GrowlTicketDatabaseCompoundAction class]]){
                                                [actions unionSet:[(GrowlTicketDatabaseCompoundAction*)pluginConfig resolvedActionConfigSet]];
                                             }else if(pluginConfig && [pluginConfig canFindInstance]){
                                                [actions addObject:pluginConfig];
                                             }
                                          }];
                                          if(logRuleResult){
                                             [ruleLogString appendFormat:@"\nRequested Actions: "];
                                             [actionNames enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                                                [ruleLogString appendFormat:@"%@, ", obj];
                                             }];
                                             [ruleLogString appendFormat:@"\nResolved Actions: "];
                                             [actions enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                                                [ruleLogString appendFormat:@"%@, ", [obj displayName]];
                                             }];
                                          }
                                          
                                          [blockSelf dispatchNotification:copyDict toActions:actions];
                                       }else if([actionsDesc descriptorType] == typeUnicodeText){
                                          NSString *actionName = [actionsDesc stringValue];
                                          //NSLog(@"use action: %@", [actionsDesc stringValue]);
                                          GrowlTicketDatabasePlugin *pluginConfig = [[GrowlTicketDatabase sharedInstance] actionForName:actionName];
                                          if([pluginConfig isKindOfClass:[GrowlTicketDatabaseCompoundAction class]]){
                                             NSSet *compoundActions = [(GrowlTicketDatabaseCompoundAction*)pluginConfig resolvedActionConfigSet];
                                             if(logRuleResult){
                                                [ruleLogString appendFormat:@"\nRequested Action: %@", actionName];
                                                [ruleLogString appendFormat:@"\nResolved Actions: "];
                                                [compoundActions enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                                                   [ruleLogString appendFormat:@"%@, ", [obj displayName]];
                                                }];
                                             }
                                             [blockSelf dispatchNotification:copyDict toActions:compoundActions];
                                             actedUpon = YES;
                                          }else if(pluginConfig && [pluginConfig isKindOfClass:[GrowlTicketDatabaseAction class]]){
                                             if(logRuleResult){
                                                [ruleLogString appendFormat:@"\nDo action config: %@", actionName];
                                             }
                                             
                                             [blockSelf dispatchNotification:copyDict toActions:[NSSet setWithObject:pluginConfig]];
                                             actedUpon = YES;
                                          }else{
                                             if(logRuleResult){
                                                [ruleLogString appendFormat:@"\nAction config: %@ not an action config, will use default", actionName];
                                             }
                                          }
                                       }
                                    }
                                    if(!actedUpon && ![[GrowlPreferencesController sharedController] squelchMode]){
                                       if(logRuleResult){
                                          [ruleLogString appendFormat:@"\nDo default actions for note type"];
                                       }
                                       [blockSelf dispatchNotificationToDefaultConfigSet:copyDict];
                                    }
                                    
                                    BOOL useDefaultForward = YES;
                                    if([result descriptorForKeyword:'GrNF']){
                                       NSAppleEventDescriptor *forward = [result descriptorForKeyword:'GrNF'];
                                       if([GrowlUserScriptTaskUtilities isAppleEventDescriptorBoolean:forward]){
                                          if([forward booleanValue]){
                                             if(logRuleResult){
                                                [ruleLogString appendFormat:@"\nForwarding to UI selected entries"];
                                             }
                                             //This bypasses the checks on forwarding enabled
                                             [[GNTPForwarder sharedController] forwardDictionary:[[copyDict copy] autorelease]
                                                                                  isRegistration:NO
                                                                                      toEntryIDs:nil];
                                          }else{
                                             if(logRuleResult){
                                                [ruleLogString appendFormat:@"\nNot forwarding"];
                                             }
                                          }
                                          useDefaultForward = NO;
                                       }else if([forward descriptorType] == typeAEList) {
                                          //Handle the list
                                          NSMutableArray *entryIDs = [NSMutableArray arrayWithCapacity:[forward numberOfItems]];
                                          //1 indexed array in AppleEvents
                                          for(int idx = 1; idx <= [forward numberOfItems]; idx++) {
                                             [entryIDs addObject:[[forward descriptorAtIndex:idx] stringValue]];
                                          }
                                          if(logRuleResult){
                                             [ruleLogString appendFormat:@"\nForwarding to entry ids: "];
                                             [entryIDs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                                [ruleLogString appendFormat:@"%@, ", obj];
                                             }];
                                          }
                                          [[GNTPForwarder sharedController] forwardDictionary:[[copyDict copy] autorelease]
                                                                               isRegistration:NO
                                                                                   toEntryIDs:entryIDs];
                                          useDefaultForward = NO;
                                       }
                                    }
                                    if(useDefaultForward) {
                                       BOOL globalForwardingEnabled = [[GrowlPreferencesController sharedController] isForwardingEnabled];
                                       if(logRuleResult){
                                          [ruleLogString appendFormat:@"\nForwarding according to default: %@", globalForwardingEnabled ? @"enabled" : @"disabled"];
                                       }
                                       if(globalForwardingEnabled)
                                          [blockSelf forwardGrowlDictViaNetwork:[[copyDict copy] autorelease]];
                                    }
                                    
                                    BOOL useDefaultSubscription = YES;
                                    if([result descriptorForKeyword:'GrNS']){
                                       NSAppleEventDescriptor *subscribe = [result descriptorForKeyword:'GrNS'];
                                       if([GrowlUserScriptTaskUtilities isAppleEventDescriptorBoolean:subscribe]){
                                          if([subscribe booleanValue]){
                                             //This bypasses the checks on is subscription allowed, however we still will only send
                                             //to active subscribers, so kind of a chicken and the egg thing
                                             if(logRuleResult){
                                                [ruleLogString appendFormat:@"\nForwarding to all subscribers"];
                                             }
                                             [[GNTPSubscriptionController sharedController] forwardDictionary:[[copyDict copy] autorelease]
                                                                                               isRegistration:NO
																															 toSubscriberIDs:nil];
                                          }else{
                                             if(logRuleResult){
                                                [ruleLogString appendFormat:@"\nNot forwarding to subscribers"];
                                             }
                                          }
                                          useDefaultSubscription = NO;
                                       }else if([subscribe descriptorType] == typeAEList) {
                                          //Handle the list
                                          NSMutableArray *entryIDs = [NSMutableArray arrayWithCapacity:[subscribe numberOfItems]];
                                          //1 indexed array in AppleEvents
                                          for(int idx = 1; idx <= [subscribe numberOfItems]; idx++) {
                                             [entryIDs addObject:[[subscribe descriptorAtIndex:idx] stringValue]];
                                          }
                                          if(logRuleResult){
                                             [ruleLogString appendFormat:@"\nForwarding to subscriber entry ids: "];
                                             [entryIDs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                                [ruleLogString appendFormat:@"%@, ", obj];
                                             }];
                                          }
                                          [[GNTPSubscriptionController sharedController] forwardDictionary:[[copyDict copy] autorelease]
                                                                                            isRegistration:NO
																														 toSubscriberIDs:entryIDs];
                                          useDefaultSubscription = NO;
                                       }
                                    }
                                    if(useDefaultSubscription){
                                       if(logRuleResult){
                                          [ruleLogString appendFormat:@"\nForwarding according to subscription defaults"];
                                       }
                                       [blockSelf sendGrowlDictToSubscribers:[[copyDict copy] autorelease]];
                                    }
                                    
                                    if([result descriptorForKeyword:'GrHL']){
                                       if([[result descriptorForKeyword:'GrHL'] booleanValue]){
                                          if(logRuleResult){
                                             [ruleLogString appendFormat:@"\nSending to the history log system"];
                                          }
                                          [blockSelf logNotification:copyDict];
                                       }else{
                                          [ruleLogString appendFormat:@"\nNot sending to the history log system"];
                                       }
                                    }else{
                                       if(logRuleResult){
                                          [ruleLogString appendFormat:@"\nSending to the history log system by default"];
                                       }
                                       [blockSelf logNotification:copyDict];
                                    }
                                    
                                    if(logRuleResult){
                                       //Make this better, don't send it raw to the console.
                                       //[ruleLogString appendFormat:@"Total time from receipt of note: %.3f\n", -[startDate timeIntervalSinceNow]];
                                       NSLog(ruleLogString);
                                    }
                                 
                                 }else{
												if(logRuleResult){
													if(result && [result descriptorType] == typeNull)
														NSLog(@"Returned nothing, sending to the default system");
													else
														NSLog(@"Unrecognized rule return type, sending to the default system");
                                    }
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

- (BOOL)showRulesWarning {
	BOOL allow = [[GrowlPreferencesController sharedController] allowsRules];
	if(![[GrowlPreferencesController sharedController] hasShownWarningForRules]){
		NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Rules.scpt Detected", nil)
													defaultButton:NSLocalizedString(@"Yes", nil)
												 alternateButton:NSLocalizedString(@"No", nil)
													  otherButton:nil
									informativeTextWithFormat:NSLocalizedString(@"Growl has detected a Rules.scpt in your user's ~/Library/Application Scripts/com.Growl.GrowlHelperApp folder.\nIf you click yes, Growl will start using it to evaluate notifications and determine what to do with them.\nIf you don't know what a rules script is, or you don't wish to use it, click no.\nYou may change this preference at any time in Growl's Preferences window on the general tab.\n", nil)];
		
		NSInteger result = [alert runModal];
		[[GrowlPreferencesController sharedController] setHasShownWarningForRules:YES];
		if(result == NSOKButton){
			allow = YES;
		}else{
			[[GrowlPreferencesController sharedController] setAllowsRules:NO];
			allow = NO;
		}
	}
	return allow;
}

- (GrowlNotificationResult) dispatchNotificationWithDictionary:(NSDictionary *)note {
   NSDictionary *dict = [self filledInNotificationDictForDict:note];
   if(!dict)
      return GrowlNotificationResultNotRegistered;
   
   if([GrowlUserScriptTaskUtilities hasScriptTaskClass] &&
		[GrowlUserScriptTaskUtilities hasRulesScript] &&
		[self showRulesWarning])
	{
      return [self dispatchByRuleSwithFilledInDict:dict];
   }else{
		return [self dispatchByClassicWithFilledInDict:dict];
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
   NSMutableDictionary *aDict = [[dict mutableCopy] autorelease];
   
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
         value = [NSNumber numberWithInt:GrowlPriorityNormal];
   } else
      value = [NSNumber numberWithInt:priority];
   [aDict setObject:value forKey:GROWL_NOTIFICATION_PRIORITY];
      
   // Retrieve and set the sticky bit of the notification
   int sticky = [[notification sticky] intValue];
   if (sticky >= 0)
      [aDict setObject:[NSNumber numberWithBool:sticky] forKey:GROWL_NOTIFICATION_STICKY];
      
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

-(void)displayNotificationUsingDefaultDisplayInDefaultPosition:(NSDictionary*)dict {
   [self displayNotificationUsingDefaultDisplay:dict atPosition:GrowlNoOrigin];
}

-(void)displayNotificationUsingDefaultDisplay:(NSDictionary*)dict atPosition:(GrowlPositionOrigin)position {
   if ([[GrowlPreferencesController sharedController] shouldUseAppleNotifications]) {
      // We ignore display preferences, and use Notification Center instead.
      [self _fireAppleNotificationCenter:dict];
   }
   else {
      //GrowlTicketDatabaseApplication *ticket = [self appTicketForDict:dict];
      GrowlTicketDatabaseNotification *notification = [self notificationTicketForDict:dict];
      if (!notification) {
         return;
      }
      [self displayNotification:dict usingPluginConfig:[notification resolvedDisplayConfig] atPosition:position];
   }
}

-(void)displayNotification:(NSDictionary*)dict
         usingPluginConfig:(GrowlTicketDatabaseDisplay*)pluginConfig
                atPosition:(GrowlPositionOrigin)origin
{
   GrowlTicketDatabaseApplication *ticket = [self appTicketForDict:dict];
   GrowlDisplayPlugin *display = (GrowlDisplayPlugin*)[pluginConfig pluginInstanceForConfiguration];
   NSMutableDictionary *configCopy = [[[pluginConfig configuration] mutableCopy] autorelease];
   if(!configCopy)
      configCopy = [NSMutableDictionary dictionary];
   if(origin == GrowlNoOrigin)
      origin = (GrowlPositionOrigin)[ticket resolvedDisplayOrigin];
   [configCopy setValue:[NSNumber numberWithInt:origin] forKey:@"com.growl.positioncontroller.selectedposition"];
   [configCopy setValue:[pluginConfig configID] forKey:GROWL_PLUGIN_CONFIG_ID];
   
   if(display && [display conformsToProtocol:@protocol(GrowlDispatchNotificationProtocol)]){
      [display dispatchNotification:dict withConfiguration:configCopy];
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
   }else if([[components objectAtIndex:0] caseInsensitiveCompare:@"plugin"] == NSOrderedSame) {
		if([components count] > 1){
			if([[components objectAtIndex:1] caseInsensitiveCompare:@"preview"] == NSOrderedSame) {
				if([components count] > 2){
					NSString *pluginPreviewString = [components objectAtIndex:2];
					GrowlTicketDatabasePlugin *plugin = [[GrowlTicketDatabase sharedInstance] actionForName:pluginPreviewString];
					
					if(!plugin){
						plugin = [[GrowlTicketDatabase sharedInstance] pluginConfigForID:pluginPreviewString];
					}
					if(!plugin){
						plugin = [[GrowlTicketDatabase sharedInstance] pluginConfigForBundleID:pluginPreviewString];
					}
					
					if(plugin){
						[[NSNotificationCenter defaultCenter] postNotificationName:GrowlPreview
																							 object:plugin
																						  userInfo:nil];
					}else{
						NSLog(@"%@ not found to preview", pluginPreviewString);
					}
				}
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
			 selector:@selector(notificationClosed:)
				  name:@"GROWL_NOTIFICATION_CLOSED"
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

-(void)applicationWillTerminate:(NSNotification *)notification {
	[GrowlXPCCommunicationAttempt shutdownXPC];
}

#pragma mark Growl Application Bridge delegate

/*click feedback comes here first. GAB picks up the DN and calls our
 *	-growlNotificationWasClicked:/-growlNotificationTimedOut: with it if it's a
 *	GHA notification.
 */
- (void)growlNotificationDict:(NSDictionary *)growlNotificationDict
 didCloseViaNotificationClick:(BOOL)viaClick
               onLocalMachine:(BOOL)wasLocal
{
	static BOOL isClosingFromRemoteClick = NO;
	/* Don't post a second close notification on the local machine if we close a notification from this method in
	 * response to a click on a remote machine.
	 */
	if (isClosingFromRemoteClick)
		return;
	
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
   }else{
      NSString *noteName = viaClick ? @"GROWL3_NOTIFICATION_CLICK" : @"GROWL3_NOTIFICATION_TIMEOUT";
      [self sendNotificationDict:growlNotificationDict feedbackOfType:noteName];
   }
	
	if (!wasLocal) {
		isClosingFromRemoteClick = YES;
		[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_CLOSE_NOTIFICATION
															object:[growlNotificationDict objectForKey:GROWL_NOTIFICATION_INTERNAL_ID]];
		isClosingFromRemoteClick = NO;
	}
}

-(BOOL)sendNotificationDict:(NSDictionary*)growlNotificationDict
                     feedbackOfType:(NSString*)feedbacktype
{
   NSString *gntpOrigin = [growlNotificationDict objectForKey:GROWL_GNTP_ORIGIN_SOFTWARE_NAME];
   if([gntpOrigin caseInsensitiveCompare:@"Growl.framework"] == NSOrderedSame &&
      [[growlNotificationDict objectForKey:GROWL_NOTIFICATION_GNTP_SENT_BY] isLocalHost]){
      NSString *frameworkVersion = [growlNotificationDict objectForKey:GROWL_GNTP_ORIGIN_SOFTWARE_VERSION];
      if(compareVersionStrings(@"3.0", frameworkVersion) != kCFCompareGreaterThan){
         NSString *noteUUID = [growlNotificationDict objectForKey:GROWL_NOTIFICATION_INTERNAL_ID];
         [[NSDistributedNotificationCenter defaultCenter] postNotificationName:feedbacktype
                                                                        object:noteUUID];
         return YES;
      }
   }
   return NO;
}

@end

#pragma mark -

@implementation GrowlApplicationController (PRIVATE)

#pragma mark Click feedback from displays

- (void) notificationClosed:(NSNotification*)notification {
   GrowlNotification *growlNotification = [notification object];
   [self sendNotificationDict:[growlNotification dictionaryRepresentation] feedbackOfType:@"GROWL3_NOTIFICATION_CLOSED"];
}

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
