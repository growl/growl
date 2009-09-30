//
//  GrowlMailNotifier.h
//  GrowlMail
//
//  Created by Peter Hosey on 2009-05-10.
//  Copyright 2009 Peter Hosey. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>
#import "MailHeaders.h"

#define NEW_MAIL_NOTIFICATION		@"New mail"
#define NEW_JUNK_MAIL_NOTIFICATION	@"New junk mail"
#define NEW_NOTE_NOTIFICATION		@"New note"

/*!	@brief	Summary mode constants
 *
 *	GrowlMail can post two kinds of notifications: One notification for every message the user receives, or a summary notification that lists only the number of messages the user received on a single account.
 *
 *	@par	The GMSummaryMode user default contains a number that specifies how GrowlMail should post notifications: always as single-message notifications, always as a summary, or automatically chosen based on number of messages added to the store in a single operation.
 */
enum GrowlMailSummaryMode {
	/*!	@brief	Automatically use summary mode or not based on how many messages the user receives within a span of time
	 */
	GrowlMailSummaryModeAutomatic = 0,
	/*!	@brief	Always post one notification per message
	 */
	GrowlMailSummaryModeDisabled = 1,
	/*!	@brief	Always post a summary notification per account
	 */
	GrowlMailSummaryModeAlways = 2
};
typedef NSInteger GrowlMailSummaryMode;

/*!	@brief	Object that posts GrowlMail notifications
 *
 *	This is a singleton object because the current Growl API can only handle one delegate at a time.
 */
@interface GrowlMailNotifier : NSObject <GrowlApplicationBridgeDelegate>
{
	BOOL shouldNotify;
}

/*!	@brief	Return the One True \c GrowlMailNotifier Instance, creating it if necessary.
 */
+ (id) sharedNotifier;

/*!	@brief	Creates or retains, then returns, the One True \c GrowlMailNotifier instance.
 *
 *	If the shared instance does not yet exist, this method makes the receiver the shared instance and initializes it.
 *	If the shared instance does already exist, this method releases the receiver, then returns the shared instance.
 *	Either way, it then returns the shared instance.
 *
 *	@par	This method will return \c nil if the suicide pill has previously been invoked.
 *
 *	@return	The One True GrowlMailNotifier instance, or \c nil.
 */
- (id) init;

- (BOOL) isEnabled;
- (GrowlMailSummaryMode) summaryMode;
/*!	@brief	Only post notifications for messages added to an account's inbox, not to other mailboxes (folders).
 */
- (BOOL) inboxOnly;

/*!	@brief	Returns the correct format string for Growl notification titles.
 *
 *	The returned format is only useful for single-message notifications. Summary notifications do not use this format.
 */
- (NSString *) titleFormat;
/*!	@brief	Returns the correct format string for Growl notification descriptions.
 *
 *	The returned format is only useful for single-message notifications. Summary notifications do not use this format.
 */
- (NSString *) descriptionFormat;

/*!	@brief	Return whether the given account is enabled for notifications
 *
 *	@return	\c YES if GrowlMail will post notifications for this account; \c NO if it won't.
 */
- (BOOL) isAccountEnabled:(MailAccount *)account;
/*!	@brief	Change whether the given account is enabled for notifications
 *
 *	@param	account	The account to enable or disable.
 *	@param	yesOrNo	If \c YES, post notifications for messages for \a account in the future; if \c NO, don't post notifications for messages for that account.
 */
- (void) setAccount:(MailAccount *)account enabled:(BOOL)yesOrNo;

- (NSString *) applicationNameForGrowl;
- (NSImage *) applicationIconForGrowl;
- (void) growlNotificationWasClicked:(NSString *)clickContext;
- (NSDictionary *) registrationDictionaryForGrowl;

- (void)didFinishNotificationForMessage:(Message *)message;


/*!	@brief	Disable GrowlMail and print a warning message
 *
 *	GrowlMail is paranoid about changes in Mail's behavior. Whenever it detects such a change, it calls this function, which removes GrowlMail's notification-observer registrations and stops it from posting Growl notifications. We call it the “suicide pill”.
 *
 *	@param	specificWarning	Additional information to add to the warning message. Can be \c nil.
 */
void GMShutDownGrowlMailAndWarn(NSString *specificWarning);
@end
