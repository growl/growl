//
//  GrowlMailWarningNote.h
//  GrowlMailUUIDPatcher
//
//  Created by Peter Hosey on 2010-11-14.
//  Copyright 2010 The Growl Project. All rights reserved.
//

/*A fatal warning will forbid the relevant bundle (whatever is selected in the GrowlMailUUIDPatcher) from being patched.
 *A non-fatal warning will still be displayed, but not prevent patching. The multiple-GrowlMails warning is one such, since it is not specific to any of the individual GrowlMail bundles.
 */

@interface GrowlMailWarningNote : NSObject {
	NSString *message;
	BOOL fatal;
}

+ (id) nonfatalWarningNoteWithMessage:(NSString *)newMessage;
+ (id) fatalWarningNoteWithMessage:(NSString *)newMessage;
- (id) initWithMessage:(NSString *)newMessage fatal:(BOOL)flag;

@property(nonatomic, readonly) NSString *message;
@property(nonatomic, readonly, getter=isFatal) BOOL fatal;

#pragma mark Prefab warning notes

//See the implementation of this method for why it needs the version number.
+ (id) warningNoteForMultipleGrowlMailsWithCurrentVersion:(NSString *)currentVersion;
+ (id) warningNoteForGrowlMailOlderThanCurrentVersion:(NSString *)currentVersion;
+ (id) warningNoteForGrowlMailInTheWrongPlace;

@end

@interface GrowlMailWarningNote (HeyTheresViewMethodsInMyModelClass)

//Returns either the caution image (NSImageNameCaution) or the white-X-on-red-circle image.
- (NSImage *) fatalityImage;

@end
