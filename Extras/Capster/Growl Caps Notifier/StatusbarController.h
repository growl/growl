//
//  StatusbarController.h
//  Capster
//
//  Created by Vasileios Georgitzikis on 9/3/11.
//  Copyright 2011 Tzikis. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface StatusbarController : NSObject
{
@private
	//the menu shown when the menu icon is pressed
    IBOutlet NSMenu *statusMenu;
	//the status item is actually the 'menu icon'
    NSStatusItem * statusItem;
	//the mini images used as an icon for the status item
	NSImage* mini_on;    
	NSImage* mini_off;    

	NSImage* mini_green;
	NSImage* mini_red;
	
	NSImage* led_green;
	NSImage* led_red;
	

	NSUInteger* currentState;

	//the user's preferences, loaded at startup
	NSUserDefaults *preferences;
	//The following are outlets in the preferences panel.
	//the outlets are needed to change their text color to white
	IBOutlet NSMatrix *statusbarMatrix;
	NSUInteger *statusbar;
}

- (void) setIconState: (BOOL) state;

- (id) initWithStatusbar: (NSUInteger*) bar
		 statusbarMatrix:(NSMatrix*) matrix
			 preferences: (NSUserDefaults*) prefs
				   state: (NSUInteger*) curState
			  statusMenu: (NSMenu*) menu;
- (IBAction) setStatusMenuTo:(id) sender;
- (IBAction)enableStatusMenu:(id)sender;
- (IBAction)disableStatusMenu:(id)sender;
- (void) initStatusMenu:(NSImage*) menuIcon;

@property(nonatomic, retain) NSStatusItem* statusItem;

@end
