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
	id<GTPSettingsProtocol>		_delegate;
	
	NSTokenField				*_source;
	NSTokenField				*_title;
	NSArray						*_titleString;
	NSTokenField				*_description;
	NSArray						*_descriptionString;
	SRRecorderControl			*_shortcut;
	SGKeyCombo					*_keyCombo;
	NSButton					*_backgroundOnly;
}

@property (assign) id<GTPSettingsProtocol> delegate;
@property (assign) SGKeyCombo	*keyCombo;
@property (assign) NSArray *titleString;
@property (assign) NSArray *descriptionString;

@property (assign) IBOutlet NSTokenField *source;
@property (assign) IBOutlet NSTokenField *title;
@property (assign) IBOutlet NSTokenField *description;
@property (assign) IBOutlet SRRecorderControl *shortcut;
@property (assign) IBOutlet NSButton *backgroundOnly;

- (IBAction)backgroundOnly:(id)sender;

@end
