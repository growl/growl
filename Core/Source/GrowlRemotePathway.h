//
//  GrowlRemotePathway.h
//  Growl
//
//  Created by Peter Hosey on 2005-03-12.
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

@property(nonatomic, assign, getter=isEnabled) BOOL enabled;

@end
