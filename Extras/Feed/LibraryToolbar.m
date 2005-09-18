/*

BSD License

Copyright (c) 2004, Keith Anderson
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

*	Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.
*	Redistributions in binary form must reproduce the above copyright notice,
	this list of conditions and the following disclaimer in the documentation
	and/or other materials provided with the distribution.
*	Neither the name of keeto.net or Keith Anderson nor the names of its
	contributors may be used to endorse or promote products derived
	from this software without specific prior written permission.

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


*/


#import "LibraryToolbar.h"

#define ADD_FEED_ICON @"NewFeed"
#define REMOVE_FEED_ICON @"DeleteItem"
#define UPDATE_ALL_ICON @"Update2"
#define TOGGLE_DRAWER_ICON @"ToggleFeedDrawer"
#define MARK_ALL_READ_ICON @"MarkAllRead"


static void addToolbarItem(NSMutableDictionary *aDict, NSString *identifier, NSString *label, NSString *paletteLabel,
		NSString *toolTip, id target, SEL settingSelector, id itemContent, SEL action, NSMenu *menu){
        
	NSMenuItem *			menuItem;
	NSToolbarItem *			toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];
    
	[toolbarItem setLabel: label];
	[toolbarItem setPaletteLabel: paletteLabel];
	[toolbarItem setToolTip: toolTip];
	[toolbarItem setTarget: target];
	[toolbarItem performSelector: settingSelector withObject:itemContent];
	[toolbarItem setAction: action];
	if( menu != nil ){
		menuItem = [[[NSMenuItem alloc] init] autorelease];
		[menuItem setSubmenu: menu];
		[menuItem setTitle: [menu title]];
		[toolbarItem setMenuFormRepresentation: menuItem];
	}
	[aDict setObject: toolbarItem forKey: identifier];
}


@implementation LibraryToolbar

-(id)initWithWindow:(NSWindow *)window{
    self = [super init];
    if( self ){
        NSToolbar *             toolbar = [[[NSToolbar alloc] initWithIdentifier: FEED_LIBRARAY_TOOLBAR] autorelease];
        
        toolbarItems = [[NSMutableDictionary dictionary] retain];
        
        addToolbarItem(toolbarItems, ADD_FEED, @"New Feed", @"New Feed", @"Add a new Feed to the library",
            [window delegate],@selector(setImage:), [NSImage imageNamed:ADD_FEED_ICON],@selector(newFeed:), nil);
            
        addToolbarItem(toolbarItems, REMOVE_FEED, @"Delete", @"Delete Item", @"Remove selected Item(s) from the library",
            [window delegate],@selector(setImage:), [NSImage imageNamed:REMOVE_FEED_ICON],@selector(delete:), nil);
            
        addToolbarItem(toolbarItems, UPDATE_ALL, @"Update", @"Update Now", @"Update selected Feeds immediately",
            [window delegate],@selector(setImage:), [NSImage imageNamed:UPDATE_ALL_ICON],@selector(refresh:), nil);
            
        addToolbarItem(toolbarItems, TOGGLE_DRAWER, @"Feeds", @"Toggle Feeds", @"Show or Hide the Feed drawer",
            [window delegate],@selector(setImage:), [NSImage imageNamed:TOGGLE_DRAWER_ICON],@selector(toggleFeedDrawer:), nil);
        
		addToolbarItem(toolbarItems, MARK_ALL_READ, @"Mark All Read", @"Mark All Read", @"Mark all currently selected sources as read",
            [window delegate],@selector(setImage:), [NSImage imageNamed:MARK_ALL_READ_ICON],@selector(markAllRead:), nil);
		
        [toolbar setDelegate: self];
        [toolbar setAllowsUserCustomization:YES];
        [toolbar setAutosavesConfiguration:YES];
        [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
        [window setToolbar: toolbar];
    }
    return self;
}

-(void)dealloc{
	[toolbarItems release];
	[super dealloc];
}

-(NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag{
#pragma unused(toolbar,flag)
	NSToolbarItem *			newItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
	NSToolbarItem *			item = [toolbarItems objectForKey: itemIdentifier];
	
	[newItem setLabel: [item label]];
	[newItem setPaletteLabel: [item paletteLabel]];
	if( [item view]!= NULL ){
		[newItem setView:[item view]];
	}else{
		[newItem setImage:[item image]];
	}
	[newItem setToolTip:[item toolTip]];
	[newItem setTarget:[item target]];
	[newItem setAction:[item action]];
	[newItem setMenuFormRepresentation:[item menuFormRepresentation]];
	//KNDebug(@"Added item: %@ with target: %@ action: %@", itemIdentifier, [item target], NSStringFromSelector([item action]));
	return newItem;
}

-(NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar{
#pragma unused(toolbar)
	return [NSArray arrayWithObjects: 
                ADD_FEED,
                REMOVE_FEED,
                TOGGLE_DRAWER,
                NSToolbarFlexibleSpaceItemIdentifier,
				MARK_ALL_READ,
                UPDATE_ALL,
            nil];
}

-(NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar{
#pragma unused(toolbar)
	return [NSArray arrayWithObjects: 
                ADD_FEED,
                REMOVE_FEED,
                TOGGLE_DRAWER,
                NSToolbarFlexibleSpaceItemIdentifier,
				MARK_ALL_READ,
                UPDATE_ALL,
            nil];
}

@end
