//
//  GrowlMailWarningNote.m
//  GrowlMailUUIDPatcher
//
//  Created by Peter Hosey on 2010-11-14.
//  Copyright 2010–2011 The Growl Project. All rights reserved.
//

#import "GrowlMailWarningNote.h"

@implementation GrowlMailWarningNote

+ (id) nonfatalWarningNoteWithMessage:(NSString *)newMessage {
	return [[[self alloc] initWithMessage:newMessage fatal:NO] autorelease];
}
+ (id) fatalWarningNoteWithMessage:(NSString *)newMessage {
	return [[[self alloc] initWithMessage:newMessage fatal:NO] autorelease];
}
- (id) initWithMessage:(NSString *)newMessage fatal:(BOOL)flag {
	if ((self = [super init])) {
		message = [newMessage copy];
		fatal = flag;
	}
	return self;
}

@synthesize message;
@synthesize fatal;

#pragma mark Prefab warning notes

+ (id) warningNoteForMultipleGrowlMailsWithCurrentVersion:(NSString *)currentVersion {
	//Including the current version here is a hack to get the text to measure properly.
	return [self nonfatalWarningNoteWithMessage:[NSString stringWithFormat:NSLocalizedString(@"You have multiple copies of GrowlMail installed. The one that Mail uses may not be the one you expect.\nYou should run the GrowlMail uninstaller and then reinstall the current version of GrowlMail, which is %@.", /*comment*/ @"Warning notes"), currentVersion]];
}
+ (id) warningNoteForGrowlMailOlderThanCurrentVersion:(NSString *)currentVersion {
	return [self fatalWarningNoteWithMessage:[NSString stringWithFormat:NSLocalizedString(@"This copy of GrowlMail is old. The current version, available from the GrowlMail web page, is %@.", /*comment*/ @"Warning notes"), currentVersion]];
}
+ (id) warningNoteForGrowlMailInTheWrongPlace {
	/*This is not necessarily fatal; the user might want their GrowlMail there for some reason.
	 *However, if we allow this, we have to implement authorization to perform the UUID adds with privileges. A lot of work and easy to get wrong.
	 *We may do that in a future version, but for now, we'll only allow hacking the GrowlMail in the Home folder, where our Installer package installs it.
	 */
	return [self fatalWarningNoteWithMessage:NSLocalizedString(@"This copy of GrowlMail is installed in the wrong place.\nThe correct place is within the Library folder in your Home folder. The GrowlMail Installer package puts it in the correct place; you should uninstall GrowlMail, then reinstall it.", /*comment*/ @"Warning notes")];
}

#pragma mark Debugging

- (NSString *) description {
	return [NSString stringWithFormat:@"<%@ %p (%@) \"%@\">",
		[self class], self,
		fatal ? @"fatal" : @"non-fatal",
		message,
		nil];
}

@end

@implementation GrowlMailWarningNote (HeyTheresViewMethodsInMyModelClass)

- (NSImage *) fatalityImage {
	return fatal ? [NSImage imageNamed:@"WhiteXOnRedCircle"] : [NSImage imageNamed:NSImageNameCaution];
}

@end
