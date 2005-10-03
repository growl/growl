//
//  GrowlNotificationView.h
//  Growl
//
//  Created by Ofri Wolfus on 01/10/05.
//  Copyright 2005 Ofri Wolfus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/*!
 * @class GrowlNotificationView
 * @abstract GrowlNotificationView is a subclass of NSView that performs all drawing on a secondary thread.
 */
@interface GrowlNotificationView : NSView {
	NSThread *mainThread;
}

@end
