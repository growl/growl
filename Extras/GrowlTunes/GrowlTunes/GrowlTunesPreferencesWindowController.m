//
//  GrowlTunesPreferencesWindowController.m
//  GrowlTunes
//
//  Created by Daniel Siemer on 11/18/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlTunesPreferencesWindowController.h"
#import "GrowlTunesController.h"
#import "GrowlTunesFormattingController.h"
#import "FormattingToken.h"

@interface GrowlTunesPreferencesWindowController ()

@property (readonly, nonatomic) GrowlTunesFormattingController *formatController;

@end

@implementation GrowlTunesPreferencesWindowController

-(id)initWithWindowNibName:(NSString *)windowNibName
{
	if ((self = [super initWithWindowNibName:windowNibName])) {
		// Initialization code here.
	}
	return self;
}

-(GrowlTunesFormattingController*)formatController {
	return [(GrowlTunesController*)NSApp formatController];
}

- (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject
{
	if ([representedObject respondsToSelector:@selector(displayString)]) {
		return [representedObject valueForKey:@"displayString"];
	}
	return representedObject;
}

- (NSString *)tokenField:(NSTokenField *)tokenField editingStringForRepresentedObject:(id)representedObject
{
	if ([representedObject respondsToSelector:@selector(editingString)]) {
		return [representedObject valueForKey:@"editingString"];
	}
	return representedObject;
}

- (id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString
{
	return AUTORELEASE([[FormattingToken alloc] initWithEditingString:editingString]);
}

- (NSTokenStyle)tokenField:(NSTokenField *)tokenField styleForRepresentedObject:(id)representedObject
{
	if ([representedObject respondsToSelector:@selector(tokenStyle)]) {
		return (NSTokenStyle)[representedObject performSelector:@selector(tokenStyle)];
	}
	return NSPlainTextTokenStyle;
}

- (NSArray*)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(NSUInteger)index {
	dispatch_async(dispatch_get_main_queue(), ^{
		[[self formatController] saveTokens];
	});
	return tokens;
}

- (NSArray*)tokenField:(NSTokenField *)tokenField readFromPasteboard:(NSPasteboard *)pboard {
	NSMutableArray *results = [NSMutableArray array];
	NSArray *pBoardItems = [pboard readObjectsForClasses:[NSArray arrayWithObject:[NSString class]] options:nil];
	[pBoardItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		FormattingToken *token = [[FormattingToken alloc] initWithEditingString:obj];
		[results addObject:token];
		RELEASE(token);
	}];
	return results;
}

- (BOOL)tokenField:(NSTokenField *)tokenField writeRepresentedObjects:(NSArray *)objects toPasteboard:(NSPasteboard *)pboard {
	[pboard writeObjects:[objects valueForKey:@"editingString"]];
	return YES;
}

@end
