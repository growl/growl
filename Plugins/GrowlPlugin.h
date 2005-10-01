//
//  GrowlPlugin.h
//  Growl
//
//  Created by Mac-arena the Bored Zo on 2005-06-01.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NSPreferencePane;

/*!	@class	GrowlPlugin
 *	@abstract	The base plug-in class.
 *	@discussion	All Growl plug-in instances are a kind of this class, including
 *	 display plug-ins, which are kinds of <code>GrowlDisplayPlugin</code>.
 */
@interface GrowlPlugin : NSObject {
	NSString *pluginName, *pluginAuthor, *pluginVersion, *pluginDesc;
	NSBundle *pluginBundle;
	NSString *pluginPathname;

	NSPreferencePane *preferencePane;
}

//designated initialiser.
- (id) initWithName:(NSString *)name author:(NSString *)author version:(NSString *)version pathname:(NSString *)pathname;
/*use this initialiser for plug-ins in bundles. the name, author, version, and
 *	pathname will be obtained from the bundle.
 */
- (id) initWithBundle:(NSBundle *)bundle;

#pragma mark -

- (NSString *) name;
- (NSString *) author;
- (NSString *) version;

- (NSBundle *) bundle;
- (NSString *) pathname;

#pragma mark -

/*!	@method	preferencePane
 *	@abstract	Return an <code>NSPreferencePane</code> instance that manages
 *	 the plugin's preferences.
 *	@discussion	Your plug-in should put the controls for its preferences in
 *	 this preference pane.
 *
 *	 Currently, the size of the preference pane's view should be 354 pixels by
 *	 289 pixels, but you should set the springs of the view and its subviews
 *	 under the assumption that it can be resized horizontally and vertically to
 *	 any size.
 *
 *	 The default implementation of this method returns <code>nil</code>.
 *	@result	The preference pane. Can be <code>nil</code>.
 */
- (NSPreferencePane *) preferencePane;

@end
