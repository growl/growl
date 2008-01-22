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

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>
#import "MailHeaders.h"
#include <pthread.h>

#define NEW_MAIL_NOTIFICATION		@"New mail"
#define NEW_JUNK_MAIL_NOTIFICATION	@"New junk mail"
#define NEW_NOTE_NOTIFICATION		@"New note"

@interface GrowlMail : MVMailBundle <GrowlApplicationBridgeDelegate>
{
}

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

+ (void)didFinishNotificationForMessage:(Message *)message;

@end

BOOL GMIsEnabled(void);
int  GMSummaryMode(void);
BOOL GMInboxOnly(void);
NSBundle *GMGetGrowlMailBundle(void);
NSString *GMTitleFormatString(void);
NSString *GMDescriptionFormatString(void);
