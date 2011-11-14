//
//  GrowlPlugin.h
//  Growl
//
//  Created by Peter Hosey on 2005-06-01.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <PreferencePanes/PreferencePanes.h>


/*!	@protocol	GrowlPlugin
 *	@abstract	The base protcol required by every plugin
 *	@discussion	All Growl plug-in instances are a kind of this class, including
 *	 display plug-ins, which are kinds of <code>GrowlDisplayPlugin</code>.
 */
@protocol GrowlPlugin <NSObject>

/*!
 * @method name
 * @abstract Returns the name of the receiver.
 */
@property (nonatomic, readonly, copy) NSString *name;

/*!
 * @method author
 * @abstract Returns the author of the receiver.
 */
@property (nonatomic, readonly, copy) NSString *author;

/*!
 * @method version
 * @abstract Returns the version of the receiver.
 */
@property (nonatomic, readonly, copy) NSString *version;

/*!
 * @method pluginDescription
 * @abstract Returns the plugin's description.
 */
@property (nonatomic, readonly, copy) NSString *pluginDescription;

/*!
 * @method bundle
 * @abstract Returns the bundle of the receiver.
 */
@property (nonatomic, readonly, retain) NSBundle *bundle;

/*!
 * @method pathname
 * @abstract Returns the pathname of the receiver.
 */
@property (nonatomic, readonly, copy) NSString *pathname;

/*!
 * @method pathname
 * @abstract Returns the string used to access the preference domain of the receiver.
 */
@property (nonatomic, readonly, retain) NSString *prefDomain;


@optional


/*!	@method	allowsMultipleInstances
 *	@abstract	Return an <code>NSPreferencePane</code> instance that manages
 *	 the plugin's preferences.
 *	@result	returns if this class allows multiple instances of this plugin to be loaded
 */
+ (BOOL) allowsMulitpleInstances;


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
 *  
 *   When using multiple instances, this instance of the preference pane 
 *   should only configure settings that relate to this specific 
 *   instance identifer.
 *   
 *
 *	@result	The preference pane. Can be <code>nil</code>.
 */
@property (nonatomic, readonly, assign) NSPreferencePane *preferencePane;


/*!	@method	initWithInstanceIdentifer:
 *	@abstract	Initializes a unique instance of your plugin.
 *	@discussion	If the plugin returns that it to supports multiple instances,
 *   this initalizer is used to initialize the plugin. A unqiue identifier is 
 *   passed in (a UUID string) to identify the plugin instance. This unique 
 *   identifier is stored by growl when the user creates an instance of your 
 *   plugin and will remain the same until the user removes the plugin instance.
 *
 *	@result	An initialized GrowlPlugin object.
 */

-(id) initWithInstanceIdentifer:(NSString *)instanceIdentifer;

/*!	@method	userDidRemoveInstanceIdentifer:
 *	@abstract	called when a user remove an instance of plugin that supports 
 *   multiple isntances.
 *	@discussion	If the plugin returns that it to supports multiple instances,
 *   if implemented, this method is invoked to allow the plugin to clean up any
 *   data relating to a paticular instance.
 *
 *	@result	An initialized GrowlPlugin object.
 */
+(void) userDidRemoveInstanceIdentifer:(NSString *)instanceIdentifer;

@end



/*!	@class	GrowlPlugin
 *	@abstract	An optional abstract base plug-in class.
 *	@discussion	 This is a base class implements the <code>GrowlPlugin</code> 
 *  protocol. Legacy plugins (pre 1.3) inherited from this class.
 *  Starting with Growl 1.4, only supporting the protcol is necessary. 
 *  
 *  Display plugins implement the <code>GrowlDisplayPlugin</code> protocol or inherit the GrowlDisplayPlugin base class.
 */
@interface GrowlPlugin : NSObject<GrowlPlugin> {
	NSString *pluginName; 
    NSString *pluginAuthor;
    NSString *pluginVersion;
    NSString *pluginDesc;
	NSBundle *pluginBundle;
	NSString *pluginPathName;

	NSPreferencePane *preferencePane;
	NSString	     *prefDomain;
}

/*!
 * @method initWithName:author:version:pathname:
 * @abstract Designated initializer.
 * @param name The name of the plugin.
 * @param author The author of the plugin.
 * @param version The version of the plugin.
 * @param pathname The pathname of the plugin.
 * @result An initialized GrowlPlugin object.
 */
- (id) initWithName:(NSString *)name author:(NSString *)author version:(NSString *)version pathname:(NSString *)pathname;

/*!
 * @method initWithBundle:
 * @abstract Initializer for plug-ins in bundles. The name, author, version, and pathname will be obtained from the bundle.
 * @result An initialized GrowlPlugin object.
 */
- (id) initWithBundle:(NSBundle *)bundle;


@end
