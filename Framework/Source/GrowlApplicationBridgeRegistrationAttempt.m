//
//  GrowlApplicationBridgeRegistrationAttempt.m
//  Growl
//
//  Created by Peter Hosey on 2011-07-11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlApplicationBridgeRegistrationAttempt.h"

#import "GrowlPathUtilities.h"
#import "GrowlProcessUtilities.h"

#import "GrowlDefines.h"
#import "GrowlDefinesInternal.h"

@implementation GrowlApplicationBridgeRegistrationAttempt

@synthesize applicationName;

- (void) begin {
	BOOL success = NO;

	//First look for a running GHA. It might not actually be within a Growl prefpane bundle.
	NSString *growlHelperAppPath = [[GrowlPathUtilities runningHelperAppBundle] bundlePath];

	//Houston, we are go for launch.
	if (growlHelperAppPath) {
		//Let's launch in the background (requires sending the Apple Event ourselves, as LS may activate the application anyway if it's already running)
		NSURL *appURL = [NSURL fileURLWithPath:growlHelperAppPath];
		if (appURL) {
			//Find the PSN for GrowlHelperApp. (We'll need this later.)
			struct ProcessSerialNumber appPSN = {
				0, kNoProcess
			};
			BOOL isRunning = Growl_GetPSNForProcessWithBundlePath(growlHelperAppPath, &appPSN);
			if (isRunning) {
				NSURL *regItemURL = nil;
				BOOL passRegDict = NO;

				if (self.dictionary) {
					NSString *regDictFileName;
					NSString *regDictPath;

					//Obtain a truly unique file name
					CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
					CFStringRef uuidString = CFUUIDCreateString(kCFAllocatorDefault, uuid);
					CFRelease(uuid);
					regDictFileName = [[NSString stringWithFormat:@"%@-%u-%@", [self.dictionary objectForKey:GROWL_APP_NAME], getpid(), (NSString *)uuidString] stringByAppendingPathExtension:GROWL_REG_DICT_EXTENSION];
					CFRelease(uuidString);
					if ([regDictFileName length] > NAME_MAX)
						regDictFileName = [[regDictFileName substringToIndex:(NAME_MAX - [GROWL_REG_DICT_EXTENSION length])] stringByAppendingPathExtension:GROWL_REG_DICT_EXTENSION];

					//make sure it's within pathname length constraints
					regDictPath = [NSTemporaryDirectory() stringByAppendingPathComponent:regDictFileName];
					if ([regDictPath length] > PATH_MAX)
						regDictPath = [[regDictPath substringToIndex:(PATH_MAX - [GROWL_REG_DICT_EXTENSION length])] stringByAppendingPathExtension:GROWL_REG_DICT_EXTENSION];

					//Write the registration dictionary out to the temporary directory
					NSData *plistData;
					NSString *errorString;
					plistData = [NSPropertyListSerialization dataFromPropertyList:self.dictionary
																		   format:NSPropertyListBinaryFormat_v1_0
																 errorDescription:&errorString];
					if (plistData) {
						if (![plistData writeToFile:regDictPath atomically:NO])
							NSLog(@"GrowlApplicationBridge: Error writing registration dictionary at %@", regDictPath);
					} else {
						NSLog(@"GrowlApplicationBridge: Error writing registration dictionary at %@: %@", regDictPath, errorString);
						NSLog(@"GrowlApplicationBridge: Registration dictionary follows\n%@", self.dictionary);
						[errorString release];
					}

					if ([[NSFileManager defaultManager] fileExistsAtPath:regDictPath]) {
						regItemURL = [NSURL fileURLWithPath:regDictPath];
						passRegDict = YES;
					}
				}

				AEStreamRef stream = AEStreamCreateEvent(kCoreEventClass, kAEOpenDocuments,
					//Target application
					typeProcessSerialNumber, &appPSN, sizeof(appPSN),
					kAutoGenerateReturnID, kAnyTransactionID);
				if (!stream) {
					NSLog(@"%@: Could not create open-document event to register this application with Growl", [self class]);
				} else {
					OSStatus err;

					if (passRegDict) {
						NSString *regItemURLString = [regItemURL absoluteString];
						NSData *regItemURLUTF8Data = [regItemURLString dataUsingEncoding:NSUTF8StringEncoding];
						err = AEStreamWriteKeyDesc(stream, keyDirectObject, typeFileURL, [regItemURLUTF8Data bytes], [regItemURLUTF8Data length]);
						if (err != noErr) {
							NSLog(@"%@: Could not set direct object of open-document event to register this application with Growl because AEStreamWriteKeyDesc returned %li/%s", [self class], (long)err, GetMacOSStatusCommentString(err));
						}
					}

					AppleEvent event;
					err = AEStreamClose(stream, &event);
					if (err != noErr) {
						NSLog(@"%@: Could not finish open-document event to register this application with Growl because AEStreamClose returned %li/%s", [self class], (long)err, GetMacOSStatusCommentString(err));
					} else {
						err = AESendMessage(&event, /*reply*/ NULL, kAENoReply | kAEDontReconnect | kAENeverInteract | kAEDontRecord, kAEDefaultTimeout);
						if (err != noErr) {
							NSLog(@"%@: Could not send open-document event to register this application with Growl because AESend returned %li/%s", [self class], (long)err, GetMacOSStatusCommentString(err));
						}

						AEDisposeDesc(&event);
					}
					
					success = (err == noErr);
				}
			}
		}
	}

	if (success) {
		[self succeeded];
	} else {
		[self failed];
	}
}

@end
