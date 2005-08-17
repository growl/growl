//
//  JKMenuController.h
//  Rawr-endezvous
//
//  Created by Jeremy Knope on 9/17/04.
//  Copyright 2004 Jeremy Knope. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JKServiceManager.h"

@class JKPreferencesController;

@interface JKMenuController : NSObject {
	IBOutlet JKPreferencesController* prefs;
	JKServiceManager *serviceManager;
	
    NSStatusItem *statusItem;
    
	IBOutlet NSMenu *dockMenu;
	
    NSMutableDictionary *menuServices; // for holding menu->service relations i hope
    NSNetService *serviceBeingResolved;
    
    BOOL isGrowlInstalled;
}

- (void)addMenuItemForService:(NSNetService *)newService;
- (void)removeMenuItemForService:(NSNetService *)oldService;
- (void) itemClicked:(id)sender;
- (IBAction)refreshServices:(id)sender;
@end
