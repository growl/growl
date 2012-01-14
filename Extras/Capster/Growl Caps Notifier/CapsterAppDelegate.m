//
//  CapsterAppDelegate.m
//  Capster
//
//  Created by Vasileios Georgitzikis on 3/3/11.
//  Copyright 2011 Tzikis. All rights reserved.
//
// This source code is release under the BSD License.

#import "CapsterAppDelegate.h"
#import "CommonTitles.h"

@implementation Growl_Caps_NotifierAppDelegate

@synthesize onLoginSegmentedControl;
@synthesize preferencePanel;

@synthesize iconOptions;
@synthesize iconPopUp;

@synthesize prefsTitle, onLoginTitle, quitTitle;
@synthesize noneTitle, blackIcons, colorIcons, preferenceTitle, labelTitle, closeTitle;
@synthesize capsTitle, numlockTitle, fnTitle, soundTitle;

@synthesize capsFlag, shiftFlag, numlockFlag, fnFlag;


//this function is called on startup
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	//register the user's preferences
	[self registerDefaults];
		
	//initializing modifier key flags
	[self initFlags];
	//adding an event handler for flag key changes
	[self listen];

	statusbar = malloc(sizeof(NSInteger*));	
	*statusbar = [preferences integerForKey:@"statusMenu"];
	oldIconValue = *statusbar;
		
	//needed, because statusbar is supposed to always store the current value
	//and we check wether it's changed when updating the status bar.
	//since, at the beginning, we have 0, we save it. in the next line, we will
	//get the correct value from the statusbarMatrix, which we've just saved
	*statusbar = 0;

	myGrowlController = [[GrowlController alloc] init];
	myStatusbarController = [[StatusbarController alloc] initWithStatusbar:statusbar 
															   preferences:preferences
																	 state:currentState
																statusMenu:statusMenu];

	//Initialize localized strings
	[self initTitles];
	self.iconOptions = [NSArray arrayWithObjects:noneTitle, blackIcons, colorIcons, nil];

	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.OnLogin" options:NSKeyValueObservingOptionNew context:&self];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.statusMenu" options:NSKeyValueObservingOptionNew context:&self];
	
    oldOnLoginValue = [[[NSUserDefaultsController sharedUserDefaultsController] defaults] integerForKey:@"OnLogin"];

	//if the user want the menu to be shown, then do so
	[myStatusbarController setStatusMenu];
	
	//send a notification to the user to let him know we're on (disabled)
	//	[myGrowlController sendStartupGrowlNotification];
}

//starts the listener and blocks the current thread, waiting for events
-(void) listen
{
		
	NSEvent* (^myHandler)(NSEvent*) = ^(NSEvent* event)
	{
//		NSLog(@"flags changed");
#define CHECK_FLAG(NAME)	if(self.NAME ## Flag != NAME)\
								[self flagChanged: @"" #NAME toValue: NAME];\
							self.NAME ## Flag = NAME;
		
		NSUInteger flags = [event modifierFlags];
		int caps = flags & NSAlphaShiftKeyMask ? 1 : 0;
		int shift = flags & NSShiftKeyMask ? 1 : 0;
		int fn = flags & NSFunctionKeyMask ? 1 : 0;
		int numlock = flags & NSNumericPadKeyMask ? 1 : 0;
		
		CHECK_FLAG(caps);
		CHECK_FLAG(shift);
		CHECK_FLAG(fn);
		CHECK_FLAG(numlock);
		
		return event;
	};
	
	[NSEvent addLocalMonitorForEventsMatchingMask:NSFlagsChangedMask 
										  handler:myHandler];
	[NSEvent addGlobalMonitorForEventsMatchingMask:NSFlagsChangedMask 
										   handler: ^(NSEvent* event)
	{
		myHandler(event);
	}];

}

//initializes the user preferences, and loads the defaults from the defaults file
-(void) registerDefaults
{
	//Save a reference to the user's preferences
	preferences = [[NSUserDefaults standardUserDefaults] retain];
	//get the default preferences file
	NSString *file = [[NSBundle mainBundle]
					  pathForResource:@"defaults" ofType:@"plist"];
	//make a dictionary of that file
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:file];
	//register the defaults
	[preferences registerDefaults:dict];
}

-(void) initTitles
{
	self.prefsTitle = PrefsTitle;
	self.onLoginTitle = OnLoginTitle;
	self.quitTitle = QuitTitle;
	self.noneTitle = NoneTitle; 
	self.blackIcons = BlackIcons;
	self.colorIcons = ColorIcons;
	self.preferenceTitle = PreferenceTitle;
	self.labelTitle = LabelTitle;
	self.closeTitle = CloseTitle;
	self.capsTitle = CapsTitle;
	self.numlockTitle = NumlockTitle;
	self.fnTitle = FnTitle;
	self.soundTitle = SoundTitle;
}

-(void) initFlags
{
	NSUInteger flags = [NSEvent modifierFlags];
	numlockFlag = flags & NSNumericPadKeyMask ? 1 : 0;
	capsFlag = flags & NSAlphaShiftKeyMask ? 1 : 0;
	shiftFlag = flags & NSShiftKeyMask ? 1 : 0;
	fnFlag = flags & NSFunctionKeyMask ? 1 : 0;
}

//Set the button's title using nsattributedtitle, which lets us change the color of a button or cell's text
- (void)setButtonTitleFor:(id)button toString:(NSString*)title withColor:(NSColor*)color 
{
	if([button respondsToSelector:@selector(setAttributedTitle:)] == NO) return;
			
	NSMutableDictionary *attrsDictionary = [NSMutableDictionary dictionaryWithDictionary:
											   [[button attributedTitle] attributesAtIndex:0 effectiveRange:NULL]];
	[attrsDictionary setObject:color forKey:NSForegroundColorAttributeName];
	
	NSAttributedString* attrString = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
	NSLog(@"%@", attrsDictionary);
	
	[button setAttributedTitle: attrString];
	[attrString release];		
}

- (void) fetchedCapsState
{
//	if( *currentState == 0)
//	{
//		NSLog(@"caps is off");
//	}
//	else
//	{
//		NSLog(@"caps is on");		
//	}
	
	[myStatusbarController setIconState:(BOOL) *currentState];
}

- (void) flagChanged: (NSString*) flag toValue: (NSUInteger) value
{
#define NOTIFY(NAME)\
	if([flag isEqualToString:@"" #NAME] && [preferences boolForKey:@"" #NAME "Notifications"])\
	{\
		[myGrowlController sendNotification:value forFlag:flag];\
		if([preferences boolForKey:@"playSound"])\
			[[NSSound soundNamed:@"Glass"] play];\
	}
	NOTIFY(caps);
	NOTIFY(numlock);
	NOTIFY(fn);
	

	if([flag isEqualToString:@"caps"])
		[myStatusbarController setIconState:value];
	
}

//set the status menu to the value of the checkbox sender
//-(IBAction) statusMenuChanged: (id) sender
//{
//	[myStatusbarController statusMenuChanged];
//}

- (BOOL) applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
	#pragma unused(theApplication, flag)
    [self showPreferences:nil];
    return YES;
}

-(IBAction) showPreferences:(id) sender
{
	[NSApp activateIgnoringOtherApps:YES];
	if(![preferencePanel isVisible]){
		[preferencePanel center];
//		[self.prefsWindow setFrameAutosaveName:@"HWGrowlerPrefsWindowFrame"];
//		[self.prefsWindow setFrameUsingName:@"HWGrowlerPrefsWindowFrame" force:YES];
	}
	[preferencePanel makeKeyAndOrderFront:sender];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
#pragma unused(object, change, context)
    if ([keyPath isEqualToString:@"values.OnLogin"])
    {
        NSInteger index = [[[NSUserDefaultsController sharedUserDefaultsController] defaults] integerForKey:@"OnLogin"];
        if((index == 0) && (oldOnLoginValue != index))
        {
            [NSApp activateIgnoringOtherApps:YES];
            NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Alert! Enabling this option will add Capster to your login items", nil)
                                             defaultButton:NSLocalizedString(@"Ok", nil)
                                           alternateButton:NSLocalizedString(@"Cancel", nil)
                                               otherButton:nil
                                 informativeTextWithFormat:NSLocalizedString(@"Allowing this will let Capster launch everytime you login, so that it is available at all times", nil)];
            NSInteger allow = [alert runModal];
            if(allow == NSAlertDefaultReturn)
            {
                [self setStartAtLogin:[[NSBundle mainBundle] bundlePath] enabled:YES];
            }
            else
            {
                [self setStartAtLogin:[[NSBundle mainBundle] bundlePath] enabled:NO];
                [[[NSUserDefaultsController sharedUserDefaultsController] defaults] setInteger:oldOnLoginValue forKey:@"OnLogin"];
                [[[NSUserDefaultsController sharedUserDefaultsController] defaults] synchronize];
                [onLoginSegmentedControl setSelectedSegment:oldOnLoginValue];
            }
        }
        else
            [self setStartAtLogin:[[NSBundle mainBundle] bundlePath] enabled:NO];
		
        oldOnLoginValue = index;
    }
	else if([keyPath isEqualToString:@"values.statusMenu"])
	{
		NSInteger newIconValue = [preferences integerForKey:@"statusMenu"];
		if(newIconValue == 0)
		{
			[NSApp activateIgnoringOtherApps:YES];
			NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Warning! Enabling this option will cause Capster to run in the background", nil)
											 defaultButton:NSLocalizedString(@"Ok", nil)
										   alternateButton:NSLocalizedString(@"Cancel", nil)
											   otherButton:nil
								 informativeTextWithFormat:NSLocalizedString(@"Enabling this option will cause Capster to run without showing a dock icon or a menu item.\n\nTo access preferences, tap Capster in Launchpad, or open Capster in Finder.", nil)];
			
			NSInteger allow = [alert runModal];
			if(allow == !NSAlertDefaultReturn)
			{
				[preferences setInteger:oldIconValue forKey:@"statusMenu"];
				[preferences synchronize];
				[iconPopUp selectItemAtIndex:oldIconValue];
				newIconValue = oldIconValue;
			}
		}
		oldIconValue = newIconValue;
		[myStatusbarController setStatusMenu];			
	}
}

- (void) setStartAtLogin:(NSString *)path enabled:(BOOL)enabled {
	OSStatus status;
	CFURLRef URLToToggle = (CFURLRef)[NSURL fileURLWithPath:path];
	LSSharedFileListItemRef existingItem = NULL;
    LSSharedFileListRef loginItems = LSSharedFileListCreate(kCFAllocatorDefault, kLSSharedFileListSessionLoginItems, /*options*/ NULL);
    if(loginItems)
    {
		UInt32 seed = 0U;
		NSArray *currentLoginItems = [NSMakeCollectable(LSSharedFileListCopySnapshot(loginItems, &seed)) autorelease];
		for (id itemObject in currentLoginItems) {
			LSSharedFileListItemRef item = (LSSharedFileListItemRef)itemObject;
			
			UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
			CFURLRef URL = NULL;
			OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, /*outRef*/ NULL);
			if (err == noErr) {
				Boolean foundIt = CFEqual(URL, URLToToggle);
				CFRelease(URL);
				
				if (foundIt) {
					existingItem = item;
					break;
				}
			}
		}
		
		if (enabled && (existingItem == NULL)) {
			NSString *displayName = [[NSFileManager defaultManager] displayNameAtPath:path];
			IconRef icon = NULL;
			FSRef ref;
			Boolean gotRef = CFURLGetFSRef(URLToToggle, &ref);
			if (gotRef) {
				status = GetIconRefFromFileInfo(&ref,
												/*fileNameLength*/ 0, /*fileName*/ NULL,
												kFSCatInfoNone, /*catalogInfo*/ NULL,
												kIconServicesNormalUsageFlag,
												&icon,
												/*outLabel*/ NULL);
				if (status != noErr)
					icon = NULL;
			}
			
			LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemBeforeFirst, (CFStringRef)displayName, icon, URLToToggle, /*propertiesToSet*/ NULL, /*propertiesToClear*/ NULL);
		} else if (!enabled && (existingItem != NULL))
			LSSharedFileListItemRemove(loginItems, existingItem);
		
		CFRelease(loginItems);
    }
}

@end
