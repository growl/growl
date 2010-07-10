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
	
	NSString *mailAppUUID;
	NSString *messageFrameworkUUID;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField *status;
@property (assign) IBOutlet NSTextField *needsUpdate;

@property (retain) NSString *mailAppUUID;
@property (retain) NSString *messageFrameworkUUID;

- (void)getUUIDs;
- (NSArray*)growlMailPaths;
- (void)verify:(NSArray*)paths;
- (BOOL)checkPlist:(NSString*)path;
- (IBAction)updatePlist:(id)sender;

@end
