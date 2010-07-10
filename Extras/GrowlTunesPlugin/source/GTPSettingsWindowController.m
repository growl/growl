//
//  GTPSettingsWindowController.m
//  GrowlTunes
//
//  Created by Rudy Richter on 9/27/09.
//  Copyright 2009 The Growl Project. All rights reserved.
//

#import "GTPSettingsWindowController.h"
#import "GTPCommon.h"

#import "GTPController.h"

@implementation GTPSettingsWindowController
@synthesize delegate = _delegate;
@synthesize keyCombo = _keyCombo;
@synthesize titleString = _titleString;
@synthesize descriptionString = _descriptionString;

@synthesize source = _source;
@synthesize title = _title;
@synthesize description = _description;
@synthesize shortcut = _shortcut;

@synthesize backgroundOnly = _backgroundOnly;

- (void)setKeyCombo:(SGKeyCombo*)keyCombo
{
	_keyCombo = keyCombo;
}

- (void)windowDidLoad
{
	KeyCombo combo = {SRCarbonToCocoaFlags(_keyCombo.modifiers), _keyCombo.keyCode};
	[_shortcut setKeyCombo:combo];
	
	NSString* str = [NSString stringWithCString:"" encoding:NSUTF8StringEncoding];
	NSCharacterSet* set = [NSCharacterSet characterSetWithCharactersInString: str];
	[_title setTokenizingCharacterSet: set];
	[_title setTokenStyle: NSPlainTextTokenStyle];
	
	[_source setEditable:YES];
	NSMutableArray *tokens = [[[NSMutableArray alloc] init] autorelease];
	for(int i = 0; i < 10; i++)
	{
		GTPToken* token = [[[GTPToken alloc] init] autorelease];
		[token setText:tokenTitles[i]];
		[tokens addObject:token];
	}
	
	[_source setObjectValue:tokens];
	[_source setEditable:NO];
	
	[self addObserver:self forKeyPath:@"titleString" options:NSKeyValueObservingOptionNew context:NULL];
	[self addObserver:self forKeyPath:@"descriptionString" options:NSKeyValueObservingOptionNew context:NULL];
	
	NSDictionary *defaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:GTPBundleIdentifier];
	[_title setObjectValue:[defaults objectForKey:@"titleString"]];
	[_description setObjectValue:[defaults objectForKey:@"descriptionString"]];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:[self window]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{	
#pragma unused(object, change, context)
	if([keyPath isEqual:@"titleString"])
	{
		NSString *title = [NSString string];
		for(NSString *segment in [self titleString])
		{
			title = [title stringByAppendingFormat:@" %@", segment];
		}
		NSMutableDictionary *defaults = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:GTPBundleIdentifier] mutableCopy];
		[defaults setValue:title forKey:@"titleString"];
		[[NSUserDefaults standardUserDefaults] setPersistentDomain:defaults forName:GTPBundleIdentifier];

		[[[GTPController sharedInstance] notification] setTitleFormat:title];
	}
	else if([keyPath isEqual:@"descriptionString"])
	{
		NSString *description = [NSString string];
		for(NSString *segment in [self descriptionString])
		{
			description = [description stringByAppendingFormat:@" %@", segment];
		}
		NSMutableDictionary *defaults = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:GTPBundleIdentifier] mutableCopy];
		if(!defaults)
			defaults = [NSMutableDictionary dictionary];
		[defaults setValue:description forKey:@"descriptionString"];
		[[NSUserDefaults standardUserDefaults] setPersistentDomain:defaults forName:GTPBundleIdentifier];
		[[[GTPController sharedInstance] notification] setDescriptionFormat:description];

	}
}

- (IBAction)backgroundOnly:(NSButton*)sender
{
	NSMutableDictionary *defaults = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:GTPBundleIdentifier] mutableCopy];
	if(!defaults)
		defaults = [NSMutableDictionary dictionary];
	[defaults setValue:[NSNumber numberWithBool:[sender state]] forKey:@"notifyInBGOnly"];
	[[NSUserDefaults standardUserDefaults] setPersistentDomain:defaults forName:GTPBundleIdentifier];
	
}
#pragma mark SRRecorderDelegate
- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason
{
#pragma unused(aRecorder, keyCode, flags, aReason)
	return NO;
}

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo
{
#pragma unused(aRecorder)
	_keyCombo.modifiers = SRCocoaToCarbonFlags(newKeyCombo.flags);
	_keyCombo.keyCode = newKeyCombo.code;
	[[self delegate] keyComboChanged:_keyCombo];
}

#pragma mark NSToken Delegate

- (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)_tokens atIndex:(unsigned)tokenIndex
{	
#pragma unused (tokenField, tokenIndex)
	/*for (id anObject in _tokens) 
	{
		//code to act on each element as it is returned
		for(id token in [_source objectValue])
		{
			NSLog (@"%@", anObject);
		}
	}*/
	return _tokens; //array;
}


- (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject
{
#pragma unused(tokenField)
	NSString* string;
	if ([representedObject isKindOfClass: [GTPToken class]]) {
		GTPToken* token = representedObject;
		string = [token text];
	}
	else
		string = representedObject;
	return string;
}

- (id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString
{
#pragma unused (tokenField)
	GTPToken *result = nil;
	NSArray *objectValue = [_source objectValue];
	for(GTPToken *token in objectValue)
	{
		if([[token text] isEqual:editingString])
			result = token;
	}
	return result;
}

- (NSTokenStyle)tokenField:(NSTokenField *)tokenField styleForRepresentedObject:(id)representedObject
{
#pragma unused(tokenField)
	NSTokenStyle result = NSPlainTextTokenStyle;
	
	if ([representedObject isKindOfClass: [GTPToken class]])
		result = NSRoundedTokenStyle;
	return result;
}

#pragma mark NSWindow Notifications

- (void)windowWillClose:(NSNotification*)notification
{
	NSWindow *window = [notification object];
	if([window isEqual:[self window]])
	{
		[self didChangeValueForKey:@"titleString"];
		[self didChangeValueForKey:@"descriptionString"];
	}
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:[self window]];
}
@end
