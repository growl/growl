//
//  GrowlMailPreferencesModule.m
//  GrowlMail
//
//  Created by Ingmar Stein on 29.10.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlMailPreferencesModule.h"
#import "GrowlMail.h"

@interface MailAccount(GrowlMail)
+ (NSArray *)remoteMailAccounts;
@end

@implementation MailAccount(GrowlMail)
+ (NSArray *)remoteMailAccounts;
{
	NSArray *mailAccounts = [MailAccount mailAccounts];
	NSMutableArray *remoteAccounts = [NSMutableArray arrayWithCapacity: [mailAccounts count]];
	NSEnumerator *enumerator = [mailAccounts objectEnumerator];
	id account;
	Class localAccountClass = [LocalAccount class];
	while( (account = [enumerator nextObject]) ) {
		if( ![account isKindOfClass:localAccountClass] ) {
			[remoteAccounts addObject:account];
		}
	}

	return( remoteAccounts );
}
@end

@implementation GrowlMailPreferencesModule
- (void)awakeFromNib
{
	NSTableColumn *activeColumn = [accountsView tableColumnWithIdentifier:@"active"];
	[[activeColumn dataCell] setImagePosition:NSImageOnly]; // center the checkbox 
}

- (void)initializeFromDefaults
{
	[super initializeFromDefaults];

	GrowlMail *mailBundle = [GrowlMail sharedInstance];
	[enabledButton setState:([mailBundle isEnabled] ? NSOnState : NSOffState)];
	[junkButton setState:([mailBundle isIgnoreJunk] ? NSOnState : NSOffState)];
	[summaryButton setState:([mailBundle showSummary] ? NSOnState : NSOffState)];
}

- (NSString *)preferencesNibName
{
    return( @"GrowlMailPreferencesPanel" );
}

- (id)viewForPreferenceNamed:(NSString *)aName
{
	if( !_preferencesView ) {
		[NSBundle loadNibNamed:[self preferencesNibName] owner:self];
	}
	return( _preferencesView );
}

- (NSString *)titleForIdentifier:(NSString *)aName
{
	return( @"GrowlMail" );
}

- (NSImage *)imageForPreferenceNamed:(NSString *)aName
{
	return( [NSImage imageNamed:@"GrowlMail"] );
}

- (NSSize)minSize
{
	return( NSMakeSize( 298, 215 ) );
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return( [[MailAccount remoteMailAccounts] count] );
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	MailAccount *account = [[MailAccount remoteMailAccounts] objectAtIndex:rowIndex];
	if( [[aTableColumn identifier] isEqualToString:@"active"] ) {
		return( [NSNumber numberWithBool:[[GrowlMail sharedInstance] isAccountEnabled:[account path]]] );
	} else {
		return( [account displayName] );
	}
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	MailAccount *account = [[MailAccount remoteMailAccounts] objectAtIndex:rowIndex];
	[[GrowlMail sharedInstance] setAccountEnabled:[anObject boolValue] path:[account path]];
}

- (IBAction)toggleEnable:(id)sender
{
    [[GrowlMail sharedInstance] setEnabled:([sender state] == NSOnState)];
}

- (IBAction)toggleIgnoreJunk:(id)sender
{
    [[GrowlMail sharedInstance] setIgnoreJunk:([sender state] == NSOnState)];
}

- (IBAction)toggleShowSummary:(id)sender
{
    [[GrowlMail sharedInstance] setShowSummary:([sender state] == NSOnState)];
}
@end
