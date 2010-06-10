//
//  GTPSettingsWindowController.h
//  GrowlTunes
//
//  Created by Rudy Richter on 9/27/09.
//  Copyright 2009 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ShortcutRecorder/ShortcutRecorder.h>
#import "SGKeyCombo.h"
#import "GTPToken.h"

@protocol GTPSettingsProtocol

- (void)keyComboChanged:(id)newCombo;
- (void)titleStringChanged:(NSString*)newTitle;
- (void)descriptionStringChanged:(NSString*)newDescription;

@end

@interface GTPSettingsWindowController : NSWindowController 
{
	id<GTPSettingsProtocol> _delegate;
	
	IBOutlet NSTokenField *_source;
	IBOutlet NSTokenField *_title;
	NSArray *_titleString;
	IBOutlet NSTokenField *_description;
	NSArray *_descriptionString;
	IBOutlet SRRecorderControl *_shortcut;
			 SGKeyCombo			*_keyCombo;
}

@property (assign) id<GTPSettingsProtocol> delegate;
@property (assign) SGKeyCombo	*keyCombo;
@property (assign) NSArray *titleString;
@property (assign) NSArray *descriptionString;
@end
