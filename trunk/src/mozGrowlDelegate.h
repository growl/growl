//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

#include "xpcom-config.h"
#import <Growl-WithInstaller/GrowlApplicationBridge.h>
#include "nsIObserver.h"

#import <Cocoa/Cocoa.h>

// XXX should this be localized?  probably :(
#define NOTIFICATION_NAME @"ApplicationNotice"
#define OBSERVER_KEY      @"ALERT_OBSERVER"
#define COOKIE_KEY        @"ALERT_COOKIE"

@interface mozGrowlDelegate : NSObject <GrowlApplicationBridgeDelegate>
{
@private
  PRUint32 mKey;
  NSMutableDictionary* mDict;
}

/**
 * Dispatches a notification to Growl
 *
 * @param aTitle  The title of the notification
 * @param aText   The body of the notification
 * @param aImage  The image data, or [NSData data] if no image
 * @param aKey    The observer key to use as a lookup (or 0 if no observer)
 * @param aCookie The string to be used as a cookie if there is an observer
 */
+ (void) title:(const nsAString&)aTitle
          text:(const nsAString&)aText
         image:(NSData*)aImage
           key:(PRUint32)aKey
        cookie:(const nsAString&)aCookie;

/**
 * Adds an nsIObserver that we can query later for dispatching obsevers.
 *
 * @param aObserver The observer we are adding.
 * @return The key it was stored in.
 */
- (PRUint32) addObserver:(nsIObserver*)aObserver;

/**
 * Gives Growl the complete list of notifications this application will ever
 * send, and also which notifications should be enabled by default.
 */
- (NSDictionary *) registrationDictionaryForGrowl;

/**
 * Informs us that a Growl notification timed out.
 *
 * @param clickContext The object passed back from growl.
 */
- (void) growlNotificationTimedOut:(id)clickContext;

/**
 * Informs us that a Growl notification was clicked.  It is only called when
 * Growl when the notification sent to Growl is sent with a non-nil
 * clickContext.
 *
 * @param clickContext The object passed back from growl.
 */
- (void) growlNotificationWasClicked:(id)clickContext;

@end
