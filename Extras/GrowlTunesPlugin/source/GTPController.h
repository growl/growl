//
//  GTPController.h
//  GrowlTunes
//
//  Created by Rudy Richter on 9/27/09.
//  Copyright 2009 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/GrowlApplicationBridge.h>
#import <GrowlAbstractSingletonObject.h>
#import <NSWorkspaceAdditions.h>

#import "GTPCommon.h"
#import "GTPSettingsWindowController.h"
#import "GTPNotification.h"

#import "SGHotKey.h"
#import "SGHotKeyCenter.h"
#import "SGKeyCombo.h"

#import "GrowlTunesPlugin.h"

@interface GTPController : GrowlAbstractSingletonObject <GrowlApplicationBridgeDelegate, GTPSettingsProtocol> 
{
	NSMutableDictionary *_settings;
	SGKeyCombo *_keyCombo;
	GTPNotification		*_notification;

	GTPSettingsWindowController *_settingsWindow;


	id <GrowlTunesPluginArchive> archivePlugin;
	NSMutableArray		*plugins;
}

- (void)setup;
- (void)showCurrentTrack:(id)sender;
- (void)showSettingsWindow;

#pragma mark Plug-ins

- (NSMutableArray *) loadPlugins;

@property (retain) NSMutableDictionary *settings;
@property (retain) GTPNotification *notification;
@property (retain) SGKeyCombo *keyCombo;
@end
