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
- (id)initWithWindowNibName:(NSString *)nibName forUpdateToVersion:(NSString *)updateVersion;
- (void) performInstallGrowl;
- (void) releaseAndClose;
@end

@implementation GrowlInstallationPrompt

static BOOL checkOSXVersion()
{
	long OSXVersion = 0L;
	OSStatus err = Gestalt(gestaltSystemVersion, &OSXVersion);
	if (err != noErr) {
		NSLog(@"WARNING in GrowlInstallationPrompt: could not get Mac OS X version (selector = %x); got error code %li (will show the installation prompt anyway)", (unsigned)gestaltSystemVersion, (long)err);
		//we proceed anyway, on the theory that it is better to show the installation prompt when inappropriate than to suppress it when not.
		OSXVersion = minimumOSXVersionForGrowl;
	}
	
	return (OSXVersion >= minimumOSXVersionForGrowl);
}

+ (void) showInstallationPrompt {
	if (checkOSXVersion()) {
		[[[[GrowlInstallationPrompt alloc] initWithWindowNibName:GROWL_INSTALLATION_NIB forUpdateToVersion:nil] window] makeKeyAndOrderFront:nil];
	}
}

+ (void) showUpdatePromptForVersion:(NSString *)inUpdateVersion {
	if (checkOSXVersion()) {
		[[[[GrowlInstallationPrompt alloc] initWithWindowNibName:GROWL_INSTALLATION_NIB forUpdateToVersion:inUpdateVersion] window] makeKeyAndOrderFront:nil];
	}
}

- (id)initWithWindowNibName:(NSString *)nibName forUpdateToVersion:(NSString *)inUpdateVersion {
	if ((self = [super initWithWindowNibName:nibName])) {
		updateVersion = [inUpdateVersion retain];
	}

	return self;
}

- (void) dealloc {
	[updateVersion release];

	[super dealloc];
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
	if (updateVersion ? 
		[growlDelegate respondsToSelector:@selector(growlUpdateWindowTitle)] :
		[growlDelegate respondsToSelector:@selector(growlInstallationWindowTitle)]) {
		
		windowTitle = (updateVersion ? [growlDelegate growlUpdateWindowTitle] : [growlDelegate growlInstallationWindowTitle]);
	} else {
		windowTitle = (updateVersion ? DEFAULT_UPDATE_WINDOW_TITLE : DEFAULT_INSTALLATION_WINDOW_TITLE);
	}
	
	[theWindow setTitle:windowTitle];
	
	//Growl information
	if (updateVersion ? 
		[growlDelegate respondsToSelector:@selector(growlUpdateInformation)] :
		[growlDelegate respondsToSelector:@selector(growlInstallationInformation)]) {
		growlInfo = (updateVersion ? [growlDelegate growlUpdateInformation] : [growlDelegate growlInstallationInformation]);

	} else {
		NSMutableAttributedString	*defaultGrowlInfo;
		
		//Start with the window title, centered and bold
		NSMutableParagraphStyle	*centeredStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[centeredStyle setAlignment:NSCenterTextAlignment];

		NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
			centeredStyle,                                 NSParagraphStyleAttributeName,
			[NSFont boldSystemFontOfSize:GROWL_TEXT_SIZE], NSFontAttributeName,
			nil];
		[centeredStyle release];
		defaultGrowlInfo = [[NSMutableAttributedString alloc] initWithString:windowTitle
																  attributes:attributes];
		//Skip a line
		[[defaultGrowlInfo mutableString] appendString:@"\n\n"];

		//Now provide a default explanation
		NSAttributedString *defaultExplanation;
		defaultExplanation = [[NSAttributedString alloc] initWithString:(updateVersion ? 
																		  DEFAULT_UPDATE_EXPLANATION : 
																		  DEFAULT_INSTALLATION_EXPLANATION)
															  attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																  [NSFont systemFontOfSize:GROWL_TEXT_SIZE], NSFontAttributeName,
																  nil]];

		[defaultGrowlInfo appendAttributedString:defaultExplanation];
		[defaultExplanation release];
		
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
	[button_install setTitle:(updateVersion ? UPDATE_BUTTON_TITLE : INSTALL_BUTTON_TITLE)];
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
	if (!updateVersion){
		//Tell the app bridge about the user's choice
		[GrowlApplicationBridge _userChoseNotToInstallGrowl];
	}
	
	//Shut down the installation prompt
	[self releaseAndClose];
}

- (IBAction) dontAskAgain:(id)sender
{
	BOOL dontAskAgain = ([sender state] == NSOnState);
	
	if (updateVersion){
		if (dontAskAgain) {
			/* We want to be able to prompt again for the next version, so we track the version for which the user requested
			 * not to be prompted again. */
			[[NSUserDefaults standardUserDefaults] setObject:updateVersion
													  forKey:@"Growl Update:Do Not Prompt Again:Last Version"];
		} else {
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Growl Update:Do Not Prompt Again:Last Version"];			
		}

	}else{
		//Store the user's preference to the user defaults dictionary
		[[NSUserDefaults standardUserDefaults] setBool:dontAskAgain
												forKey:@"Growl Installation:Do Not Prompt Again"];
	}
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
	BOOL success = NO;

	bundle = [NSBundle bundleForClass:[GrowlInstallationPrompt class]];
	archivePath = [bundle pathForResource:GROWL_PREFPANE_NAME ofType:@"zip"];

	//desired folder: /private/tmp/$UID/GrowlInstallations/`uuidgen`

	tmpDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"GrowlInstallations"];
	if (tmpDir) {
		[[NSFileManager defaultManager] createDirectoryAtPath:tmpDir attributes:nil];
		
		tmpDir = [tmpDir stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
		if (tmpDir) {
			[[NSFileManager defaultManager] createDirectoryAtPath:tmpDir attributes:nil];

			NSArray *arguments = [[NSArray alloc] initWithObjects:
				@"-o",  /* overwrite */
				@"-q", /* quiet! */
				archivePath, /* source zip file */
				@"-d", tmpDir, /* The temporary folder is the destination folder*/
				nil];
			unzip = [[NSTask alloc] init];
			[unzip setLaunchPath:@"/usr/bin/unzip"];
			[unzip setArguments:arguments];
			[unzip setCurrentDirectoryPath:tmpDir];
			
			NS_DURING
				[unzip launch];
				[unzip waitUntilExit];
				success = ([unzip terminationStatus] == 0);
			NS_HANDLER
				/* No exception handler needed */
			NS_ENDHANDLER
			[unzip release];
			[arguments release];
				
			if (success) {
				NSString	*tempGrowlPrefPane;
				
				// Kill the running Growl helper app if necessary by asking the Growl Helper App to shutdown via the DNC
				[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_SHUTDOWN object:nil];
				
				/* Open Growl.prefPane using System Preferences, which will take care of the rest.
				 * Growl.prefPane will relaunch the GHA if appropriate. */
				tempGrowlPrefPane = [tmpDir stringByAppendingPathComponent:GROWL_PREFPANE_NAME];
				success = [[NSWorkspace sharedWorkspace] openFile:tempGrowlPrefPane
												  withApplication:@"System Preferences"
													andDeactivate:YES];
				if (!success){
					/* If the System Preferences app could not be found for whatever reason, try opening
					 * Growl.prefPane with openTempFile so the associated app will launch. This could be the case
					 * if "System Preferences.app" were renamed or if an alternative program were being used. */
					success = [[NSWorkspace sharedWorkspace] openTempFile:tempGrowlPrefPane];
				}
			}
		}
	}

	if (!success) {
		//XXX show this to the user; don't just log it.
		NSLog(@"GrowlInstallationPrompt: Growl was not successfully installed");
	}
}

- (void)releaseAndClose
{
	[self autorelease];
	[[self window] close];	
}

@end
