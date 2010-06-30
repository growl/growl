//
//  GrowlInstallationPrompt.m
//  Growl
//
//  Created by Evan Schoenberg on 1/8/05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlInstallationPrompt.h"
#import "GrowlApplicationBridge.h"
#import "GrowlPathUtilities.h"
#import "GrowlDefines.h"
#import "GrowlDefinesInternal.h"
#import "GrowlVersionCheck.h"

#import "AEVTBuilder.h"
#import	"NSFileManager+Authentication.h"

#define GROWL_INSTALLATION_NIB     @"GrowlInstallationPrompt"

#define DEFAULT_INSTALLATION_WINDOW_TITLE NSLocalizedStringFromTableInBundle(@"Growl Installation Recommended", @"GrowlInstallation", [NSBundle bundleForClass:[self class]], @"Growl installation window title")
#define DEFAULT_UPDATE_WINDOW_TITLE       NSLocalizedStringFromTableInBundle(@"Growl Update Available", @"GrowlInstallation", [NSBundle bundleForClass:[self class]], @"Growl update window title")

#define DEFAULT_INSTALLATION_EXPLANATION NSLocalizedStringFromTableInBundle(@"This program displays information via Growl, a centralized notification system that enables applications to unobtrusively inform the user about potentially important information.  Growl is not currently installed; to see Growl notifications from this and other applications, you must install it.  No download is required.", @"GrowlInstallation", [NSBundle bundleForClass:[self class]], @"Default Growl installation explanation")
#define DEFAULT_UPDATE_EXPLANATION       NSLocalizedStringFromTableInBundle(@"This program displays information via Growl, a centralized notification system that enables applications to unobtrusively inform the user about potentially important information.  A version of Growl is currently installed, but this program includes an updated version of Growl.  It is strongly recommended that you update now.  No download is required.", @"GrowlInstallation", [NSBundle bundleForClass:[self class]], @"Default Growl update explanation")

#define INSTALL_BUTTON_TITLE			NSLocalizedStringFromTableInBundle(@"Install", @"GrowlInstallation", [NSBundle bundleForClass:[self class]], @"Button title for installing Growl")
#define UPDATE_BUTTON_TITLE				NSLocalizedStringFromTableInBundle(@"Update", @"GrowlInstallation", [NSBundle bundleForClass:[self class]], @"Button title for updating Growl")
#define CANCEL_BUTTON_TITLE				NSLocalizedStringFromTableInBundle(@"Cancel", @"GrowlInstallation", [NSBundle bundleForClass:[self class]], @"Button title for canceling installation of Growl")
#define DONT_ASK_AGAIN_CHECKBOX_TITLE	NSLocalizedStringFromTableInBundle(@"Don't Ask Again", @"GrowlInstallation", [NSBundle bundleForClass:[self class]], @"Don't ask again checkbox title for installation of Growl")

#define GROWL_TEXT_SIZE 11

#ifndef NSAppKitVersionNumber10_3
# define NSAppKitVersionNumber10_3 743
#endif

/*!
* The 10.3+ exception handling can only work if -fobjc-exceptions is enabled
 */
#if 0
	#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_3
		# define TRY		@try {
		# define ENDTRY		}
		# define CATCH		@catch(NSException *localException) {
		# define ENDCATCH	}
	#else
		# define TRY		NS_DURING
		# define ENDTRY
		# define CATCH		NS_HANDLER
		# define ENDCATCH	NS_ENDHANDLER
	#endif
#else
	# define TRY		NS_DURING
	# define ENDTRY
	# define CATCH		NS_HANDLER
	# define ENDCATCH	NS_ENDHANDLER
#endif


@interface NSWorkspace (ProcessSerialNumberFinder)
- (ProcessSerialNumber)processSerialNumberForApplicationWithIdentifier:(NSString *)identifier;
@end

@interface GrowlInstallationPrompt (PRIVATE)
- (id)initWithWindowNibName:(NSString *)nibName forUpdateToVersion:(NSString *)updateVersion;
- (void) performInstallGrowl;
- (void) releaseAndClose;
@end

@implementation GrowlInstallationPrompt

+ (void) showInstallationPrompt {
	if (GrowlCheckOSXVersion()) {
		[[[[GrowlInstallationPrompt alloc] initWithWindowNibName:GROWL_INSTALLATION_NIB forUpdateToVersion:nil] window] makeKeyAndOrderFront:nil];
	}
}

+ (void) showUpdatePromptForVersion:(NSString *)inUpdateVersion {
	if (GrowlCheckOSXVersion()) {
		[[[[GrowlInstallationPrompt alloc] initWithWindowNibName:GROWL_INSTALLATION_NIB forUpdateToVersion:inUpdateVersion] window] makeKeyAndOrderFront:nil];
	}
}

- (id) initWithWindowNibName:(NSString *)nibName forUpdateToVersion:(NSString *)inUpdateVersion {
	if ((self = [self initWithWindowNibName:nibName])) {
		updateVersion = [inUpdateVersion retain];
	}

	return self;
}

- (void) finalize
{
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];

	[super finalize];
}

- (void) dealloc {
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[updateVersion release];
	[temporaryDirectory release];

	[super dealloc];
}

// closes this window
- (IBAction) closeWindow:(id)sender {
#pragma unused(sender)
	if ([self windowShouldClose:nil])
		[[self window] close];
}

// called after the about window loads, so we can set up the window before it's displayed
- (void) windowDidLoad {
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
	CGFloat	heightChange;

	//Resize the window frame to fit the description
	[textView_growlInfo sizeToFit];
	heightChange = [textView_growlInfo frame].size.height - [scrollView_growlInfo documentVisibleRect].size.height;
	frame.size.height += heightChange;
	frame.origin.y -= heightChange;
	[theWindow setFrame:frame display:YES];

	//Localize and size the buttons

	//The install button should maintain its distance from the right side of the window
	NSRect	newInstallButtonFrame, oldInstallButtonFrame;
	CGFloat installButtonOriginLeftShift;
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

	//put the spinner to the left of the Cancel button
	NSRect spinnerFrame = [spinner frame];
	spinnerFrame.origin.x = newCancelButtonFrame.origin.x - (spinnerFrame.size.width + 8.0);
	[spinner setFrame:spinnerFrame];

	[spinner stopAnimation:nil];
	[button_install setEnabled:YES];
	[button_cancel  setEnabled:YES];
}

- (IBAction) installGrowl:(id)sender {
#pragma unused(sender)
	[spinner startAnimation:sender];
	[button_install setEnabled:NO];
	[button_cancel  setEnabled:NO];

	[self performInstallGrowl];

	[self releaseAndClose];
}

- (IBAction) cancel:(id)sender {
#pragma unused(sender)
	if (!updateVersion) {
		//Tell the app bridge about the user's choice
		[GrowlApplicationBridge _userChoseNotToInstallGrowl];
	}

	//Shut down the installation prompt
	[self releaseAndClose];
}

- (IBAction) dontAskAgain:(id)sender {
	BOOL dontAskAgain = ([sender state] == NSOnState);

	if (updateVersion) {
		if (dontAskAgain) {
			/* We want to be able to prompt again for the next version, so we track the version for which the user requested
			 * not to be prompted again.
			 */
			[[NSUserDefaults standardUserDefaults] setObject:updateVersion
													  forKey:@"Growl Update:Do Not Prompt Again:Last Version"];
		} else {
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Growl Update:Do Not Prompt Again:Last Version"];
		}

	} else {
		//Store the user's preference to the user defaults dictionary
		[[NSUserDefaults standardUserDefaults] setBool:dontAskAgain
												forKey:@"Growl Installation:Do Not Prompt Again"];
	}
}

// called as the window closes
- (BOOL) windowShouldClose:(id)sender {
#pragma unused(sender)
	//If the window closes via the close button or cmd-W, it should be treated as clicking Cancel.
	[self cancel:nil];

	return YES;
}

/*!
 * @brief Delete any existing Growl installation
 *
 * @result YES if delete was successful or not needed; NO if there was an error.
 */
- (BOOL) deleteExistingGrowlInstallation
{
	NSString *oldGrowlPath = [[GrowlPathUtilities growlPrefPaneBundle] bundlePath];
	if (oldGrowlPath) {
		return [[NSFileManager defaultManager] deletePathWithAuthentication:oldGrowlPath]; 
	}
	
	return YES;
}

/*!
 * @brief Install Growl from a temporary directory into which the Growl preference pane has been extracted
 *
 * @param tmpDir The directory in which GROWL_PREFPANE_NAME already exists.
 * @result YES if Growl is succesfully installed. NO if it fails.
 */
- (BOOL) installGrowlFromTmpDir:(NSString *)tmpDir
{
	BOOL success;
	
	/* Open Growl.prefPane using System Preferences, which will take care of the rest.
	 * Growl.prefPane will relaunch the GHA if appropriate.
	 */
	NSString *tempGrowlPrefPane = [tmpDir stringByAppendingPathComponent:GROWL_PREFPANE_NAME];
	if ([[NSWorkspace sharedWorkspace] respondsToSelector:@selector(openURLs:withAppBundleIdentifier:options:additionalEventParamDescriptor:launchIdentifiers:)]) {
		/* Available in 10.3 and above only; preferred since it doesn't matter if System Preferences.app has been renamed */
		NSArray *identifiers;
		success = [[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:[NSURL fileURLWithPath:tempGrowlPrefPane]]
								  withAppBundleIdentifier:@"com.apple.systempreferences"
												  options:NSWorkspaceLaunchDefault
						   additionalEventParamDescriptor:nil
										launchIdentifiers:&identifiers];
		
	} else {
		//We should never get here, since Growl doesn't run in 10.2.
		success = [[NSWorkspace sharedWorkspace] openFile:tempGrowlPrefPane
										  withApplication:@"System Preferences"
											andDeactivate:YES];
	}

	if (!success) {
		NSLog(@"GrowlInstallationPrompt: Warning: Could not find the System Preferences via NSWorksapce");
		
		/*If the System Preferences app could not be found for
		 *	whatever reason, try opening Growl.prefPane with
		 *	-openTempFile: so the associated app will launch. This
		 *	could be the case if an alternative program were being used.
		 */
		success = [[NSWorkspace sharedWorkspace] openTempFile:tempGrowlPrefPane];
		if (!success) {
			NSLog(@"GrowlInstallationPrompt: Could not open %@",tempGrowlPrefPane);
		}
	}

	return success;
}

- (BOOL) continuePerformInstallGrowl:(NSNotification *)notification
{
	BOOL success = NO;

	if (!notification ||
		[[[notification userInfo] objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:@"com.apple.systempreferences"]) {
		if ([self deleteExistingGrowlInstallation]) {
			success = [self installGrowlFromTmpDir:temporaryDirectory];
		} else {
			NSLog(@"Could not delete the existing Growl installation. Perhaps there was an authorization failure?");
		}

		if (!success) {
			NSLog(@"GrowlInstallationPrompt: Growl was not successfully installed");
		}

		//Retained in -[self performInstallGrowl].
		[self autorelease];
	}
	
	return success;
}

- (void) performInstallGrowl {
	// Obtain the path to the archived Growl.prefPane
	NSFileManager *mgr = [NSFileManager defaultManager];
	NSBundle *bundle;
	NSString *archivePath, *tmpDir;
	NSTask	*unzip;
	BOOL success = NO;

	bundle = [NSBundle bundleWithIdentifier:@"com.growl.growlwithinstallerframework"];
	archivePath = [bundle pathForResource:GROWL_PREFPANE_NAME ofType:@"zip"];

	//desired folder (Panther): /private/tmp/$UID/GrowlInstallations/`uuidgen`
	//desired folder (Tiger):   /private/var/tmp/folders.$UID/TemporaryItems/GrowlInstallations/`uuidgen`

	tmpDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"GrowlInstallations"];
	if (tmpDir) {
		[[NSFileManager defaultManager] createDirectoryAtPath:tmpDir attributes:nil];

		CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
		CFStringRef uuidString = CFUUIDCreateString(kCFAllocatorDefault, uuid);
		CFRelease(uuid);
		tmpDir = [tmpDir stringByAppendingPathComponent:(NSString *)uuidString];
		CFRelease(uuidString);
		if (tmpDir) {
			[mgr createDirectoryAtPath:tmpDir attributes:nil];
			BOOL hasUnzip = YES;
			BOOL usingArchiveUtility = YES;
			NSString *launchPath;
			NSArray *arguments = nil;

			//10.5 and later: Try Archive Utility.
			launchPath = @"/System/Library/CoreServices/Archive Utility.app/Contents/MacOS/Archive Utility";
			//10.4: Archive Utility was called BOMArchiveHelper back then.
			if (![mgr fileExistsAtPath:launchPath]) 
				launchPath = @"/System/Library/CoreServices/BOMArchiveHelper.app/Contents/MacOS/BOMArchiveHelper";

			if ([mgr fileExistsAtPath:launchPath]) {
				//BOMArchiveHelper is more particular than unzip, so we need to do some clean-up first:
				//(1) copy the zip file into the temporary directory.
				NSString *archiveFilename = [archivePath lastPathComponent];
				NSString *tmpArchivePath = [tmpDir stringByAppendingPathComponent:archiveFilename];
				[mgr copyPath:archivePath
				       toPath:tmpArchivePath
				      handler:nil];

				//(2) pass BOMArchiveHelper only the path to the archive.
				arguments = [NSArray arrayWithObject:tmpArchivePath];
			} else {
				//10.3: No BOMArchiveHelper - fall back on unzip.
				launchPath = @"/usr/bin/unzip";
				hasUnzip = [mgr fileExistsAtPath:launchPath];
				usingArchiveUtility = NO;

				if (hasUnzip) {
					arguments = [NSArray arrayWithObjects:
						@"-o",         //overwrite
						@"-q",         //quiet!
						archivePath,   //source zip file
						@"-d", tmpDir, //The temporary folder is the destination folder
						nil];
				}
			}

			if (hasUnzip) {
				unzip = [[NSTask alloc] init];
				[unzip setLaunchPath:launchPath];
				[unzip setArguments:arguments];
				[unzip setCurrentDirectoryPath:tmpDir];

				TRY
					[unzip launch];
					[unzip waitUntilExit];
					/* The BOMArchiveHelper, as of 10.4.8, appears to return a termination status of -1 even with success. Weird. */
					success = (([unzip terminationStatus] == 0) || (usingArchiveUtility && ([unzip terminationStatus] == -1)));
					if (!success) {
						NSLog(@"GrowlInstallationPrompt: unzip task %@ (launchPath %@, arguments %@, currentDir %@) returned termination status of %i",
							  unzip, launchPath, arguments, tmpDir, [unzip terminationStatus]);
					}
				ENDTRY
				CATCH
					NSLog(@"GrowlInstallationPrompt: unzip task %@ failed.",unzip);
					success = NO;
				ENDCATCH
				[unzip release];
			} else {
				NSLog(@"GrowlInstallationPrompt: Could not find /System/Library/CoreServices/BOMArchiveHelper.app/Contents/MacOS/BOMArchiveHelper or /usr/bin/unzip");
			}

			if (success) {
				/*Kill the running GrowlHelperApp if necessary by asking it via
				 *	DNC to shutdown.
				 */
				[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_SHUTDOWN
																			   object:nil
																			 userInfo:nil];
				//tell GAB to register when GHA next launches.
				[GrowlApplicationBridge setWillRegisterWhenGrowlIsReady:YES];

				[temporaryDirectory release];
				temporaryDirectory = [tmpDir retain];

				/* Will release in -[self continuePerformInstallGrowl:]. Needed to handle the possibility of a
				 * notification later calling continuePerformInstallGrowl:
				 */
				[self retain];
				
				//If there's an existing version of Growl, system preferneces must not be running
				NSString *oldGrowlPath = [[GrowlPathUtilities growlPrefPaneBundle] bundlePath];
				if (oldGrowlPath) {
					ProcessSerialNumber psn = [[NSWorkspace sharedWorkspace] processSerialNumberForApplicationWithIdentifier:@"com.apple.systempreferences"];
					if (psn.highLongOfPSN != 0 || psn.lowLongOfPSN != 0) {
						NSAppleEventDescriptor *descriptor;
						/* tell application "System Preferences" to quit. The name may be localized, so we can't use applescript directly. */
						[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
																			   selector:@selector(continuePerformInstallGrowl:)
																				   name:NSWorkspaceDidTerminateApplicationNotification
																				 object:nil];
						descriptor = [AEVT class:kCoreEventClass id:kAEQuitApplication
										  target:psn,
									  ENDRECORD];
						[descriptor sendWithImmediateReplyWithTimeout:5];

						/* Whenever system prefs quits, we'll continue in -[self continuePerformInstallGrowl:].
						 * This method will be responsible for further upgrade logic.
						 */
						return;
					}
				}

				//Install immediately. This method will be responsible for further upgrade logic.
				success = [self continuePerformInstallGrowl:nil];
			} else {
				NSLog(@"GrowlInstallationPrompt: unzip with %@ failed", launchPath);
			}
		}
	} else {
		NSLog(@"GrowlInstallationPrompt: Could not get a temporary directory");	
	}

	if (!success) {
#warning XXX - show this to the user; do not just log it.
		NSLog(@"GrowlInstallationPrompt: Growl was not successfully installed");
	}
}

- (void)releaseAndClose {
	[self autorelease];
	[[self window] close];
}

@end

@implementation NSWorkspace (ProcessSerialNumberFinder)
- (ProcessSerialNumber)processSerialNumberForApplicationWithIdentifier:(NSString *)identifier
{
	ProcessSerialNumber psn = {0, 0};
	
	for (NSDictionary *dict in [self launchedApplications]) {
		if ([[dict objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:identifier]) {
			psn.highLongOfPSN = [[dict objectForKey:@"NSApplicationProcessSerialNumberHigh"] unsignedIntValue];	// no, really these numbers are UInt32s now, not longs
			psn.lowLongOfPSN  = [[dict objectForKey:@"NSApplicationProcessSerialNumberLow"] unsignedIntValue];
			break;
		}
	}
	
	return psn;
}
@end
