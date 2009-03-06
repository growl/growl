/*
 Copyright (c) The Growl Project, 2004-2005
 All rights reserved.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 3. Neither the name of Growl nor the names of its contributors
 may be used to endorse or promote products derived from this software
 without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 OF THE POSSIBILITY OF SUCH DAMAGE.
*/
//
//  GrowlMail.m
//  GrowlMail
//
//  Created by Adam Iser on Mon Jul 26 2004.
//  Copyright (c) 2004-2005 The Growl Project. All rights reserved.
//

#import "GrowlMail.h"
#import "Message+GrowlMail.h"

#import "MailHeaders.h"
#import "MessageFrameworkHeaders.h"
#import <objc/objc-class.h>

typedef enum {
	MODE_AUTO = 0,
	MODE_SINGLE = 1,
	MODE_SUMMARY = 2
} GrowlMailModeType;

#define AUTO_THRESHOLD	10

#define	MAX_NOTIFICATION_THREADS	5

static int	activeNotificationThreads = 0;

//#define GROWL_MAIL_DEBUG

NSBundle *GMGetGrowlMailBundle(void) {
	return [NSBundle bundleForClass:[GrowlMail class]];
}

@implementation GrowlMail

static int messageCopies = 0;

#pragma mark Panic buttons

//The purpose of this method is to shut down GrowlMail completely: we should not be notified of any messages, nor notify the user of any messages, after this message is called.
- (void) shutDownGrowlMail {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[GrowlApplicationBridge setGrowlDelegate:nil];
}

//This is a suicide pill. GrowlMail sends itself this message any time it detects a change in Mail's implementation, such as a missing method or an object of the wrong class.
- (void) shutDownGrowlMailAndWarn:(NSString *)specificWarning {
	NSLog(NSLocalizedString(@"WARNING: Mail is not behaving in the way that GrowlMail expects. This is probably because GrowlMail is incompatible with the version of Mail you're using. GrowlMail will now turn itself off. Please check the Growl website for a new version. If you're a programmer and want to debug this error, run gdb, load Mail, set a breakpoint on %s, and run.", /*comment*/ nil), __PRETTY_FUNCTION__);
	if (specificWarning)
		NSLog(@"Furthermore, the caller provided a more specific message: %@", specificWarning);

	[self shutDownGrowlMail];
}

#pragma mark Boring bookkeeping stuff

+ (void) initialize {
	[super initialize];

	// this image is leaked
	NSImage *image = [[NSImage alloc] initByReferencingFile:[GMGetGrowlMailBundle() pathForImageResource:@"GrowlMail"]];
	[image setName:@"GrowlMail"];

	[GrowlMail registerBundle];

	NSNumber *automatic = [NSNumber numberWithInt:MODE_AUTO];
	NSDictionary *defaultsDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
		@"(%account) %sender",         @"GMTitleFormat",
		@"%subject\n%body",            @"GMDescriptionFormat",
		automatic,                     @"GMSummaryMode",
		[NSNumber numberWithBool:YES], @"GMEnableGrowlMailBundle",
		[NSNumber numberWithBool:NO],  @"GMInboxOnly",
		nil];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDictionary];
	[defaultsDictionary release];

	NSLog(@"Loaded GrowlMail %@", [GMGetGrowlMailBundle() objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]);
}

+ (BOOL) hasPreferencesPanel {
	return YES;
}

+ (NSString *) preferencesOwnerClassName {
	return @"GrowlMailPreferencesModule";
}

+ (NSString *) preferencesPanelName {
	return @"GrowlMail";
}

- (id) init {
	if ((self = [super init])) {
		NSString *privateFrameworksPath = [GMGetGrowlMailBundle() privateFrameworksPath];
		NSString *growlBundlePath = [privateFrameworksPath stringByAppendingPathComponent:@"Growl.framework"];

		NSBundle *growlBundle = [NSBundle bundleWithPath:growlBundlePath];
		if (growlBundle) {
			if ([growlBundle load]) {
				// Register ourselves as a Growl delegate
				[GrowlApplicationBridge setGrowlDelegate:self];

				if ([GrowlApplicationBridge respondsToSelector:@selector(frameworkInfoDictionary)]) {
					NSDictionary *infoDictionary = [GrowlApplicationBridge frameworkInfoDictionary];
					NSLog(@"Using Growl.framework %@ (%@)",
						  [infoDictionary objectForKey:@"CFBundleShortVersionString"],
						  [infoDictionary objectForKey:(NSString *)kCFBundleVersionKey]);
				} else {
					NSLog(@"Using a version of Growl.framework older than 1.1. One of the other installed Mail plugins should be updated to Growl.framework 1.1 or later.");
				}
			}

			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(messageStoreDidAddMessages:)
														 name:@"MessageStoreMessagesAdded_inMainThread_"
													   object:nil];
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(monitoredActivityStarted:)
														 name:@"MonitoredActivityStarted_inMainThread_"
													   object:nil];
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(monitoredActivityEnded:)
														 name:@"MonitoredActivityEnded_inMainThread_"
													   object:nil];
			
#ifdef GROWL_MAIL_DEBUG
			/*
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(showAllNotifications:)
														 name:nil object:nil];
			 */
#endif
			
		} else {
			NSLog(@"Could not load Growl.framework, GrowlMail disabled");
		}
	}

	return self;
}

- (void)showAllNotifications:(NSNotification *)notification
{
	if (([[notification name] rangeOfString:@"NSWindow"].location == NSNotFound) &&
		([[notification name] rangeOfString:@"NSMouse"].location == NSNotFound) &&
		([[notification name] rangeOfString:@"_NSThread"].location == NSNotFound)) {
		NSLog(@"%@", notification);
	}
}

- (void)monitoredActivityStarted:(NSNotification *)notification
{
	if ([[[notification object] description] isEqualToString:@"Copying messages"]) {
		messageCopies++;
#ifdef GROWL_MAIL_DEBUG
		NSLog(@"Copying a message: messageCopies is now %i", messageCopies);
#endif
		if (messageCopies <= 0)
			[self shutDownGrowlMailAndWarn:@"Number of message-copying operations overflowed. How on earth did you accomplish starting more than 2 billion copying operations at a time?!"];
	}
}

- (void)monitoredActivityEnded:(NSNotification *)notification
{
	if ([[[notification object] description] isEqualToString:@"Copying messages"]) {
		if (messageCopies <= 0)
			[self shutDownGrowlMailAndWarn:@"Number of message-copying operations went below 0. It is not possible to have a negative number of copying operations!"];
		messageCopies--;
#ifdef GROWL_MAIL_DEBUG
		NSLog(@"Finished copying a message: messageCopies is now %i", messageCopies);
#endif
	}
}

- (void) dealloc {
	[self shutDownGrowlMail];
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];
}

#pragma mark GrowlApplicationBridge delegate methods

- (NSString *) applicationNameForGrowl {
	return @"GrowlMail";
}

- (NSImage *) applicationIconForGrowl {
	return [NSImage imageNamed:@"NSApplicationIcon"];
}

- (void) growlNotificationWasClicked:(NSString *)clickContext {
	if ([clickContext length]) {
		//Make sure we have all the methods we need.
		if (!class_getClassMethod([Library class], @selector(messageWithMessageID:)))
			[self shutDownGrowlMailAndWarn:@"Library does not respond to +messageWithMessageID:"];
		if (!class_getInstanceMethod([SingleMessageViewer class], @selector(initForViewingMessage:showAllHeaders:viewingState:fromDefaults:)))
			[self shutDownGrowlMailAndWarn:@"SingleMessageViewer does not respond to -initForViewingMessage:showAllHeaders:viewingState:fromDefaults:"];
		if (!class_getInstanceMethod([SingleMessageViewer class], @selector(showAndMakeKey:)))
			[self shutDownGrowlMailAndWarn:@"SingleMessageViewer does not respond to -showAndMakeKey:"];

		Message *message = [Library messageWithMessageID:clickContext];
		MessageViewingState *viewingState = [[MessageViewingState alloc] init];
		SingleMessageViewer *messageViewer = [[SingleMessageViewer alloc] initForViewingMessage:message showAllHeaders:NO viewingState:viewingState fromDefaults:NO];
		[viewingState release];
		[messageViewer showAndMakeKey:YES];
		[messageViewer release];
		[Library markMessageAsViewed:message];
	}
	[NSApp activateIgnoringOtherApps:YES];
}

- (NSDictionary *) registrationDictionaryForGrowl {
	// Register our ticket with Growl
	NSArray *allowedNotifications = [NSArray arrayWithObjects:
		NEW_MAIL_NOTIFICATION,
		NEW_JUNK_MAIL_NOTIFICATION,
		NEW_NOTE_NOTIFICATION,
		nil];
	NSDictionary *humanReadableNames = [NSDictionary dictionaryWithObjectsAndKeys:
										NSLocalizedStringFromTableInBundle(@"New mail", nil, GMGetGrowlMailBundle(), ""), NEW_MAIL_NOTIFICATION,
										NSLocalizedStringFromTableInBundle(@"New junk mail", nil, GMGetGrowlMailBundle(), ""), NEW_JUNK_MAIL_NOTIFICATION,
										NSLocalizedStringFromTableInBundle(@"New note", nil, GMGetGrowlMailBundle(), ""), NEW_NOTE_NOTIFICATION,
										nil];
	NSArray *defaultNotifications = [NSArray arrayWithObject:NEW_MAIL_NOTIFICATION];

	NSDictionary *ticket = [NSDictionary dictionaryWithObjectsAndKeys:
		allowedNotifications, GROWL_NOTIFICATIONS_ALL,
		defaultNotifications, GROWL_NOTIFICATIONS_DEFAULT,
		humanReadableNames, GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES,
		nil];
#ifdef GROWL_MAIL_DEBUG
	NSLog(@"%s: Returning Growl dictionary %@", __PRETTY_FUNCTION__, ticket);
#endif

	return ticket;
}

#pragma mark Mail notification handlers

+ (void)showNotificationForMessage:(Message *)message
{
	if (activeNotificationThreads < MAX_NOTIFICATION_THREADS) { 
		activeNotificationThreads++;
		
		/* Why use a thread?
		 *
		 * If we want the message body, it may not be immediately available.
		 * It can be retrieved without blocking if it's available, which we initially try.
		 * However, if we really, really want it, we may have to request it in a blocking fashion:
		 *		for example, if the user doesn't read the message and doesn't have Mail set to download it automatically,
		 *		we'll never get it without blocking.
		 *
		 * Blocking the main thread is, of course, out of the question.
		 *
		 * We're making some assumptions about Mail's internals, but the fact that notifications are posted on auxiliary threads
		 * and then again with a _inMainThread_ suffix on the main thread indicates that threads are being used for mail access elsewhere.
		 */
		[NSThread detachNewThreadSelector:@selector(GMShowNotificationPart1)
								 toTarget:message
							   withObject:nil];
	} else {
		[self performSelector:@selector(showNotificationForMessage:)
				   withObject:message
				   afterDelay:2.0];
	}
}

+ (void)didFinishNotificationForMessage:(Message *)message
{
#pragma unused(message)
	activeNotificationThreads--;	
}

- (void)messageStoreDidAddMessages:(NSNotification *)notification {
	if (!GMIsEnabled()) return;

#ifdef GROWL_MAIL_DEBUG
	NSLog(@"%s called", __PRETTY_FUNCTION__);
#endif
	
	if (messageCopies) {
#ifdef GROWL_MAIL_DEBUG
		NSLog(@"Ignoring because %i message copies are in process", messageCopies);
#endif
		return;
	}

	Library *store = [notification object];
	if (!store) {
		[self shutDownGrowlMailAndWarn:[NSString stringWithFormat:@"'%@' notification has no object", [notification name]]];
	}
	if ([store isKindOfClass:[LibraryStore class]]) {
		//As of Tiger, this is normal; this notification is posted a couple times (perhaps once per inbox) with a LibraryStore object.
		//This is not the notification we're looking for; we don't need to see its papers. We will move along now.
		return;
	}
	//We don't actually use the store. We only retrieve it and examine it at all because we know we don't want the one with a LibraryStore as its object.
	//The rest of the handler should be able to work just fine without proving anything else about the store, since it doesn't use the store.

	NSDictionary *userInfo = [notification userInfo];
	if (!userInfo) [self shutDownGrowlMailAndWarn:@"Notification had no userInfo"];

	NSArray *mailboxes = [userInfo objectForKey:@"mailboxes"];
#ifdef GROWL_MAIL_DEBUG
	NSLog(@"%s: Adding messages to mailboxes %@", __PRETTY_FUNCTION__, mailboxes);
#endif

	//As of Tiger, it's normal for about half of these notifications to not have any mailboxes. We simply ignore the notification in this case.
	if (!(mailboxes && [mailboxes count])) return;

	//Ignore a notification if we're ignoring all of the mailboxes involved.
	Class MailAccount_class = [MailAccount class];
	if (!class_getClassMethod(MailAccount_class, @selector(draftMailboxUids)))
		[self shutDownGrowlMailAndWarn:@"MailAccount does not respond to +draftMailboxUids"];
	if (!class_getClassMethod(MailAccount_class, @selector(outboxMailboxUids)))
		[self shutDownGrowlMailAndWarn:@"MailAccount does not respond to +outboxMailboxUids"];
	if (!class_getClassMethod(MailAccount_class, @selector(sentMessagesMailboxUids)))
		[self shutDownGrowlMailAndWarn:@"MailAccount does not respond to +sentMessagesMailboxUids"];
	if (!class_getClassMethod(MailAccount_class, @selector(trashMailboxUids)))
		[self shutDownGrowlMailAndWarn:@"MailAccount does not respond to +trashMailboxUids"];
	//We need this method to support the Inbox Only preference.
	if (!class_getClassMethod(MailAccount_class, @selector(inboxMailboxUids)))
		[self shutDownGrowlMailAndWarn:@"MailAccount does not respond to +inboxMailboxUids"];

	//Ignore messages being written.
	NSMutableSet *mailboxesToIgnore = [NSMutableSet setWithArray:[MailAccount draftMailboxUids]];
	//Ignore messages being sent.
	[mailboxesToIgnore unionSet:[NSSet setWithArray:[MailAccount outboxMailboxUids]]];
	[mailboxesToIgnore unionSet:[NSSet setWithArray:[MailAccount sentMessagesMailboxUids]]];
	//Ignore messages being deleted.
	[mailboxesToIgnore unionSet:[NSSet setWithArray:[MailAccount trashMailboxUids]]];

	NSSet *mailboxesSet = [NSSet setWithArray:mailboxes];
	NSMutableSet *mailboxesNotIgnored = [[mailboxesSet mutableCopy] autorelease];
	[mailboxesNotIgnored minusSet:mailboxesToIgnore];
	if ([mailboxesNotIgnored count] == 0U)
		return;

	NSArray *messages = [userInfo objectForKey:@"messages"];
	if (!messages) [self shutDownGrowlMailAndWarn:@"Notification's userInfo has no messages"];
	
#ifdef GROWL_MAIL_DEBUG
	NSLog(@"%s: Mail added messages [1] to mailboxes [2].\n[1]: %@\n[2]: %@", __PRETTY_FUNCTION__, messages, mailboxes);
#endif
	
	unsigned count = [messages count];

	int summaryMode = GMSummaryMode();
	if (summaryMode == MODE_AUTO) {
		if (count >= AUTO_THRESHOLD)
			summaryMode = MODE_SUMMARY;
		else
			summaryMode = MODE_SINGLE;
	}

#ifdef GROWL_MAIL_DEBUG
	NSLog(@"Got %i new messages. Summary mode was %i and is now %i", count, GMSummaryMode(), summaryMode);
#endif

	Class Message_class = [Message class];

	switch (summaryMode) {
		default:
		case MODE_SINGLE: {
			NSEnumerator *messagesEnum = [messages objectEnumerator];
			Message *message;
			while ((message = [messagesEnum nextObject])) {
				MailboxUid *mailbox = [message mailbox];
				//If this mailbox is not an inbox, and we only care about inboxes, then skip this message.
				if (GMInboxOnly() && ![[MailAccount inboxMailboxUids] containsObject:mailbox])
					continue;

				MailAccount *account = [mailbox account];
				if (![self isAccountEnabled:account])
					continue;

				if (![message isKindOfClass:Message_class])
					[self shutDownGrowlMailAndWarn:[NSString stringWithFormat:@"Message in notification was not a Message; it is %@", message]];

				if (![message respondsToSelector:@selector(isRead)] || ![message isRead]) {
					/* Don't display read messages */
					[[self class] showNotificationForMessage:message];
				}
			}
			break;
		}
		case MODE_SUMMARY: {
			if (!class_getClassMethod([MailAccount class], @selector(mailAccounts)))
				[self shutDownGrowlMailAndWarn:@"MailAccount does not respond to +mailAccounts"];
			if (!class_getInstanceMethod(Message_class, @selector(mailbox)))
				[self shutDownGrowlMailAndWarn:@"Message does not respond to -mailbox"];

			NSArray *accounts = [MailAccount mailAccounts];
			unsigned accountsCount = [accounts count];
			NSCountedSet *accountSummary = [NSCountedSet setWithCapacity:accountsCount];
			NSCountedSet *accountJunkSummary = [NSCountedSet setWithCapacity:accountsCount];
			NSEnumerator *messagesEnum = [messages objectEnumerator];
			NSArray *junkMailboxUids = [MailAccount junkMailboxUids];
			Message *message;
			while ((message = [messagesEnum nextObject])) {
				MailboxUid *mailbox = [message mailbox];
				//If this mailbox is not an inbox, and we only care about inboxes, then skip this message.
				if (GMInboxOnly() && ![[MailAccount inboxMailboxUids] containsObject:mailbox])
					continue;

				MailAccount *account = [mailbox account];
				if (![self isAccountEnabled:account])
					continue;

				if (([message isJunk]) || [junkMailboxUids containsObject:[message mailbox]])
					[accountJunkSummary addObject:account];
				else
					[accountSummary addObject:account];
			}
			NSString *title = NSLocalizedStringFromTableInBundle(@"New mail", NULL, GMGetGrowlMailBundle(), "");
			NSString *titleJunk = NSLocalizedStringFromTableInBundle(@"New junk mail", NULL, GMGetGrowlMailBundle(), "");
			NSString *description;

			MailAccount *account;

			NSEnumerator *accountSummaryEnum = [accountSummary objectEnumerator];
			while ((account = [accountSummaryEnum nextObject])) {
				if (![self isAccountEnabled:account])
					continue;

				unsigned summaryCount = [accountSummary countForObject:account];
				if (summaryCount) {
					if (summaryCount == 1) {
						description = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ \n 1 new mail", NULL, GMGetGrowlMailBundle(), "%@ is an account name"), [account displayName]];
					} else {
						description = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ \n %u new mails", NULL, GMGetGrowlMailBundle(), "%@ is an account name; %u becomes a number"), [account displayName], summaryCount];
					}
					[GrowlApplicationBridge notifyWithTitle:title
												description:description
										   notificationName:NEW_MAIL_NOTIFICATION
												   iconData:nil
												   priority:0
												   isSticky:NO
											   clickContext:@""];	// non-nil click context
				}
			}

			NSEnumerator *accountJunkSummaryEnum = [accountJunkSummary objectEnumerator];
			while ((account = [accountJunkSummaryEnum nextObject])) {
				if (![self isAccountEnabled:account])
					continue;

				unsigned summaryCount = [accountJunkSummary countForObject:account];
				if (summaryCount) {
					if (summaryCount == 1) {
						description = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ \n 1 new mail", NULL, GMGetGrowlMailBundle(), "%@ is an account name"), [account displayName]];
					} else {
						description = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ \n %u new mails", NULL, GMGetGrowlMailBundle(), "%@ is an account name; %u becomes a number"), [account displayName], summaryCount];
					}					
					[GrowlApplicationBridge notifyWithTitle:titleJunk
												description:description
										   notificationName:NEW_JUNK_MAIL_NOTIFICATION
												   iconData:nil
												   priority:0
												   isSticky:NO
											   clickContext:@""];	// non-nil click context
				}
			}
			break;
		}
	}
}

#pragma mark Preferences

- (BOOL) isAccountEnabled:(MailAccount *)account {
	BOOL isEnabled = YES;
	NSDictionary *accountSettings = [[NSUserDefaults standardUserDefaults] objectForKey:@"GMAccounts"];
	if (accountSettings) {
		NSNumber *value = [accountSettings objectForKey:[account path]];
		if (value)
			isEnabled = [value boolValue];
	}
	return isEnabled;
}

- (void) setAccount:(MailAccount *)account enabled:(BOOL)yesOrNo {
	NSDictionary *accountSettings = [[NSUserDefaults standardUserDefaults] objectForKey:@"GMAccounts"];
	NSMutableDictionary *newSettings = [[accountSettings mutableCopy] autorelease];
	if (!newSettings)
		newSettings = [NSMutableDictionary dictionaryWithCapacity:1U];
	[newSettings setObject:[NSNumber numberWithBool:yesOrNo] forKey:[account path]];
	[[NSUserDefaults standardUserDefaults] setObject:newSettings forKey:@"GMAccounts"];
}

@end

BOOL GMIsEnabled(void) {
	NSNumber *enabledNum = [[NSUserDefaults standardUserDefaults] objectForKey:@"GMEnableGrowlMailBundle"];
	return enabledNum ? [enabledNum boolValue] : YES;
}

int GMSummaryMode(void) {
	NSNumber *summaryModeNum = [[NSUserDefaults standardUserDefaults] objectForKey:@"GMSummaryMode"];
	return summaryModeNum ? [summaryModeNum intValue] : MODE_AUTO;
}

BOOL GMInboxOnly(void) {
	NSNumber *inboxOnlyNum = [[NSUserDefaults standardUserDefaults] objectForKey:@"GMInboxOnly"];
	return inboxOnlyNum ? [inboxOnlyNum boolValue] : YES;
}

NSString *GMTitleFormatString(void) {
	NSString *titleFormat = [[NSUserDefaults standardUserDefaults] stringForKey:@"GMTitleFormat"];
	return titleFormat ? titleFormat : @"(%account) %sender";
}

NSString *GMDescriptionFormatString(void) {
	NSString *descriptionFormat = [[NSUserDefaults standardUserDefaults] stringForKey:@"GMDescriptionFormat"];
	return descriptionFormat ? descriptionFormat : @"%subject\n%body";
}
