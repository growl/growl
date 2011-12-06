//
//  StatusbarController.m
//  Capster
//
//  Created by Vasileios Georgitzikis on 9/3/11.
//  Copyright 2011 Tzikis. All rights reserved.
//

#import "StatusbarController.h"


@implementation StatusbarController
@synthesize statusItem;

- (id) initWithStatusbar: (NSUInteger*) bar
			 preferences: (NSUserDefaults*) prefs
				   state:(NSUInteger *)curState
			  statusMenu: (NSMenu*) menu
{
	self = [super init];
    if (self)
	{
        // Initialization code here.
		statusbar = bar;
		preferences = prefs;
		currentState = curState;
		statusMenu = menu;
		
		//initialize the mini icon image
		NSString* path_mini_on = [[NSBundle mainBundle] pathForResource:@"capster_mini" ofType:@"png"];
		mini_on = [[NSImage alloc] initWithContentsOfFile:path_mini_on];
		
		NSString* path_mini_off = [[NSBundle mainBundle] pathForResource:@"capster_mini_off" ofType:@"png"];
		mini_off = [[NSImage alloc] initWithContentsOfFile:path_mini_off];

		
		NSString* path_mini_green = [[NSBundle mainBundle] pathForResource:@"capster_mini_green" ofType:@"png"];
		mini_green = [[NSImage alloc] initWithContentsOfFile:path_mini_green];
		
		NSString* path_mini_red = [[NSBundle mainBundle] pathForResource:@"capster_mini_red" ofType:@"png"];
		mini_red = [[NSImage alloc] initWithContentsOfFile:path_mini_red];
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void) setIconState: (BOOL) state
{
//	NSLog(@"state %i and statusbar %i", state, *statusbar);
	if(*statusbar == 1)
	{
		if(state) [statusItem setImage:mini_on];
		else [statusItem setImage:mini_off];
	}
	else if(*statusbar == 2)
	{
		if(state) [statusItem setImage:mini_green];
		else [statusItem setImage:mini_red];
	}
}

//set the status menu to the value of the checkbox sender
-(IBAction) setStatusMenu
{
	//merely a casting
	NSUInteger status = 0;
	//	static NSUInteger oldStatus = 0;
	
//	NSLog(@"selected row %i, old status %i", status, *statusbar);
	//update our status bar if needed
//	[preferences setInteger:status forKey:@"statusMenu"];
//	[preferences synchronize];
	
	status = [preferences integerForKey:@"statusMenu"];

	if ((*statusbar == 0 &&  status !=0) || (*statusbar != 0 && status ==0))
	{
		//NULL
		//if we are adding a statusmenu, then run initStatusMenu
		//otherwise run disableStatusMenu
		if(status > 0)
		{
			[self initStatusMenu: mini_on];
		}
		else
		{
			[self disableStatusMenu:nil];
		}

	}
	
	//make sure we need to add or remove a menu
	if(*statusbar != status)
	{
		*statusbar = status;
		[self setIconState:*currentState];
	}
	else return;

}
//- (IBAction) statusMenuChanged
//{
////	NSLog(@"Row %d",[statusbarMatrix selectedRow]);
////	NSLog(@"Column %d",[statusbarMatrix selectedColumn]);
//
//	NSUInteger status = [statusbarMatrix selectedRow];	
//	if(status == 0)
//	{
//		[NSApp activateIgnoringOtherApps:YES];
//		NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Warning! Enabling this option will cause Capster to run in the background", nil)
//										 defaultButton:NSLocalizedString(@"Ok", nil)
//									   alternateButton:NSLocalizedString(@"Cancel", nil)
//										   otherButton:nil
//							 informativeTextWithFormat:NSLocalizedString(@"Enabling this option will cause Capster to run without showing a dock icon or a menu item.\n\nTo access preferences, tap Capster in Launchpad, or open Capster in Finder.", nil)];
//		
//		NSInteger allow = [alert runModal];
//		if(allow == NSAlertDefaultReturn)
//			return;
//	}
//
//}

-(IBAction) enableStatusMenu:(id)sender
{
	//not used
}
//update the user's preferences, and remove the item from the status bar
-(IBAction) disableStatusMenu: (id)sender
{
	[[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
}

//update the user's preferences, create a status bar item, and add it to the
//status bar
-(void) initStatusMenu: (NSImage*) menuIcon
{
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain]; 
	[statusItem setMenu:statusMenu];
	[statusItem setImage:mini_on];
	[statusItem setHighlightMode:YES];
}

@end
