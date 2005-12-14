/*
 
 BSD License
 
 Copyright (c) 2005, Jesper <wootest@gmail.com>
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 * Neither the name of Gmail+Growl or Jesper, nor the names of Gmail+Growl's contributors 
 may be used to endorse or promote products derived from this software without
 specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
 BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 The name Gmail is owned by Google, Inc. Growl is owned by the Growl Development Team.
 Likewise, the logos of those services are owned and copyrighted to their owners.
 No ownership of any of these is assumed or implied, and no infringement is intended.
 
 Gmail+Growl is expressively permitted to be distributed with Growl itself.
 
 For more info on this products or on the technologies on which it builds: 
				Growl: <http://growl.info/>
                Gmail: <http://gmail.com>
       Gmail Notifier: <http://toolbar.google.com/gmail-helper/index.html>
 
		  Gmail+Growl: <http://wootest.net/gmailgrowl/>
 
 */

//
//  GMNGrowlController.m
//  GMNGrowl
//
//  Created by Jesper on 2005-09-02.
//  Copyright 2005 Jesper. All rights reserved.
//  Contact: <wootest@gmail.com>.
//

#import <Growl/Growl.h>

#import "GGPluginProtocol.h"
#import "GMNGrowlController.h"

/** The following enables a feature where Gmail+Growl will not show a notification
*** for a message that has been shown before. It was decided to leave this feature
*** out, since even if Gmail+Growl's part works, this obviously doesn't cancel
*** Gmail Notifier's own number+icon thing in the menu bar, or the sound it plays
*** on received mails, if any. As such this would be inconsistent and confusing.
*** It's there for the enabling, though, if you think you can stand it. :)
***
*** Added in 1.1. */
#define CompileJustNotifyOnceSupport	0

/** The following is Gmail+Growl's new support for self-defined notification
*** formats. Any 'message dict key' placeholder will be substituted for its
*** respective value when the notifications are shown. Dates will also be
*** converted into the short system default format.
***
*** The brave and/or foolhardy may choose to change the placeholder's format
*** in this one place, as the rest of the defines just uses that define to
*** implement their static selves.
***
*** Added in 1.1. */
#define GmailMessageDictPlaceholder		@"<#%@#>"
//                                        <#whatever#>

#define MAKEPLACEHOLDER(A)				[NSString stringWithFormat:GmailMessageDictPlaceholder, A]

#define GmailMessageDictAuthorEmailKey	@"authorEmail"
#define GmailMessageDictAuthorNameKey	@"authorName"
#define GmailMessageDictMailUUIDKey		@"identifier"
#define GmailMessageDictDateIssuedKey	@"issued"
#define GmailMessageDictDateModifierKey	@"modified"
#define GmailMessageDictSummaryKey		@"summary"
#define GmailMessageDictTitleKey		@"title"

/** The above GmailMessageDict defines are keys in the message dictionary format
*** used in the -newMessagesReceived:fullCount: method. Each item in the messages
*** array is a dictionary that has items with those keys. 
***
*** Here's what an NSLogged dictionary could look like: 
*** (everything is an NSString unless otherwise noted) */
//         authorEmail = "foo@bar.baz"; 
//			authorName = Jesper; 
//			identifier = "tag:gmail.google.com,2004:XXXXXXXXXXXXXX";
//				issued = 2005-09-02 18:54:45 +0000; // NSDate
//			  modified = 2005-09-02 18:54:45 +0000; // NSDate
//			   summary = "bar /Jesper"; 
//				 title = foo;

/** Any English "user-readable" text below is not localized because Gmail Notifier
*** is not yet localized itself. We're not western-centric dolts. There's a method
*** to our madness. And so on. */

#define GMNGrowlMissingSummary			@"(No summary)"
#define GMNGrowlMissingTitle			@"(No title)"
#define GMNGrowlMissingAuthorName		@"(No author)"

#define GMNGrowlNewMailNotification		@"New Gmail"

#define GMNGrowlNotificationFormatUDK	@"GMNGrowlNotificationFormat"
#define GMNGrowlNotificationFormat		[NSString stringWithFormat:@"New mail! \"%@\" from %@",	MAKEPLACEHOLDER(GmailMessageDictTitleKey), MAKEPLACEHOLDER(GmailMessageDictAuthorNameKey)]
#define GMNGrowlNotificationTextFormatUDK	@"GMNGrowlNotificationTextFormat"
#define GMNGrowlNotificationTextFormat	[NSString stringWithFormat:@"%@", MAKEPLACEHOLDER(GmailMessageDictSummaryKey)]

#define GMNGrowlDontUseABIconsUDK		@"GMNGrowlDontUseABIcons"
#define GMNGrowlDontUseABIcons			NO

#define GMNGrowlMaxNotificationsCapUDK	@"GMNGrowlMaxNotificationsCap"
#define GMNGrowlMaxNotificationsCap		6

#if CompileJustNotifyOnceSupport
#define GMNGrowlJustNotifyOnceUDK		@"GMNGrowlJustNotifyOnce"
#define GMNGrowlJustNotifyOnceListUDK	@"GMNGrowlJustNotifyOnceList"
#endif

/** *yoink* As of Growlification, the Growl framework is assumed installed, which means not using the -WithInstall version, which means we can get rid of this:
#define GrowlUpdateTitle				@"Growl can be updated to a newer version"
#define GrowlUpdateInfo					@"Growl can automatically be updated to a newer version than the one currently installed. No download is necessary."
#define GrowlInstallTitle				@"Growl wasn't found, but can be installed"
#define GrowlInstallInfo				@"Gmail+Growl depends on the tool Growl to display notifications when new mails are received. Growl isn't currently installed but can automatically be installed for you. No download is necessary." */

@interface GMNPlaceholderTool : NSObject
+ (NSString *)replaceString:(NSString *)replace withString:(NSString *)with inString:(NSString *)subject;
+ (NSString *)replacePlaceholdersInString:(NSString *)str withPlaceholderDict:(NSDictionary *)dict;
@end

#pragma mark Placeholder replacement (for format strings)
@implementation GMNPlaceholderTool
+ (NSString *)replacePlaceholdersInString:(NSString *)str withPlaceholderDict:(NSDictionary *)dict {

	NSString *placeHolderFormat = GmailMessageDictPlaceholder;
	
	NSEnumerator *phEnumerator = [dict keyEnumerator];
	NSString *ph;
	id object;
	while (ph = [phEnumerator nextObject]) {
		object = [dict objectForKey:ph];
		if ([object isKindOfClass:[NSDate class]]) {
			object = [[(NSDate *)object dateWithCalendarFormat:[[NSUserDefaults standardUserDefaults] objectForKey:@"NSShortTimeDateFormatString"] timeZone:nil] descriptionWithLocale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
			/** Construct an NSCalendarDate, because they automatically show nicer dates. */
		}
		str = [GMNPlaceholderTool replaceString:[NSString stringWithFormat:placeHolderFormat, ph]
					   withString:[object description]
					     inString:str];
	} 
	
	return str;
	
}

+ (NSString *)replaceString:(NSString *)replace withString:(NSString *)with inString:(NSString *)subject {
//	GMNLog(@"in %@, replace %@ with %@", subject, replace, with);
	return [[subject componentsSeparatedByString:replace] componentsJoinedByString:with];
}
@end

@implementation GMNGrowlController

#pragma mark -
#pragma mark Initialization, plugin registration, Growl registration

- (id)init {
	self = [super init];
	NSBundle *myBundle = [NSBundle bundleForClass:[GMNGrowlController class]];
	NSString *growlPath = [[myBundle privateFrameworksPath]
        stringByAppendingPathComponent:@"Growl.framework"];
	NSBundle *growlBundle = [NSBundle bundleWithPath:growlPath];
	if (growlBundle && [growlBundle load]) {
        // Register ourselves as a Growl delegate
        [GrowlApplicationBridge setGrowlDelegate:self];
	} else {
		/**TODO** Better error handling. */
        GMNLog(@"-ERR: Could not load Growl framework.");
	}
	return self;
}

+ (void)pluginLoaded {
#if CompileJustNotifyOnceSupport
	[[NSUserDefaults standardUserDefaults] setObject:[NSArray array] forKey:GMNGrowlJustNotifyOnceListUDK];
#endif
	GMNLog(@"Plugin loaded.");
}

+ (void)pluginWillUnload {
	GMNLog(@"Plugin about to unload.");
}


- (NSString *) applicationNameForGrowl {
	return @"Gmail+Growl (Gmail Notifier Plugin)";
}

- (void)growlIsReady {
	GMNLog(@"Growl is ready for Gmail!");
}

- (NSDictionary *) registrationDictionaryForGrowl {
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSArray arrayWithObject:GMNGrowlNewMailNotification], GROWL_NOTIFICATIONS_ALL,
		[NSArray arrayWithObject:GMNGrowlNewMailNotification], GROWL_NOTIFICATIONS_DEFAULT, 
		nil];
}

/** *yoink* As of Growlification, the Growl framework is assumed installed, which means not using the -WithInstall version, which means we can get rid of this:
#pragma mark -
#pragma mark Installation or Update box for Growl

- (NSAttributedString *)growlInstallationInformation {
	return [[NSAttributedString alloc] initWithString:GrowlInstallInfo attributes:[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]] forKey:NSFontAttributeName]];
}

- (NSString *)growlInstallationWindowTitle {
	return GrowlInstallTitle;
}
- (NSAttributedString *)growlUpdateInformation {
	return [[NSAttributedString alloc] initWithString:GrowlUpdateInfo attributes:[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]] forKey:NSFontAttributeName]];	
}
- (NSString *)growlUpdateWindowTitle {
	return GrowlUpdateTitle;
} */

#pragma mark -
#pragma mark New messages handler

- (void)newMessagesReceived:(NSArray *)messages
                  fullCount:(int)fullCount {
	NSEnumerator *messageEnumerator = [messages objectEnumerator];
	NSDictionary *messageDict;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults synchronize]; /** Always, ALWAYS get the latest settings. */

#if CompileJustNotifyOnceSupport
	
	BOOL checkForMessagesToIgnore = NO;
	BOOL ignoreMessages = NO;
	NSMutableArray *messagesToIgnore = nil;
	if ([defaults boolForKey:GMNGrowlJustNotifyOnceUDK]) {
		checkForMessagesToIgnore = YES;
		ignoreMessages = YES;
		if (nil == (messagesToIgnore = (NSMutableArray *)[[defaults arrayForKey:GMNGrowlJustNotifyOnceListUDK] mutableCopy])) {
			checkForMessagesToIgnore = NO;
			messagesToIgnore = (NSMutableArray *)[[NSArray array] mutableCopy];
		}
	}
	
#endif
	
	BOOL useABicon = !([[NSUserDefaults standardUserDefaults] boolForKey:GMNGrowlDontUseABIconsUDK]);
	
	GMNLog(@"Use Address Book icon? %@", (useABicon ? @"YES" : @"NO"));
	
	NSString *notificationTitle = [[NSUserDefaults standardUserDefaults] stringForKey:GMNGrowlNotificationFormatUDK];
	if (!notificationTitle || [notificationTitle isEqualToString:@""])
		notificationTitle = GMNGrowlNotificationFormat;
		
	NSString *notificationText = [[NSUserDefaults standardUserDefaults] stringForKey:GMNGrowlNotificationTextFormatUDK];
	if (!notificationText || [notificationText isEqualToString:@""])
		notificationText = GMNGrowlNotificationTextFormat;
	
	id maxN = [[NSUserDefaults standardUserDefaults] objectForKey:GMNGrowlMaxNotificationsCapUDK];
	int notificationsCap = GMNGrowlMaxNotificationsCap;
	if (maxN)
		notificationsCap = [(NSNumber *)maxN intValue];
	if (notificationsCap > 20 || notificationsCap < 1)
		notificationsCap = GMNGrowlMaxNotificationsCap;
	int i = 1;
	NSData *iconData; 
	iconData = [[[NSWorkspace sharedWorkspace] iconForFile:[[NSWorkspace sharedWorkspace] fullPathForApplication:@"Gmail Notifier"]] TIFFRepresentation];
	defIcon = [[[[NSWorkspace sharedWorkspace] iconForFile:[[NSWorkspace sharedWorkspace] fullPathForApplication:@"Gmail Notifier"]] TIFFRepresentation] retain];
	while (messageDict = [messageEnumerator nextObject]) {
		messageDict = [self normalizeMessageDict:messageDict];
		if (i == notificationsCap)
			break;
#if CompileJustNotifyOnceSupport
		if (checkForMessagesToIgnore)
			if ([messagesToIgnore containsObject:[messageDict objectForKey:GmailMessageDictMailUUIDKey]])
				continue;
		if (ignoreMessages)
			[messagesToIgnore addObject:[messageDict objectForKey:GmailMessageDictMailUUIDKey]];
#endif
		
		if (useABicon)
			iconData = [self iconDataBasedOnSender:[messageDict objectForKey:GmailMessageDictAuthorEmailKey]];
		
		[GrowlApplicationBridge 
		notifyWithTitle:[GMNPlaceholderTool replacePlaceholdersInString:notificationTitle withPlaceholderDict:messageDict]
			description:[GMNPlaceholderTool replacePlaceholdersInString:notificationText withPlaceholderDict:messageDict]
	   notificationName:GMNGrowlNewMailNotification
			   iconData:iconData
			   priority:0
			   isSticky:NO
		   clickContext:nil];	
		i++;
	} 
[defIcon release];
#if CompileJustNotifyOnceSupport
	[defaults setObject:messagesToIgnore forKey:GMNGrowlJustNotifyOnceListUDK];
#endif
	[defaults synchronize];
	GMNLog(@"new messages received: %@", messages);
}

- (NSDictionary *)normalizeMessageDict:(NSDictionary *)di {
	NSMutableDictionary *d = (NSMutableDictionary *)[di mutableCopy];
	
	NSString *authorName = [d objectForKey:GmailMessageDictAuthorNameKey];
	if (!authorName || [authorName isEqualToString:@""])
		[d setObject:GMNGrowlMissingAuthorName forKey:GmailMessageDictAuthorNameKey];
	
	NSString *subject = [d objectForKey:GmailMessageDictTitleKey];
	if (!subject || [subject isEqualToString:@""])
		[d setObject:GMNGrowlMissingTitle forKey:GmailMessageDictTitleKey];
	
	NSString *summary = [d objectForKey:GmailMessageDictSummaryKey];
	if (!summary || [summary isEqualToString:@""])
		[d setObject:GMNGrowlMissingSummary forKey:GmailMessageDictSummaryKey];
	
	return d;
}

- (NSData *)iconDataBasedOnSender:(NSString *)email {
	GMNLog(@"Looking for Address Book icon for %@.", email);
	ABAddressBook *AB = [ABAddressBook sharedAddressBook];
	ABSearchElement *wanted = [ABPerson searchElementForProperty:kABEmailProperty
									 label:nil
									   key:nil
									 value:email
								comparison:kABEqualCaseInsensitive];
	NSArray *people = [AB recordsMatchingSearchElement:wanted];
	if (!people || [people count]<1) {
		GMNLog(@"No icon found - no corresponding people.");
		return defIcon;
	}
//	GMNLog(@"found people: %@", people);
	NSEnumerator *peopleEnumerator = [people objectEnumerator];
	ABRecord *rec;
	while (rec = [peopleEnumerator nextObject]) {
//		GMNLog(@"guy: %@", [rec class]);
		if (![rec respondsToSelector:@selector(imageData)])
			continue;
		ABPerson *guy = (ABPerson *)rec;
//		ABMultiValue *mv = [guy valueForProperty:kABEmailProperty];
		NSData *d = [guy imageData]; 
		if (d != nil) {
			GMNLog(@"Found icon!");
			return d;
		}
	} 
	GMNLog(@"No icon found - no icon set for any corresponding people.");
	return defIcon;
}

@end
