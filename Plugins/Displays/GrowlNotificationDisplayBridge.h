//
//  GrowlNotificationDisplayBridge.h
//  Growl
//
//  Created by Mac-arena the Bored Zo on 2005-06-05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

@class GrowlApplicationNotification, GrowlDisplayPlugin, GrowlDisplayWindowController;

@interface GrowlNotificationDisplayBridge : NSObject {
	GrowlDisplayPlugin           *display;
	GrowlApplicationNotification *notification;
	NSString                     *windowNibName;
	NSMutableArray               *windowControllers;
	Class                        windowControllerClass;
}

+ (GrowlNotificationDisplayBridge *) bridgeWithDisplay:(GrowlDisplayPlugin *)newDisplay
										  notification:(GrowlApplicationNotification *)newNotification
								 windowControllerClass:(Class)wcc;

+ (GrowlNotificationDisplayBridge *) bridgeWithDisplay:(GrowlDisplayPlugin *)newDisplay
										  notification:(GrowlApplicationNotification *)newNotification
										 windowNibName:(NSString *)newWindowNibName
								 windowControllerClass:(Class)wcc;

- (id) initWithDisplay:(GrowlDisplayPlugin *)newDisplay
		  notification:(GrowlApplicationNotification *)newNotification
 windowControllerClass:(Class)wcc;

- (id) initWithDisplay:(GrowlDisplayPlugin *)newDisplay
		  notification:(GrowlApplicationNotification *)newNotification
		 windowNibName:(NSString *)newWindowNibName
 windowControllerClass:(Class)wcc;

#pragma mark -

//XXX DocumentMe
//override this if you want to create multiple WCs.
- (void) makeWindowControllers;

//XXX DocumentMe
- (GrowlDisplayPlugin *) display;

//XXX DocumentMe
- (GrowlApplicationNotification *) notification;

//XXX DocumentMe
//if you override -makeWindowControllers, you don't (necessarily) need to override this.
- (NSString *) windowNibName;

//XXX DocumentMe
//be sure to call up to super.
- (void) windowControllerWillLoadNib:(GrowlDisplayWindowController *)windowController;
- (void) windowControllerDidLoadNib:(GrowlDisplayWindowController *)windowController;

//XXX DocumentMe
//don't override these.
- (void) addWindowController:(GrowlDisplayWindowController *)newWindowController;
- (void) removeWindowController:(GrowlDisplayWindowController *)windowControllerToRemove;

- (BOOL) containsWindowController:(GrowlDisplayWindowController *)windowController;

/*!	@method	windowControllers
 *	@abstract	Returns all of the window controllers associated with this display.
 *	@discussion	Returns all of the window controllers that have been added with <code>addWindowController:</code>, that haven't been removed with <code>removeWindowController:</code>.
 *
 *	 You shouldn't need to override this method.
 *	@result	An array of zero or more <code>GrowlDisplayWindowController</code>s.
 */
- (NSArray *) windowControllers;

@end

@interface NSArray (GrowlDisplaySearching)

- (GrowlNotificationDisplayBridge *) bridgeForWindowController:(GrowlDisplayWindowController *) windowController;

@end
