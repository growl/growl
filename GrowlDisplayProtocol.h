//
//  GrowlDisplayProtocol.h
//  Growl
//

/*!
	@header
	@abstract    Defines the protocols used by plugins
	@discussion  This header defines the 3 protocols used by plugins.
	
	The base protocol &lt;GrowlPlugin&gt; isn't intended to be used by anything else, it's
	basically an abstract superprotocol for the other protocols.
	
	The protocol &lt;GrowlDisplayPlugin&gt; is meant for plugins that provide alternate displays.
	
	The protocol &lt;GrowlFunctionalPlugin&gt; is meant for plugins that provide additional functionality.
 */

@class NSPreferencePane;

/*!
	@protocol    GrowlPlugin
	@abstract    The base plugin protocol
	@discussion  A protocol defining all methods supported by all Growl plugins.
 */
@protocol GrowlPlugin
/*! A method sent to tell the plugin to initialize itself */
- (void) loadPlugin;
/*! Returns the name of the author of the plugin
	@result A string */
- (NSString *) author;
/*! Returns the name of the plugin
	@result A string */
- (NSString *) name;
/*! Returns the description of the plugin
	@result A string */
- (NSString *) userDescription;
/*! Returns the version of the plugin
	@result A string */
- (NSString *) version;
/*! Returns a dictionary containing author, name, desc, and version for the plugin.
	
	The corresponding keys are: Author, Name, Description, Version */
- (NSDictionary *) pluginInfo;
/*! A method sent to tell the plugin to clean itself up */
- (void) unloadPlugin;
/*! Returns an NSPreferencePane instance that manages the plugin's preferences.
	
	For reference, the size of the view should be 354 x 289.
	That's because that's all the available space right now.
	We have to think of something if there are more options than fit in that place.
 */
- (NSPreferencePane *) preferencePane;
@end

/*!
	@protocol    GrowlDisplayPlugin
	@abstract    The display plugin protocol
	@discussion  A protocol defining all methods supported by Growl display plugins.
 */
@protocol GrowlDisplayPlugin <GrowlPlugin>
/*! Tells the display plugin to display a notification with the given information
	@param noteDict The userInfo dictionary that describes the notification */
- (void)  displayNotificationWithInfo:(NSDictionary *) noteDict;
@end

/*!
	@protocol    GrowlFunctionalPlugin
	@abstract    The functional plugin protocol
	@discussion  A protocol defining all methods supported by Growl functionality plugins.
	
	Currently has no new methods on top of GrowlDisplayPlugin.
 */
@protocol GrowlFunctionalPlugin <GrowlPlugin>
//empty for now
@end
