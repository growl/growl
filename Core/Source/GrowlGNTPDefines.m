//
//  GrowlGNTPDefines.m
//  Growl
//
//  Created by Rudy Richter on 10/7/09.
//  Copyright 2009 The Growl Project. All rights reserved.
//

#pragma mark Encryption
NSString *GrowlGNTPNone = @"NONE";
NSString *GrowlGNTPMD5 = @"MD5";
NSString *GrowlGNTPSHA1 = @"SHA1";
NSString *GrowlGNTPSHA256 = @"SHA256";
NSString *GrowlGNTPSHA512 = @"SHA512";
NSString *GrowlGNTPAES = @"AES";
NSString *GrowlGNTPDES = @"DES";
NSString *GrowlGNTP3DES = @"3DES";

#pragma mark Callback Results
NSString *GrowlGNTPCallbackClicked = @"CLICKED";
NSString *GrowlGNTPCallbackClosed = @"CLOSED";
NSString *GrowlGNTPCallbackTimedout = @"TIMEDOUT";
NSString *GrowlGNTPCallbackClick = @"CLICK";
NSString *GrowlGNTPCallbackClose = @"CLOSE";
NSString *GrowlGNTPCallbackTimeout = @"TIMEOUT";

#pragma mark Requests
//Request Types
NSString *GrowlGNTPRegisterMessageType = @"REGISTER";
NSString *GrowlGNTPNotificationMessageType = @"NOTIFY";
NSString *GrowlGNTPSubscribeMessageType = @"SUBSCRIBE";

#pragma mark Responses
//Response Types
NSString *GrowlGNTPOKResponseType = @"-OK";
NSString *GrowlGNTPErrorResponseType = @"-ERROR";

#pragma mark Callbacks
//Callback Types
NSString *GrowlGNTPCallbackTypeHeader = @"-CALLBACK";


#pragma mark Registration Headers
//REGISTER

NSString *GrowlGNTPApplicationNameHeader = @"Application-Name";
NSString *GrowlGNTPApplicationIconHeader = @"Application-Icon";
NSString *GrowlGNTPNotificationCountHeader = @"Notifications-Count";
NSString *GrowlGNTPNotificationName = @"Notification-Name";
NSString *GrowlGNTPNotificationDisplayName = @"Notification-Display-Name";
NSString *GrowlGNTPNotificationEnabled = @"Notification-Enabled";
NSString *GrowlGNTPNotificationIcon = @"Notification-Icon";

#pragma mark Notify Headers
//Notify

NSString *GrowlGNTPNotificationID = @"Notification-ID";
NSString *GrowlGNTPNotificationTitle = @"Notification-Title";
NSString *GrowlGNTPNotificationText = @"Notification-Text";
NSString *GrowlGNTPNotificationSticky = @"Notification-Sticky";
NSString *GrowlGNTPNotificationPriority = @"Notification-Priority";
NSString *GrowlGNTPNotificationCallbackContext = @"Notification-Callback-Context";
NSString *GrowlGNTPNotificationCallbackContextType = @"Notification-Callback-Context-Type";
NSString *GrowlGNTPNotificationCallbackTarget = @"Notification-Callback-Target";

#pragma mark Subscribe Headers
//Subscribe

NSString *GrowlGNTPSubscriberID = @"Subscriber-ID";
NSString *GrowlGNTPSubscriberName = @"Subscriber-Name";
NSString *GrowlGNTPSubscriberPort = @"Subscriber-Port";

NSString *GrowlGNTPResponseSubscriptionTTL = @"Subscription-TTL";

#pragma mark Callback Headers
//-CALLBACK

NSString *GrowlGNTPNotificationCallbackResult = @"Notification-Callback-Result";
NSString *GrowlGNTPNotificationCallbackTimestamp = @"Notification-Callback-Timestamp";

#pragma mark Generic Headers
//Generic Headers

NSString *GrowlGNTPOriginMachineName = @"Origin-Machine-Name";
NSString *GrowlGNTPOriginSoftwareName = @"Origin-Software-Name";
NSString *GrowlGNTPOriginSoftwareVersion = @"Origin-Software-Version";
NSString *GrowlGNTPOriginPlatformName = @"Origin-Platform-Name";
NSString *GrowlGNTPOriginPlatformVersion = @"Origin-Platform-Version";

#pragma mark Extension Headers
//Extension Headers
NSString *GrowlGNTPExtensionPrefix = @"X-";
NSString *GrowlGNTPApplicationBundleIDHeader = @"X-Application-BundleID";
NSString *GrowlGNTPApplicationPIDHeader = @"X-Application-PID";

#pragma mark Data Headers
//Application Data Headers
NSString *GrowlGNTPApplicationDataPrefix = @"Data-";
