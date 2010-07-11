//
//  GrowlRemotePathway.h
//  Growl
//
//  Created by Mac-arena the Bored Zo on 2005-03-12.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlPathway.h"

/*subclassing note: your remote pathway should not be listening for
 *	notifications right out of the box.
 *GrowlPathwayController will call setEnabled:YES at the appropriate time, and
 *	then (and only then), your pathway should start listening.
 */
@interface GrowlRemotePathway: GrowlPathway {
	BOOL enabled;
}

#warning investigate an alternative mechanism for reporting failure to enable the pathway, this violates Cocoa design patterns.
//-setEnabled: returns YES if it succeeded. (see GrowlUDPPathway for an example of such error-handling.)
- (BOOL) setEnabled:(BOOL)flag;
- (BOOL) isEnabled;

@end
