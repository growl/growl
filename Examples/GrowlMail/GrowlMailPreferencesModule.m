//
//  GrowlMailPreferencesModule.m
//  GrowlMail
//
//  Created by Ingmar Stein on 29.10.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlMailPreferencesModule.h"
#import "GrowlMail.h"

@implementation GrowlMailPreferencesModule
- (void) initializeFromDefaults
{
	[super initializeFromDefaults];

	GrowlMail *mailBundle = [GrowlMail sharedInstance];
	[enabledButton setState:([mailBundle isEnabled] ? NSOnState : NSOffState)];
	[junkButton setState:([mailBundle isIgnoreJunk] ? NSOnState : NSOffState)];
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

- (IBAction)toggleEnable:(id)sender
{
    [[GrowlMail sharedInstance] setEnabled:([sender state] == NSOnState)];
}

- (IBAction)toggleIgnoreJunk:(id)sender
{
    [[GrowlMail sharedInstance] setIgnoreJunk:([sender state] == NSOnState)];
}
@end
