//
//  GrowlInstallationPrompt.m
//  Growl
//
//  Created by Evan Schoenberg on 1/8/05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "GrowlInstallationPrompt.h"
#import "GrowlApplicationBridge.h"
#import "GrowlDefines.h"

#define GROWL_INSTALLATION_NIB @"GrowlInstallationPrompt"
#define GROWL_INSTALLATION_STRINGS @"GrowlInstallation.strings"

#define DEFAULT_INSTALLATION_WINDOW_TITLE NSLocalizedStringFromTable(@"Growl Installation Recommended", GROWL_INSTALLATION_STRINGS, @"Growl installation window title")
#define DEFAULT_UPDATE_WINDOW_TITLE NSLocalizedStringFromTable(@"Growl Update Available", GROWL_INSTALLATION_STRINGS, @"Growl update window title")

#define DEFAULT_INSTALLATION_EXPLANATION NSLocalizedStringFromTable(@"This program displays information via Growl, a centralized notification system.  Growl is not currently installed; to see Growl notifications from this and other applications, you must install it.  No download is required.", GROWL_INSTALLATION_STRINGS, @"Default Growl installation explanation")
#define DEFAULT_UPDATE_EXPLANATION NSLocalizedStringFromTable(@"This program displays information via Growl, a centralized notification system.  A version of Growl is currently installed, but this program includes an updated version of Growl.  It is strongly recommended that you update now.  No download is required.", GROWL_INSTALLATION_STRINGS, @"Default Growl update explanation")

#define INSTALL_BUTTON_TITLE NSLocalizedStringFromTable(@"Install", GROWL_INSTALLATION_STRINGS, @"Button title for installing Growl")
#define UPDATE_BUTTON_TITLE NSLocalizedStringFromTable(@"Update", GROWL_INSTALLATION_STRINGS, @"Button title for updating Growl")
#define CANCEL_BUTTON_TITLE NSLocalizedStringFromTable(@"Cancel", GROWL_INSTALLATION_STRINGS, @"Button title for canceling installation of Growl")
#define DONT_ASK_AGAIN_CHECKBOX_TITLE NSLocalizedStringFromTable(@"Don't Ask Again", GROWL_INSTALLATION_STRINGS, @"Don't ask again checkbox title for installation of Growl")

#define GROWL_TEXT_SIZE 11

static const long minimumOSXVersionForGrowl = 0x1030L;

@interface GrowlInstallationPrompt (private)
- (id) initWithWindowNibName:(NSString *)nibName forUpdate:(BOOL)inIsUpdate;
- (void) performInstallGrowl;
- (void) releaseAndClose;
@end

@implementation GrowlInstallationPrompt

+ (void) showInstallationPromptForUpdate:(BOOL)inIsUpdate
{
	long OSXVersion = 0L;
	OSStatus err = Gestalt(gestaltSystemVersion, &OSXVersion);
	if(err != noErr) {
		NSLog(@"WARNING in GrowlInstallationPrompt: could not get Mac OS X version (selector = %x); got error code %li (will show the installation prompt anyway)", (unsigned)gestaltSystemVersion, (long)err);
		//we proceed anyway, on the theory that it is better to show the installation prompt when inappropriate than to suppress it when not.
		OSXVersion = minimumOSXVersionForGrowl;
	}

	if(OSXVersion >= minimumOSXVersionForGrowl)
		[[[[self alloc] initWithWindowNibName:GROWL_INSTALLATION_NIB forUpdate:inIsUpdate] window] makeKeyAndOrderFront:nil];
}

- (id)initWithWindowNibName:(NSString *)nibName forUpdate:(BOOL)inIsUpdate
{
	if((self = [super initWithWindowNibName:nibName]))
		isUpdate = inIsUpdate;

	return self;
}

// closes this window
- (IBAction)closeWindow:(id)sender
{
	if ([self windowShouldClose:nil]){
		[[self window] close];
	}
}

// called after the about window loads, so we can set up the window before it's displayed
- (void)windowDidLoad
{
	NSObject<GrowlApplicationBridgeDelegate> *growlDelegate = [GrowlApplicationBridge growlDelegate];
	NSString *windowTitle;
	NSAttributedString *growlInfo;
	NSWindow *theWindow = [self window];

	//Setup the textviews
	[textView_growlInfo setHorizontallyResizable:NO];
	[textView_growlInfo setVerticallyResizable:YES];
	[textView_growlInfo setDrawsBackground:NO];
	[scrollView_growlInfo setDrawsBackground:NO];
	
	//Window title
	if (isUpdate ? 
		[growlDelegate respondsToSelector:@selector(growlUpdateWindowTitle)] :
		[growlDelegate respondsToSelector:@selector(growlInstallationWindowTitle)]) {
		
		windowTitle = (isUpdate ? [growlDelegate growlUpdateWindowTitle] : [growlDelegate growlInstallationWindowTitle]);
	} else {
		windowTitle = (isUpdate ? DEFAULT_UPDATE_WINDOW_TITLE : DEFAULT_INSTALLATION_WINDOW_TITLE);
	}
	
	[theWindow setTitle:windowTitle];
	
	//Growl information
	if (isUpdate ? 
		[growlDelegate respondsToSelector:@selector(growlUpdateInformation)] :
		[growlDelegate respondsToSelector:@selector(growlInstallationInformation)]) {
		growlInfo = (isUpdate ? [growlDelegate growlUpdateInformation] : [growlDelegate growlInstallationInformation]);

	} else {
		NSMutableAttributedString	*defaultGrowlInfo;
		
		//Start with the window title, centered and bold
		NSMutableParagraphStyle	*centeredStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
		[centeredStyle setAlignment:NSCenterTextAlignment];

		defaultGrowlInfo = [[NSMutableAttributedString alloc] initWithString:windowTitle
																  attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																	  centeredStyle,NSParagraphStyleAttributeName,
																	  [NSFont boldSystemFontOfSize:GROWL_TEXT_SIZE], NSFontAttributeName,
																	  nil]];
		//Skip a line
		[[defaultGrowlInfo mutableString] appendString:@"\n\n"];
		
		//Now provide a default explanation
		NSAttributedString *defaultExplanation;
		defaultExplanation = [[[NSAttributedString alloc] initWithString:(isUpdate ? DEFAULT_UPDATE_EXPLANATION : DEFAULT_INSTALLATION_EXPLANATION)
															  attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																  [NSFont systemFontOfSize:GROWL_TEXT_SIZE], NSFontAttributeName,
																  nil]] autorelease];
			
		[defaultGrowlInfo appendAttributedString:defaultExplanation];
		
		growlInfo = defaultGrowlInfo;
	}

	[[textView_growlInfo textStorage] setAttributedString:growlInfo];
	NSRect	frame = [theWindow frame];
	int		heightChange;

	//Resize the window frame to fit the description
	[textView_growlInfo sizeToFit];
	heightChange = [textView_growlInfo frame].size.height - [scrollView_growlInfo documentVisibleRect].size.height;
	frame.size.height += heightChange;
	frame.origin.y -= heightChange;
	[theWindow setFrame:frame display:YES];
	
	//Localize and size the buttons
	
	//The install button should maintain its distance from the right side of the window
	NSRect	newInstallButtonFrame, oldInstallButtonFrame;
	int installButtonOriginLeftShift;
	oldInstallButtonFrame = [button_install frame];
	[button_install setTitle:(isUpdate ? UPDATE_BUTTON_TITLE : INSTALL_BUTTON_TITLE)];
	[button_install sizeToFit];
	newInstallButtonFrame = [button_install frame];
	//Don't shrink to a size less than the original size
	if (newInstallButtonFrame.size.width < oldInstallButtonFrame.size.width) {
		newInstallButtonFrame.size.width = oldInstallButtonFrame.size.width;
	}
	//Adjust the origin to put the right edge at the proper place
	newInstallButtonFrame.origin.x = (oldInstallButtonFrame.origin.x + oldInstallButtonFrame.size.width) - newInstallButtonFrame.size.width;
	installButtonOriginLeftShift = oldInstallButtonFrame.origin.x - newInstallButtonFrame.origin.x;
	[button_install setFrame:newInstallButtonFrame];

	NSRect newCancelButtonFrame, oldCancelButtonFrame;
	oldCancelButtonFrame = [button_cancel frame];
	[button_cancel setTitle:CANCEL_BUTTON_TITLE];
	[button_cancel sizeToFit];
	newCancelButtonFrame = [button_cancel frame];
	//Don't shrink to a size less than the original size
	if (newCancelButtonFrame.size.width < oldCancelButtonFrame.size.width) {
		newCancelButtonFrame.size.width = oldCancelButtonFrame.size.width;
	}
	//Adjust the origin to put the right edge at the proper place (same distance from the left edge of the install button as before)
	newCancelButtonFrame.origin.x = ((oldCancelButtonFrame.origin.x + oldCancelButtonFrame.size.width) - newCancelButtonFrame.size.width) - installButtonOriginLeftShift;
	[button_cancel setFrame:newCancelButtonFrame];
	
	[checkBox_dontAskAgain setTitle:DONT_ASK_AGAIN_CHECKBOX_TITLE];
	[checkBox_dontAskAgain sizeToFit];
}

- (IBAction) installGrowl:(id)sender
{
	[self performInstallGrowl];

	[self releaseAndClose];
}

- (IBAction) cancel:(id)sender
{	
	if (!isUpdate){
		//Tell the app bridge about the user's choice
		[GrowlApplicationBridge _userChoseNotToInstallGrowl];
	}
	
	//Shut down the installation prompt
	[self releaseAndClose];
}

- (IBAction) dontAskAgain:(id)sender
{
	//Store the user's preference to the user defaults dictionary
	[[NSUserDefaults standardUserDefaults] setBool:([sender state] == NSOnState)
											forKey:(isUpdate ?
													@"Growl Update: Do Not Prompt Again" :
													@"Growl Installation: Do Not Prompt Again")];
}

// called as the window closes
- (BOOL) windowShouldClose:(id)sender
{
	//If the window closes via the close button or cmd-W, it should be treated as clicking Cancel.
	[self cancel:nil];

	return YES;
}

- (void) performInstallGrowl
{
	// Obtain the path to the archived Growl.prefPane
	NSBundle *bundle;
	NSString *archivePath, *tmpDir;
	NSTask	*unzip;
	
	bundle = [NSBundle bundleForClass:[self class]];
	archivePath = [bundle pathForResource:GROWL_PREFPANE_NAME ofType:@"zip"];
	
	if ( (tmpDir = NSTemporaryDirectory()) ){
		unzip = [[NSTask alloc] init];
		[unzip setLaunchPath:@"/usr/bin/unzip"];
		[unzip setArguments:[NSArray arrayWithObjects:
			@"-o",  /* overwrite */
			@"-q", /* quiet! */
			archivePath, /* source zip file */
			@"-d", tmpDir, /* The temporary folder is the destination folder*/
			nil]];
		
		[unzip setCurrentDirectoryPath:tmpDir];
		
		[unzip launch];
		[unzip waitUntilExit];
		[unzip release];
		
		// Kill the running Growl helper app if necessary by asking the Growl Helper App to shutdown via the DNC
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_SHUTDOWN object:nil];

		// Open Growl.prefPane; System Preferences will take care of the rest, and Growl.prefPane will relaunch the GHA if appropriate.
		[[NSWorkspace sharedWorkspace] openTempFile:[tmpDir stringByAppendingPathComponent:GROWL_PREFPANE_NAME]];
	}
}

- (void) releaseAndClose
{
	[self autorelease];
	[[self window] close];	
}

@end
