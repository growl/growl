//
//  Message+GrowlMail.m
//  GrowlMail
//
//  Created by Ingmar Stein on 27.10.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "Message+GrowlMail.h"
#import "GrowlMail.h"
#import "GrowlDefines.h"

@interface NSString(GrowlMail)
- (NSString *)firstNLines:(unsigned int)n;
@end

@implementation NSString(GrowlMail)
- (NSString *)firstNLines:(unsigned int)n
{
        NSRange range;
        unsigned int i;
        unsigned int index;

        range.location = 0;
        range.length = 0;
        for( i=0; i<n; ++i ) {
                [self getLineStart:NULL end:&range.location contentsEnd:&index forRange:range];
        }

        return( [self substringToIndex: index] );
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
	if( [messageBody respondsToSelector:@selector(stringForIndexing)] ) {
		body = [messageBody stringForIndexing];
	} else {
		/* Mail.app 2.0. */
		body = [messageBody stringValueForJunkEvaluation: NO];
	}
	body = [[body stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] firstNLines: 4U];

	/* The fullName selector is not available in Mail.app 2.0. */
	if( [sender respondsToSelector:@selector(fullName)] ) {
		sender = [sender fullName];
	} else if( [sender addressComment] ) {
		sender = [sender addressComment];
	}
	NSString *title = [NSString stringWithFormat: @"(%@) %@: %@", account, sender, subject];
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
	if( !image ) {
//		NSLog(@"Image: Mail.app");
//		icon = [[NSApp applicationIconImage] TIFFRepresentation];
//		NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
//		image = [workspace iconForFile: [workspace fullPathForApplication: @"Mail"]];
		image = [NSImage imageNamed:@"NSApplicationIcon"];
	}
	NSDictionary *notif = [NSDictionary dictionaryWithObjectsAndKeys:
		NSLocalizedStringFromTableInBundle(@"New mail", nil, [GrowlMail bundle], @""), GROWL_NOTIFICATION_NAME,
		@"GrowlMail", GROWL_APP_NAME,
		title, GROWL_NOTIFICATION_TITLE,
		[image TIFFRepresentation], GROWL_NOTIFICATION_ICON,
		body, GROWL_NOTIFICATION_DESCRIPTION,
		nil];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION
																   object:nil
																 userInfo:notif];
}
@end
