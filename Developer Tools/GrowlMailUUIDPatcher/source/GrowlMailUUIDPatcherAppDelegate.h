//
//  GrowlMailUUIDPatcherAppDelegate.h
//  GrowlMailUUIDPatcher
//
//  Created by Rudy Richter on 7/10/10.
//  Copyright 2010 Beware Reactor. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GrowlMailUUIDPatcherAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
	NSTextField *status;
	NSTextField *needsUpdate;
	NSButton *updateButton;
	
	NSString *mailAppUUID;
	NSString *messageFrameworkUUID;
	
	NSArray *paths;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField *status;
@property (assign) IBOutlet NSTextField *needsUpdate;
@property (assign) IBOutlet NSButton *updateButton;

@property (retain) NSString *mailAppUUID;
@property (retain) NSString *messageFrameworkUUID;

@property (retain) NSArray *paths;

- (void)getUUIDs;
- (NSArray*)growlMailPaths;
- (void)verify;
- (BOOL)checkPlist:(NSString*)path;
- (IBAction)updatePlist:(id)sender;
- (BOOL)mailIsRunning;
- (void)relaunchMail;
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;

@end
