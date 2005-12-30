/*
 
 BSD License
 
 Copyright (c) 2005-2006, Jesper <wootest@gmail.com>
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
 
 For more info on this products or on the technologies on which it builds: 
 Growl: <http://growl.info/>
 Gmail: <http://gmail.com>
 Gmail Notifier: <http://toolbar.google.com/gmail-helper/index.html>
 
 Gmail+Growl: <http://wootest.net/gmailgrowl/>
 
 */

//
//  PrefsController.m
//  GMNGrowl
//
//  Created by Jesper on 2005-09-28.
//  Copyright 2005-2006 Jesper. All rights reserved.
//  Contact: <wootest@gmail.com>.
//

#import "PrefsController.h"

#define		GMNGrowlNotificationFormatUDK		@"GMNGrowlNotificationFormat"
#define		GMNGrowlNotificationTextFormatUDK	@"GMNGrowlNotificationTextFormat"
#define		GMNGrowlDontUseABIconsUDK			@"GMNGrowlDontUseABIcons"

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

#define GMNGrowlNotificationFormat		[NSString stringWithFormat:@"New mail! \"%@\" from %@",	MAKEPLACEHOLDER(GmailMessageDictTitleKey), MAKEPLACEHOLDER(GmailMessageDictAuthorNameKey)]
#define GMNGrowlNotificationTextFormat	[NSString stringWithFormat:@"%@", MAKEPLACEHOLDER(GmailMessageDictSummaryKey)]

#define		GMNGrowlNotificationFormatTag		2010
#define		GMNGrowlNotificationFormatTextTag	2020
#define		GMNGrowlDontUseABIconsTag			2050

#define		GMNGrowlLookupNumber(x)				[NSNumber numberWithInt:x]

#define		GMNGrowlLookupDict					[NSDictionary dictionaryWithObjectsAndKeys:GMNGrowlNotificationFormatUDK, GMNGrowlLookupNumber(GMNGrowlNotificationFormatTag), GMNGrowlNotificationTextFormatUDK, GMNGrowlLookupNumber(GMNGrowlNotificationFormatTextTag), GMNGrowlDontUseABIconsUDK, GMNGrowlLookupNumber(GMNGrowlDontUseABIconsTag), nil]


@implementation PrefsController

- (void) awakeFromNib {
	[self updateFields];
	[NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(updateFields) userInfo:nil repeats:YES];
}

- (void)controlTextDidBeginEditing:(NSNotification *)aNotification {
	NSLog(@"began editing");
	isEditing = YES;
}


- (void)controlTextDidEndEditing:(NSNotification *)aNotification {
	NSLog(@"ended editing");
	isEditing = NO;
}

- (void) updateFields {
//	NSLog(@"update fields");
	if (isEditing) {
//		NSLog(@"is editing...");
		return;
	}
	CFBooleanRef boo = (CFBooleanRef)CFPreferencesCopyValue((CFStringRef)GMNGrowlDontUseABIconsUDK,kCFPreferencesAnyApplication,kCFPreferencesCurrentUser,kCFPreferencesAnyHost);
	[abIcons setState:((boo == kCFBooleanFalse) ? NSOnState : NSOffState)];
	NSString *title = (NSString *)((CFStringRef)CFPreferencesCopyValue((CFStringRef)GMNGrowlNotificationFormatUDK,kCFPreferencesAnyApplication,kCFPreferencesCurrentUser,kCFPreferencesAnyHost));
	NSString *body = (NSString *)((CFStringRef)CFPreferencesCopyValue((CFStringRef)GMNGrowlNotificationTextFormatUDK,kCFPreferencesAnyApplication,kCFPreferencesCurrentUser,kCFPreferencesAnyHost));
	[titleFormat setStringValue:((title != nil) ? title : GMNGrowlNotificationFormat)];
	[bodyFormat setStringValue:((body != nil) ? body : GMNGrowlNotificationTextFormat)];	
}

- (IBAction)prefsChanged:(id)sender
{
	NSString *key = nil; CFPropertyListRef value; BOOL proceed = NO;
	switch ([sender tag]) {
		case GMNGrowlDontUseABIconsTag:
			value = (([(NSButton *)sender state] == NSOffState) ? kCFBooleanTrue : kCFBooleanFalse);
			proceed = YES;
//			NSLog(@"don't use Address Book icons: %@", (([(NSButton *)sender state] == NSOffState) ? @"No, don't" : @"Yes, do"));
			break;
		case GMNGrowlNotificationFormatTag:
		case GMNGrowlNotificationFormatTextTag:
			value = (CFStringRef)[(NSTextField *)sender stringValue];
//			NSLog(@"string value: %@", [(NSTextField *)sender stringValue]);
			proceed = YES;
	}
	if (proceed) {
			key = (NSString *)[GMNGrowlLookupDict objectForKey:GMNGrowlLookupNumber([sender tag])];
//			NSLog(@"key: %@ (metakey: %@)", key, GMNGrowlLookupNumber([sender tag]));
			CFPreferencesSetValue((CFStringRef)key,value,kCFPreferencesAnyApplication,kCFPreferencesCurrentUser,kCFPreferencesAnyHost);
			if (CFPreferencesSynchronize(kCFPreferencesAnyApplication,kCFPreferencesCurrentUser,kCFPreferencesAnyHost))
				NSLog(@"synchronized...");
	}
	
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
	return YES;
}

@end
