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
#import "GrowlMail.h"
#import <Growl/Growl.h>

@interface NSString(GrowlMail)
- (NSString *)firstNLines:(unsigned int)n;
@end

@implementation NSString(GrowlMail)
- (NSString *)firstNLines:(unsigned int)n
{
	NSRange range;
	unsigned int i;
	unsigned int end;

	range.location = 0;
	range.length = 0;
	for( i=0; i<n; ++i ) {
		[self getLineStart:NULL end:&range.location contentsEnd:&end forRange:range];
	}

	return [self substringToIndex:end];
}
@end

@implementation Message(GrowlMail)
- (void)showNotification
{
	NSString *account = [[[self messageStore] account] displayName];
	NSString *sender = [self sender];
	NSString *senderAddress = [sender uncommentedAddress];
	NSString *subject = [self subject];
	NSString *body;
	MessageBody *messageBody = [self messageBody];
	if ( [messageBody respondsToSelector:@selector(stringForIndexing)] ) {
		body = [messageBody stringForIndexing];
	} else {
		/* Mail.app 2.0. */
		body = [messageBody stringValueForJunkEvaluation: NO];
	}
	body = [[body stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] firstNLines: 4U];

	/* The fullName selector is not available in Mail.app 2.0. */
	if ( [sender respondsToSelector:@selector(fullName)] ) {
		sender = [sender fullName];
	} else if ( [sender addressComment] ) {
		sender = [sender addressComment];
	}
	NSString *title = [NSString stringWithFormat: @"(%@) %@", account, sender];
	NSString *description = [NSString stringWithFormat: @"%@\n%@",  subject, body];
/*
	NSLog( @"Subject: '%@'", subject );
	NSLog( @"Sender: '%@'", sender );
	NSLog( @"Account: '%@'", account );
	NSLog( @"Body: '%@'", body );
	NSLog( @"Title: '%@'", title );
*/
	MailAddressManager *addressManager = [MailAddressManager addressManager];
	[addressManager fetchImageForAddress: senderAddress];
	NSImage *image = [addressManager imageForMailAddress: senderAddress];
	if ( !image ) {
//		NSLog(@"Image: Mail.app");
//		icon = [[NSApp applicationIconImage] TIFFRepresentation];
//		NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
//		image = [workspace iconForFile: [workspace fullPathForApplication: @"Mail"]];
		image = [NSImage imageNamed:@"NSApplicationIcon"];
	}
	Class gab = [GrowlMail growlApplicationBridge];
	[gab notifyWithTitle:title
			 description:description
		notificationName:NSLocalizedStringFromTableInBundle(@"New mail", nil, [GrowlMail bundle], @"")
				iconData:[image TIFFRepresentation]
				priority:0
				isSticky:NO
			clickContext:@""];	// non-nil click context
}
@end
