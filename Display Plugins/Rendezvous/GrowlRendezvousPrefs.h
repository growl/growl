//
//  GrowlRendezvousPrefs.h
//  Display Plugins
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

@interface GrowlRendezvousPrefs : NSPreferencePane
{
	IBOutlet NSTableView	*growlServiceList;

    NSMutableArray			*services;
	NSNetServiceBrowser		*browser;
    NSNetService			*serviceBeingResolved;
}
- (IBAction)serviceClicked:(id)sender;

@end
