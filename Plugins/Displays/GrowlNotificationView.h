//
//  GrowlNotificationView.h
//  Growl
//
//  Created by Ofri Wolfus on 01/10/05.
//  Copyright 2005 Ofri Wolfus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/*!	@class GrowlNotificationView
 *	@abstract GrowlNotificationView is a subclass of NSView that can perform drawing on a secondary thread.
 *	@discussion	When subclassing, in your -drawRect:, call [self dispatchDrawingToThread:].
 *  If the current thread is the main thread (as it will be when AppKit calls -drawRect:), -dispatchDrawingToThread: will dispatch a drawing thread with NSApplication (hence the name), and then it will return NO, indicating that you should simply return without doing anything further.
 *  When the current thread is the drawing thread, -dispatchDrawingToThread: returns YES, indicating that you should now draw.
 *  All of this is optional. If you want, you can omit the call to -dispatchDrawingToThread:, and simply draw on the main thread.
 */
@interface GrowlNotificationView : NSView {
	NSThread *mainThread;
	unsigned numberOfThreads;
}

/*!
 * @method dispatchDrawingToThread:
 * @abstract Used to execute -drawRect: in a drawing thread so that the main thread will not freeze.
 * @param aRect The rect that will be used by the threaded -drawRect:.
 */
- (BOOL) dispatchDrawingToThread:(NSRect)aRect;

@end
