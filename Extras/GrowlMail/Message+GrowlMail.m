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
//  Message+GrowlMail.m
//  GrowlMail
//
//  Created by Ingmar Stein on 27.10.04.
//

#import "Message+GrowlMail.h"
#import "GrowlMailNotifier.h"
#import <AddressBook/AddressBook.h>
#import <Growl/Growl.h>

@interface NSString (GrowlMail_KeywordReplacing)

- (NSString *) stringByReplacingKeywords:(NSArray *)keywords
                              withValues:(NSArray *)values;

@end

@interface NSMutableString (GrowlMail_LineOrientedTruncation)

- (void) trimStringToFirstNLines:(NSUInteger)n;

@end

@implementation Message (GrowlMail)

- (void) GMShowNotificationPart1 {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	MessageBody *messageBody = nil;

	GrowlMailNotifier *notifier = [GrowlMailNotifier sharedNotifier];
	NSString *titleFormat = [notifier titleFormat];
	NSString *descriptionFormat = [notifier descriptionFormat];

	if ([titleFormat rangeOfString:@"%body"].location != NSNotFound ||
			[descriptionFormat rangeOfString:@"%body"].location != NSNotFound) {
		/* We will need the body */
		messageBody = [self messageBodyIfAvailable];
		int nonBlockingAttempts = 0;
		while (!messageBody && nonBlockingAttempts < 3) {
			/* No message body available yet, but we need one */
			nonBlockingAttempts++;
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:(0.5 * nonBlockingAttempts)]];
			
			/* We'd prefer to let whatever Mail process might want the message body get it on its own terms rather than blocking on this thread */
			messageBody = [self messageBodyIfAvailable];
		}

		/* Already tried three times (3 seconds); this time, block this thread to get it. */ 
		if (!messageBody) messageBody = [self messageBody];
	}

	[self performSelectorOnMainThread:@selector(GMShowNotificationPart2:)
						   withObject:messageBody
						waitUntilDone:NO];

	[pool drain];
}

- (void) GMShowNotificationPart2:(MessageBody *)messageBody {
	NSString *account = (NSString *)[[[self mailbox] account] displayName];
	NSString *sender = [self sender];
	NSString *senderAddress = [sender uncommentedAddress];
	NSString *subject = (NSString *)[self subject];
	NSString *body;
	GrowlMailNotifier *notifier = [GrowlMailNotifier sharedNotifier];
	NSString *titleFormat = [notifier titleFormat];
	NSString *descriptionFormat = [notifier descriptionFormat];

	/* The fullName selector is not available in Mail.app 2.0. */
	if ([sender respondsToSelector:@selector(fullName)])
		sender = [sender fullName];
	else if ([sender addressComment])
		sender = [sender addressComment];

	if (messageBody) {
		NSString *originalBody = nil;
		/* stringForIndexing selector: Mail.app 3.0 in OS X 10.4, not in 10.5. */
		if ([messageBody respondsToSelector:@selector(stringForIndexing)])
			originalBody = [messageBody stringForIndexing];
		else if ([messageBody respondsToSelector:@selector(attributedString)])
			originalBody = [[messageBody attributedString] string];
		else if ([messageBody respondsToSelector:@selector(stringValueForJunkEvaluation:)])
			originalBody = [messageBody stringValueForJunkEvaluation:NO];
		if (originalBody) {
			NSMutableString *transformedBody = [[[originalBody stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] mutableCopy] autorelease];
			NSUInteger lengthWithoutWhitespace = [transformedBody length];
			[transformedBody trimStringToFirstNLines:4U];
			NSUInteger length = [transformedBody length];
			if (length > 200U) {
				[transformedBody deleteCharactersInRange:NSMakeRange(200U, length - 200U)];
				length = 200U;
			}
			if (length != lengthWithoutWhitespace)
				[transformedBody appendString:[NSString stringWithUTF8String:"\xE2\x80\xA6"]];
			body = (NSString *)transformedBody;
		} else {
			body = @"";	
		}
	} else {
		body = @"";
	}

	NSArray *keywords = [NSArray arrayWithObjects:
		@"%sender",
		@"%subject",
		@"%body",
		@"%account",
		nil];
	NSArray *values = [NSArray arrayWithObjects:
		(sender ? sender : @""),
		(subject ? subject : @""),
		(body ? body : @""),
		(account ? account : @""),
		 nil];
	NSString *title = [titleFormat stringByReplacingKeywords:keywords withValues:values];
	NSString *description = [descriptionFormat stringByReplacingKeywords:keywords withValues:values];

	/*
	NSLog(@"Subject: '%@'", subject);
	NSLog(@"Sender: '%@'", sender);
	NSLog(@"Account: '%@'", account);
	NSLog(@"Body: '%@'", body);
	*/

	/*
	 * MailAddressManager fetches images asynchronously so they might arrive
	 * after we have sent our notification.
	 */
	/*
	MailAddressManager *addressManager = [MailAddressManager addressManager];
	[addressManager fetchImageForAddress:senderAddress];
	NSImage *image = [addressManager imageForMailAddress:senderAddress];
	*/
	ABSearchElement *personSearch = [ABPerson searchElementForProperty:kABEmailProperty
																 label:nil
																   key:nil
																 value:senderAddress
															comparison:kABEqualCaseInsensitive];

	NSData *image = nil;
	NSEnumerator *matchesEnum = [[[ABAddressBook sharedAddressBook] recordsMatchingSearchElement:personSearch] objectEnumerator];
	ABPerson *person;
	while ((!image) && (person = [matchesEnum nextObject]))
		image = [person imageData];

	//no matches in the Address Book with an icon, so use Mail's icon instead.
	if (!image)
		image = [[NSImage imageNamed:@"NSApplicationIcon"] TIFFRepresentation];

	NSString *notificationName;
	if ([self isJunk] || ([[MailAccount junkMailboxUids] containsObject:[self mailbox]])) {
		notificationName = NEW_JUNK_MAIL_NOTIFICATION;
	} else {
		if ([self respondsToSelector:@selector(type)] && [self type] == MESSAGE_TYPE_NOTE) {
			notificationName = NEW_NOTE_NOTIFICATION;
		} else {
			notificationName = NEW_MAIL_NOTIFICATION;
		}
	}

	NSString *clickContext = [self messageID];

	[GrowlApplicationBridge notifyWithTitle:title
								description:description
						   notificationName:notificationName
								   iconData:image
								   priority:0
								   isSticky:NO
							   clickContext:clickContext];	// non-nil click context

	[notifier didFinishNotificationForMessage:self];
}

@end

@implementation NSString (GrowlMail_KeywordReplacing)

- (NSString *) stringByReplacingKeywords:(NSArray *)keywords
                              withValues:(NSArray *)values
{
	NSParameterAssert([keywords count] == [values count]);
	NSMutableString *str = [[self mutableCopy] autorelease];

	NSEnumerator *keywordsEnum = [keywords objectEnumerator], *valuesEnum = [values objectEnumerator];
	NSString *keyword, *value;
	while ((keyword = [keywordsEnum nextObject]) && (value = [valuesEnum nextObject])) {
		[str replaceOccurrencesOfString:keyword
		                     withString:value
		                        options:0
		                          range:NSMakeRange(0, [str length])];
	}
	return str;
}

@end

@implementation NSMutableString (GrowlMail_LineOrientedTruncation)

- (void) trimStringToFirstNLines:(NSUInteger)n {
	NSRange range;
	NSUInteger end = 0U;
	NSUInteger length;

	range.location = 0;
	range.length = 0;
	for (NSUInteger i = 0U; i < n; ++i)
		[self getLineStart:NULL end:&range.location contentsEnd:&end forRange:range];

	length = [self length];
	if (length > end)
		[self deleteCharactersInRange:NSMakeRange(end, length - end)];
}

@end
