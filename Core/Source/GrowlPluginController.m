//
//  GrowlPluginController.m
//  Growl
//
//  Created by Nelson Elhage on 8/25/04.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "GrowlPluginController.h"
#import "GrowlPreferencesController.h"
#import "GrowlDisplayPlugin.h"
#import "GrowlDefinesInternal.h"
#include "CFDictionaryAdditions.h"
#include "CFMutableDictionaryAdditions.h"

#import "GrowlPathUtilities.h"
#import "GrowlNonCopyingMutableDictionary.h"
#import "NSSetAdditions.h"
#import "NSWorkspaceAdditions.h"
#import "GrowlWebKitPluginHandler.h"

@interface GrowlPluginController (PRIVATE)
- (void) registerDefaultPluginHandlers;
- (void) findPluginsInDirectory:(NSString *)dir;
- (void) pluginInstalledSelector:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void) pluginExistsSelector:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
@end

@interface WebCoreCache
+ (void) empty;
@end

//for use as CFSetCallBacks.equal
static Boolean caseInsensitiveStringComparator(const void *value1, const void *value2);
//for use as CFSetCallBacks.hash
static CFHashCode passthroughStringHash(const void *value);
//for use on array of matching plug-in handlers in -openPluginAtPath:
int comparePluginHandlerRegistrationOrder(id a, id b, void *context);

#pragma mark -

NSString *GrowlPluginControllerWillAddPluginHandlerNotification = @"GrowlPluginControllerWillAddPluginHandlerNotification";
NSString *GrowlPluginControllerDidAddPluginHandlerNotification = @"GrowlPluginControllerDidAddPluginHandlerNotification";
NSString *GrowlPluginControllerWillRemovePluginHandlerNotification = @"GrowlPluginControllerWillRemovePluginHandlerNotification";
NSString *GrowlPluginControllerDidRemovePluginHandlerNotification = @"GrowlPluginControllerDidRemovePluginHandlerNotification";

//Info.plist keys for plug-in bundles.
NSString *GrowlPluginInfoKeyName              = @"CFBundleName";
NSString *GrowlPluginInfoKeyAuthor            = @"GrowlPluginAuthor";
NSString *GrowlPluginInfoKeyVersion           = @"CFBundleVersion";
NSString *GrowlPluginInfoKeyDescription       = @"GrowlPluginDescription";
//keys in plug-in description dictionaries (also includes the above).
NSString *GrowlPluginInfoKeyBundle            = @"GrowlPluginBundle";
NSString *GrowlPluginInfoKeyTypes             = @"GrowlPluginType";
NSString *GrowlPluginInfoKeyPath              = @"GrowlPluginPath";
NSString *GrowlPluginInfoKeyHumanReadableName = @"GrowlPluginHumanReadableName";
NSString *GrowlPluginInfoKeyIdentifier        = @"GrowlPluginIdentifier";
NSString *GrowlPluginInfoKeyInstance          = @"GrowlPluginInstance";

/*******************************************************************************
 *  _____ ___  ____   ___
 * |_   _/ _ \|  _ \ / _ \
 *   | || | | | | | | | | |
 *   | || |_| | |_| | |_| |
 *   |_| \___/|____/ \___/
 *
 *******************************************************************************
 *
 * 	-	Use identifier strings for all loaded plug-ins (simpler than using
 *		human-readable names) (DONE though this will probably only be used for
 *		storage of plug-in prefs)
 *	-	Use plug-in dictionaries (DONE)
 *	-	Use GrowlNonCopyingMutableDictionary instead of NSMapTable (DONE)
 *	-	Write the built-in plug-in handler (DONE)
 *	-	Add a WebKit plug-in handler (jkp)
 *	-	Better localize human-readable names
 */

@implementation GrowlPluginController

+ (GrowlPluginController *) sharedController {
	return [self sharedInstance];
}

- (id) initSingleton {
	if ((self = [super initSingleton])) {
		bundlesToLazilyInstantiateAnInstanceFrom = [[NSMutableSet alloc] init];
		
		pluginsByIdentifier         = [[NSMutableDictionary alloc] init];
		pluginIdentifiersByPath     = [[NSMutableDictionary alloc] init];
		pluginIdentifiersByBundle   = [[GrowlNonCopyingMutableDictionary alloc] init];
		pluginIdentifiersByInstance = [[GrowlNonCopyingMutableDictionary alloc] init];

		pluginsByName     = [[NSMutableDictionary alloc] init];
		pluginsByAuthor   = [[NSMutableDictionary alloc] init];
		pluginsByVersion  = [[NSMutableDictionary alloc] init];
		pluginsByFilename = [[NSMutableDictionary alloc] init];
		pluginsByType     = [[NSMutableDictionary alloc] init];
		pluginHumanReadableNames = [[NSCountedSet alloc] init];

		allPluginHandlers = [[NSMutableArray alloc] init];
		pluginHandlers  = [[NSMutableDictionary alloc] init];
		handlersForPlugins = [[GrowlNonCopyingMutableDictionary alloc] init];

		displayPlugins = [[NSMutableArray alloc] init];

		[self registerDefaultPluginHandlers];

		enum { builtInTypesCount = 4U };
		NSString *builtInTypesArray[builtInTypesCount] = {
			GROWL_STYLE_EXTENSION,
			GROWL_VIEW_EXTENSION,
			GROWL_PATHWAY_EXTENSION,
			GROWL_PLUGIN_EXTENSION,
		};
		CFSetCallBacks callbacks = kCFCopyStringSetCallBacks;
		callbacks.equal = caseInsensitiveStringComparator;
		callbacks.hash = passthroughStringHash;
		builtInTypes = (NSSet *)CFSetCreate(kCFAllocatorDefault,
		                                    (const void **)builtInTypesArray,
		                                    builtInTypesCount,
		                                    &callbacks);

		//find plug-ins in Library/Application Support/Growl/Plugins directories.
		NSArray *libraries = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
		NSEnumerator *enumerator = [libraries objectEnumerator];
		NSString *dir;
		while ((dir = [enumerator nextObject])) {
			dir = [dir stringByAppendingPathComponent:@"Application Support/Growl/Plugins"];
			[self findPluginsInDirectory:dir];
		}

		//and inside GHA itself.
		[self findPluginsInDirectory:[[GrowlPathUtilities helperAppBundle] builtInPlugInsPath]];
	}

	return self;
}

- (void) destroy {
	[pluginsByIdentifier     release];	
	[pluginIdentifiersByPath release];
	[pluginIdentifiersByBundle release];
	[pluginIdentifiersByInstance release];

	[pluginsByName     release];
	[pluginsByAuthor   release];
	[pluginsByVersion  release];
	[pluginsByFilename release];
	[pluginsByType     release];
	[pluginHumanReadableNames release];

	[bundlesToLazilyInstantiateAnInstanceFrom release];
	[displayPlugins release];

	[allPluginHandlers release];
	[pluginHandlers  release];
	[handlersForPlugins release];

	[builtInTypes release];

	[cache_allPlugins release];
	[cache_allPluginsArray release];
	[cache_registeredPluginTypes release];
	[cache_registeredPluginNames release];
	[cache_registeredPluginNamesArray release];
	[cache_allPluginInstances release];
	[cache_displayPlugins release];

	[super destroy];
}

#pragma mark -

- (void) registerDefaultPluginHandlers {
	//register ourselves for display plug-ins (non-WebKit), pathway plug-ins, and functional plug-ins.
	NSSet *types = [[NSSet alloc] initWithObjects:
		//display plug-ins
		GROWL_VIEW_EXTENSION,
		NSFileTypeForHFSTypeCode(FOUR_CHAR_CODE('DISP')),
		//pathway plug-ins
		GROWL_PATHWAY_EXTENSION,
		NSFileTypeForHFSTypeCode(FOUR_CHAR_CODE('PWAY')),
		//generic functional plug-ins
		GROWL_PLUGIN_EXTENSION,
		NSFileTypeForHFSTypeCode(FOUR_CHAR_CODE('GEXT')),
		nil];

	[self addPluginHandler:self forPluginTypes:types];

	[types release];

	[GrowlWebKitPluginHandler sharedInstance];		// Calling this here will cause the handler to register
}

#pragma mark -
#pragma mark GrowlPluginHandler protocol conformance

//the method that dispatches incoming plug-ins to plug-in handlers is -dispatchPluginAtPath:.
//this is for handling plug-ins of the built-in types.
- (BOOL)loadPluginWithBundle:(NSBundle *)bundle {
	[self addPluginInstance:nil fromBundle:bundle];

	return YES;
}

#pragma mark -
#pragma mark Plugin-handler handling

- (void) addPluginHandler:(id <GrowlPluginHandler>)handler forPluginTypes:(NSSet *)types {
	NSParameterAssert(handler != nil);
	NSParameterAssert(types != nil);

	if (![types count]) {
		NSLog(@"Warning: -[%@ addPluginHandler:forPluginTypes:] called with an empty set of file types. This may be indicative of a bug in Growl or a plug-in. The handler was %@.", [self class], handler);
	} else {
		//make sure nobody tries to register a plug-in handler for a built-in type.
		if (builtInTypes) {
			NSMutableSet *builtInMutable = [builtInTypes mutableCopy];
			[builtInMutable intersectSet:types];

			//the intersection must be empty; if it isn't, at least one of the types for which this handler is attempting to register is a built-in type.
			NSAssert2([builtInMutable count] == 0U, @"Something attempted to register a plug-in handler for one or more reserved file types (%@). The handler was %@.", builtInMutable, handler);

			[builtInMutable release];
		}

		NSEnumerator *typeEnum = [types objectEnumerator];
		NSString *type;
		while ((type = [typeEnum nextObject])) {
			//normalise: strip leading ., if any.
			unsigned i = 0U, len = [type length];
			for (; i < len; ++i) {
				if ([type characterAtIndex:i] != '.')
					break;
			}
			NSAssert2(i < len, @"Something tried to register a plug-in handler for a file type consisting entirely of %u full stops ('.'). The handler was %@.", len, handler);
			if (i)
				type = [type substringFromIndex:i];

			NSMutableArray *handlers = [pluginHandlers objectForKey:type];
			if (!handlers) {
				handlers = [[NSMutableArray alloc] initWithCapacity:1U];
				[pluginHandlers setObject:handlers forKey:type];
				[handlers release];
			}
			[handlers addObject:handler];
		}

		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		NSDictionary *notificationUserInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
			handler, @"GrowlPluginHandler",
			nil];

		[nc postNotificationName:GrowlPluginControllerWillAddPluginHandlerNotification
						  object:self
						userInfo:notificationUserInfo];

		[allPluginHandlers addObject:handler];

		//add the handler as an observer for various notifications.
		if ([handler respondsToSelector:@selector(growlPluginControllerWillAddPluginHandler:)]) {
			[nc addObserver:handler
				   selector:@selector(growlPluginControllerWillAddPluginHandler:)
					   name:GrowlPluginControllerWillAddPluginHandlerNotification
					 object:self];
		}
		if ([handler respondsToSelector:@selector(growlPluginControllerDidAddPluginHandler:)]) {
			[nc addObserver:handler
				   selector:@selector(growlPluginControllerDidAddPluginHandler:)
					   name:GrowlPluginControllerDidAddPluginHandlerNotification
					 object:self];
		}
		if ([handler respondsToSelector:@selector(growlPluginControllerWillRemovePluginHandler:)]) {
			[nc addObserver:handler
				   selector:@selector(growlPluginControllerWillRemovePluginHandler:)
					   name:GrowlPluginControllerWillRemovePluginHandlerNotification
					 object:self];
		}
		if ([handler respondsToSelector:@selector(growlPluginControllerDidRemovePluginHandler:)]) {
			[nc addObserver:handler
				   selector:@selector(growlPluginControllerDidRemovePluginHandler:)
					   name:GrowlPluginControllerDidRemovePluginHandlerNotification
					 object:self];
		}

		[nc postNotificationName:GrowlPluginControllerDidAddPluginHandlerNotification
						  object:self
						userInfo:notificationUserInfo];
	}
}
- (void) removePluginHandler:(id <GrowlPluginHandler>)handler forPluginTypes:(NSSet *)extensions {
	NSParameterAssert(handler != nil);

	[allPluginHandlers removeObjectIdenticalTo:handler];

	if (!extensions)
		extensions = (NSSet *)[pluginHandlers allKeysForObject:handler];

	NSEnumerator *extEnum = [extensions objectEnumerator];
	NSString *ext;
	while ((ext = [extEnum nextObject])) {
		NSMutableArray *handlers = [pluginHandlers objectForKey:ext];
		if (handlers) {
			unsigned idx = [handlers indexOfObjectIdenticalTo:handler];
			if (idx != NSNotFound)
				[handlers removeObjectAtIndex:idx];
		}
	}
}

- (NSArray *) allPluginHandlers {
	return [[allPluginHandlers copy] autorelease];
}

#pragma mark -

//private method.
- (NSDictionary *) addPluginInstance:(GrowlPlugin *)plugin fromPath:(NSString *)path bundle:(NSBundle *)bundle {
	NSString *identifier = nil;
	if (plugin)
		identifier = [pluginIdentifiersByInstance objectForKey:plugin];
	else if (bundle)
		identifier = [pluginIdentifiersByBundle   objectForKey:bundle];
	else if (path)
		identifier = [pluginIdentifiersByPath     objectForKey:path];

	NSMutableDictionary *pluginDict = identifier ? [pluginsByIdentifier objectForKey:identifier] : nil;
	if (pluginDict && !plugin)
		plugin = [pluginDict pluginInstance];

	NSAssert1(plugin || bundle, @"Cannot load plug-ins lazily without a bundle (path: %@)", path);

	NSString *name    = plugin ? [plugin name]    : [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
	NSString *author  = plugin ? [plugin author]  : [bundle objectForInfoDictionaryKey:GrowlPluginInfoKeyAuthor];
	NSString *version = plugin ? [plugin version] : [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
	if (!path)
		path = [bundle bundlePath];

	NSAssert5((name != nil) && (author != nil) && (version != nil),
			  @"Cannot load plug-in at path %@ (plug-in instance's class: %@). One of these is (null), but they must all not be:\n"
			  @"\t"@"   name: %@\n"
			  @"\t"@" author: %@\n"
			  @"\t"@"version: %@\n",
			  path, [plugin class], name, author, version);

	//just in case the plug-in instance gives us a mutable string for some reason.
	name    = [name    copy];
	author  = [author  copy];
	version = [version copy];

	if (!identifier)
		identifier = [NSString stringWithFormat:@"Name: %@ Author: %@ Path: %@", name, author, path];
	
	if (!plugin && bundle) {
		if (![bundlesToLazilyInstantiateAnInstanceFrom containsObject:bundle])
			[bundlesToLazilyInstantiateAnInstanceFrom addObject:bundle];
		else {
			plugin = [[[bundle principalClass] alloc] init];
			[bundlesToLazilyInstantiateAnInstanceFrom removeObject:bundle];
			[pluginDict setObject:plugin forKey:GrowlPluginInfoKeyInstance];
		}
	}

	if (!pluginDict) {
		pluginDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			name,                 GrowlPluginInfoKeyName,
			author,               GrowlPluginInfoKeyAuthor,
			version,              GrowlPluginInfoKeyVersion,
			path,                 GrowlPluginInfoKeyPath,
			nil];
		NSString *description = [plugin description];
		if (description)
			[pluginDict setObject:description forKey:GrowlPluginInfoKeyDescription];

		NSString *extension = [path pathExtension];
		NSString *fileType = nil;
		[[NSWorkspace sharedWorkspace] getFileType:&fileType creatorCode:NULL forFile:path];

		NSSet *types;
		if (extension) {
#warning when there is no file type it is coming back as \'\'...im guessing this means no type, but it still tests as true so each plugin is registered against that type...wrong???
			if (fileType)
				types = [NSSet setWithObjects:extension, fileType, nil];
			else
				types = [NSSet setWithObject:extension];
		} else if (fileType)
			types = [NSSet setWithObject:fileType];
		[pluginDict setObject:types forKey:GrowlPluginInfoKeyTypes];

		[pluginsByIdentifier setObject:pluginDict forKey:identifier];
		[pluginIdentifiersByPath setObject:identifier forKey:path];
			
	#define ADD_TO_DICT(dictName, key, value)                                          \
			do {                                                                        \
				NSMutableSet *plugins = [dictName objectForKey:key];                     \
				if (plugins)                                                              \
					[plugins addObject:value];                                             \
				else                                                                        \
					[dictName setObject:[NSMutableSet setWithObject:value] forKey:key];      \
			} while(0)
		ADD_TO_DICT(pluginsByName,     name,                     pluginDict);
		ADD_TO_DICT(pluginsByAuthor,   author,                   pluginDict);
		ADD_TO_DICT(pluginsByVersion,  version,                  pluginDict);
		ADD_TO_DICT(pluginsByFilename, [path lastPathComponent], pluginDict);
		
		ADD_TO_DICT(pluginsByType, extension, pluginDict);
		ADD_TO_DICT(pluginsByType, fileType,  pluginDict); 
	#undef ADD_TO_DICT
	}
	
	if (bundle) {
		if (![pluginDict objectForKey:GrowlPluginInfoKeyBundle])
			[pluginDict setObject:bundle forKey:GrowlPluginInfoKeyBundle];
		[pluginIdentifiersByBundle setObject:identifier forKey:bundle];
	}
	if (plugin) {
		if (![pluginDict objectForKey:GrowlPluginInfoKeyInstance])
			[pluginDict setObject:plugin forKey:GrowlPluginInfoKeyInstance];
		[pluginIdentifiersByInstance setObject:identifier forKey:plugin];
	}

	//release our copies.
	[name    release];
	[author  release];
	[version release];

	//invalidate non-display plug-in caches.
	[cache_allPlugins release];
	 cache_allPlugins = nil;
	[cache_allPluginsArray release];
	 cache_allPluginsArray = nil;
	[cache_registeredPluginTypes release];
	 cache_registeredPluginTypes = nil;
	[cache_registeredPluginNames release];
	 cache_registeredPluginNames = nil;
	[cache_registeredPluginNamesArray release];
	 cache_registeredPluginNamesArray = nil;

	if ([self pluginWithDictionaryIsDisplayPlugin:pluginDict]) {
		[displayPlugins addObject:pluginDict];

		//invalidate display plug-in cache.
		[cache_displayPlugins release];
		 cache_displayPlugins = nil;
	}

	return pluginDict;
}

- (NSDictionary *) addPluginInstance:(GrowlPlugin *)plugin fromBundle:(NSBundle *)bundle {
	return [self addPluginInstance:plugin fromPath:nil bundle:bundle];
}
- (NSDictionary *) addPluginInstance:(GrowlPlugin *)plugin fromPath:(NSString *)path {
	return [self addPluginInstance:plugin fromPath:path bundle:nil];
}

#pragma mark -

- (NSSet *) registeredPluginTypes {
	if (!cache_registeredPluginTypes)
		cache_registeredPluginTypes = [[NSSet alloc] initWithArray:[pluginHandlers allKeys]];

	return cache_registeredPluginTypes;
}

- (NSSet *) registeredPluginNames {
	if (!cache_registeredPluginNames)
		cache_registeredPluginNames = [[NSSet alloc] initWithArray:[self registeredPluginNamesArray]];
	return cache_registeredPluginNames;
}
- (NSArray *) registeredPluginNamesArray {
	if (!cache_registeredPluginNamesArray) {
		cache_registeredPluginNamesArray = [[[pluginsByIdentifier allValues] valueForKey:GrowlPluginInfoKeyName] retain];
	}
	return cache_registeredPluginNamesArray;
}

- (NSArray *) registeredPluginNamesArrayForType:(NSString *)type {
#warning this should be cached per type
	return [[[pluginsByType valueForKey:type] allObjects] valueForKey:GrowlPluginInfoKeyName];
}


#pragma mark -

- (NSArray *) allPluginDictionariesArray {
	if (!cache_allPluginsArray)
		cache_allPluginsArray = [[pluginsByIdentifier allValues] copy];
	return cache_allPluginsArray;
}
- (NSSet *) allPluginDictionaries {
	if (!cache_allPlugins)
		cache_allPlugins = [[NSMutableSet alloc] initWithArray:[self allPluginDictionariesArray]];
	return cache_allPlugins;
}
- (NSArray *) allPluginInstances {
	if (!cache_allPluginInstances)
		cache_allPluginInstances = [[[self allPluginDictionaries] valueForKey:GrowlPluginInfoKeyInstance] retain];
	return cache_allPluginInstances;
}

- (NSSet *) pluginDictionariesWithName:(NSString *)name author:(NSString *)author version:(NSString *)version type:(NSString *)type {
	NSMutableSet *matches = [[[self allPluginDictionaries] mutableCopy] autorelease];

#warning this is an extremely strange problem. objectForKey returns a set but if you use it directly intersetSet returns an empty set.  the only way i could make this work was to wrap it in another set and use that.  I spent 2 hours trying to work this out so for now Ill just move on.  jkp.
	if ([matches count]) {
		if (name)
			[matches intersectSet:[NSSet setWithSet:[pluginsByName objectForKey:name]]];
		if (author)
			[matches intersectSet:[NSSet setWithSet:[pluginsByAuthor objectForKey:author]]];
		if (version)
			[matches intersectSet:[NSSet setWithSet:[pluginsByVersion objectForKey:version]]];
		if (type)
			[matches intersectSet:[NSSet setWithSet:[pluginsByType objectForKey:type]]];
	}

	return matches;
}
- (NSDictionary *) pluginDictionaryWithName:(NSString *)name author:(NSString *)author version:(NSString *)version type:(NSString *)type {
	NSSet *matches = [self pluginDictionariesWithName:name author:author version:version type:type];
	if([matches count] == 1U)
		return [matches anyObject];
	else
		return nil;
}
- (NSDictionary *) pluginDictionaryWithName:(NSString *)name {
	return [self pluginDictionaryWithName:name author:nil version:nil type:nil];
}
- (GrowlPlugin *) pluginInstanceWithName:(NSString *)name author:(NSString *)author version:(NSString *)version type:(NSString *)type {
	NSDictionary *pluginDict = [self pluginDictionaryWithName:name author:author version:version type:type];
	GrowlPlugin *instance = [pluginDict pluginInstance];
	if (!instance) {
		NSBundle *bundle = [pluginDict pluginBundle];
		if (bundle) {
			[self addPluginInstance:nil fromBundle:bundle]; //causes instantiation
			instance = [pluginDict pluginInstance];
		}
	}
	return instance;
}
- (GrowlPlugin *) pluginInstanceWithName:(NSString *)name {
	return [self pluginInstanceWithName:name author:nil version:nil type:nil];
}

#pragma mark -

- (NSString *) humanReadableNameForPluginWithDictionary:(NSDictionary *)pluginDict {
	NSString *humanReadableName = [pluginDict pluginHumanReadableName];

	if (!humanReadableName) {
		NSString *name = [pluginDict pluginName];
		if ([[pluginsByName objectForKey:name] count] == 1U)
			humanReadableName = name;
		else {
			NSString *author = [pluginDict pluginAuthor];
			if ([[pluginsByAuthor objectForKey:author] count] == 1U)
				humanReadableName = [NSString stringWithFormat:@"%@ (by %@)", name, author]; //XXX LOCALIZEME
			else {
				NSString *filename = [[pluginDict pluginPath] lastPathComponent];
				if ([[pluginsByFilename objectForKey:filename] count] == 1U)
					humanReadableName = [NSString stringWithFormat:@"%@ (filename %@)", name, filename]; //XXX LOCALIZEME
				else {
					humanReadableName = [NSString stringWithFormat:@"%@ (by %@, filename %@)", name, author, filename]; //XXX LOCALIZEME
					unsigned count = [pluginHumanReadableNames countForObject:humanReadableName];
					[pluginHumanReadableNames addObject:humanReadableName];
					if (count > 1U)
						humanReadableName = [NSString stringWithFormat:@"%@ %u", humanReadableName, count];
				}
			}
		}

		if ([pluginDict isKindOfClass:[NSMutableDictionary class]]) {
			//save the name for later retrieval.
			[(NSMutableDictionary *)pluginDict setObject:humanReadableName forKey:GrowlPluginInfoKeyHumanReadableName];
		}
	}

	return humanReadableName;
}

- (BOOL) pluginWithDictionaryIsDisplayPlugin:(NSDictionary *)pluginDict {
	GrowlPlugin *instance = [pluginDict pluginInstance];
	if (instance)
		return [instance isKindOfClass:[GrowlDisplayPlugin class]];
	else {
		NSBundle *bundle = [pluginDict pluginBundle];
		NSAssert1(bundle, @"no instance or bundle in plug-in dictionary! description of dictionary follows\n%@", pluginDict);
		Class principalClass = [bundle principalClass];
		NSAssert1(bundle, @"bundle in plug-in dictionary has no principal class! description of dictionary follows\n%@", pluginDict);
		return [principalClass isSubclassOfClass:[GrowlDisplayPlugin class]];
	}
}

#pragma mark -
#warning XXX all of this could potentially go bye-bye if it is not needed

- (NSArray *) displayPlugins {
	if (!cache_displayPlugins)
		cache_displayPlugins = [[NSArray alloc] initWithArray:displayPlugins];
	return cache_displayPlugins;
}

#pragma mark -

- (NSSet *) displayPluginDictionariesWithName:(NSString *)name author:(NSString *)author version:(NSString *)version type:(NSString *)type {
	NSMutableSet *matches = (NSMutableSet *)[self pluginDictionariesWithName:name
																	  author:author
																	 version:version
																		type:type];

	NSSet *copyForIteration = [matches copy];
	NSEnumerator *matchesEnum = [copyForIteration objectEnumerator];
	NSDictionary *pluginDict;
	while ((pluginDict = [matchesEnum nextObject])) {
		if (![self pluginWithDictionaryIsDisplayPlugin:pluginDict])
			[matches removeObject:pluginDict];
	}

	return matches;
}
- (NSDictionary *) displayPluginDictionaryWithName:(NSString *)name author:(NSString *)author version:(NSString *)version type:(NSString *)type {
	NSSet *matches = [self displayPluginDictionariesWithName:name
													  author:author
													 version:version
														type:type];
	if ([matches count] == 1U)
		return [matches anyObject];
	else
		return nil;
}
- (GrowlDisplayPlugin *) displayPluginInstanceWithName:(NSString *)name author:(NSString *)author version:(NSString *)version type:(NSString *)type {
	GrowlPlugin *plugin = [self pluginInstanceWithName:name author:author version:version type:type];
	if (plugin && [plugin isKindOfClass:[GrowlDisplayPlugin class]])
		return (GrowlDisplayPlugin *)plugin;
	else
		return nil;
}

#pragma mark -
#pragma mark Finding and using installed plug-ins

- (void) findPluginsInDirectory:(NSString *)dir {
	NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:dir];
	NSString *file;
	while ((file = [enumerator nextObject])) {
		NSString *fullPath = [dir stringByAppendingPathComponent:file];

		NSString *pathExtension = [file pathExtension];
		NSString *fileType;
		[[NSWorkspace sharedWorkspace] getFileType:&fileType creatorCode:NULL forFile:fullPath];
		if ([pluginHandlers objectForKey:pathExtension] || (fileType && [pluginHandlers objectForKey:fileType])) {
			[self dispatchPluginAtPath:fullPath];
			[enumerator skipDescendents];
		}
	}
}

- (void) dispatchPluginAtPath:(NSString *)path {
	//get all the relevant handlers, by extension and by type.
	NSArray *handlersByExtension = [pluginHandlers objectForKey:[path pathExtension]];
	NSString *fileType;
	[[NSWorkspace sharedWorkspace] getFileType:&fileType creatorCode:NULL forFile:path];
	NSArray *handlersByType      = [pluginHandlers objectForKey:fileType];

	//strip duplicates by making a set from both arrays.
	NSMutableSet *allMatchingHandlersSet = handlersByExtension ? [NSMutableSet setWithArray:handlersByExtension] : [NSMutableSet set];
	if (handlersByType)
		[allMatchingHandlersSet unionSet:[NSSet setWithArray:handlersByType]];

	NSMutableArray *allMatchingHandlers = [[allMatchingHandlersSet allObjects] mutableCopy];
	[allMatchingHandlers sortUsingFunction:comparePluginHandlerRegistrationOrder context:self];

	NSBundle *pluginBundle = [[NSBundle alloc] initWithPath:path];

	NSEnumerator *handlersEnum = [allMatchingHandlers objectEnumerator];
	id <GrowlPluginHandler> handler;
	while ((handler = [handlersEnum nextObject])) {
		BOOL success = NO;
		if (pluginBundle && [handler respondsToSelector:@selector(loadPluginWithBundle:)])
			success = (unsigned)[handler performSelector:@selector(loadPluginWithBundle:) withObject:pluginBundle];
		else if ([handler respondsToSelector:@selector(loadPluginAtPath:)])
			success = (unsigned)[handler performSelector:@selector(loadPluginAtPath:) withObject:path];
		else if ([handler respondsToSelector:@selector(loadPluginAtURL:)])
			success = (unsigned)[handler performSelector:@selector(loadPluginAtURL:) withObject:[NSURL fileURLWithPath:path]];
		else
			NSLog(@"warning: while loading plug-in at %@, tried to use plug-in handler %@, but it appears incapable of handling a plug-in", path, handler); //XXX should do this diagnostic when adding the handler
	}

	[pluginBundle release];
}

#pragma mark -
#pragma mark Installing plug-ins

- (void) pluginInstalledSelector:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
#pragma unused(sheet, contextInfo)
	if (returnCode == NSAlertAlternateReturn) {
		NSBundle *prefPane = [GrowlPathUtilities growlPrefPaneBundle];

		if (prefPane && ![[NSWorkspace sharedWorkspace] openFile:[prefPane bundlePath]])
			NSLog(@"Could not open Growl PrefPane");
	}
}

- (void) pluginExistsSelector:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
#pragma unused(sheet)
	NSString *filename = (NSString *)contextInfo;

	if (returnCode == NSAlertAlternateReturn) {
		//'Yes' to 'Do you want to overwrite [the installed plug-in with the version you double-clicked]?'
		NSString *pluginFile = [filename lastPathComponent];
		NSString *destination = [[NSHomeDirectory()
			stringByAppendingPathComponent:@"Library/Application Support/Growl/Plugins"]
			stringByAppendingPathComponent:pluginFile];
		NSFileManager *fileManager = [NSFileManager defaultManager];

		// first remove old copy if present
		[fileManager removeFileAtPath:destination handler:nil];

		// copy new version to destination
		if ([fileManager copyPath:filename toPath:destination handler:nil]) {
			[self dispatchPluginAtPath:destination];
			[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
			NSBeginInformationalAlertSheet( NSLocalizedString( @"Plugin installed", @"" ),
											NSLocalizedString( @"No",  @"" ),
											NSLocalizedString( @"Yes", @"" ),
											nil, nil, self,
											@selector(pluginInstalledSelector:returnCode:contextInfo:),
											NULL, NULL,
											NSLocalizedString( @"Plugin '%@' has been installed successfully. Do you want to configure it now?", @"" ),
											[pluginFile stringByDeletingPathExtension] );
		} else {
			[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
			NSBeginCriticalAlertSheet( NSLocalizedString( @"Plugin not installed", @"" ),
									   NSLocalizedString( @"OK", @"" ),
									   nil, nil, nil, self, NULL, NULL, NULL,
									   NSLocalizedString( @"There was an error while installing the plugin '%@'.", @"" ),
									   [pluginFile stringByDeletingPathExtension] );
		}
	}

	[filename release];
}

- (void) installPluginFromPath:(NSString *)filename {
	NSString *pluginFile = [filename lastPathComponent];
	NSString *destination = [[NSHomeDirectory()
		stringByAppendingPathComponent:@"Library/Application Support/Growl/Plugins"]
		stringByAppendingPathComponent:pluginFile];
	// retain a copy of the filename because it is passed as context to the sheetDidEnd selectors
	NSString *filenameCopy = [[NSString alloc] initWithString:filename];

	if ([[NSFileManager defaultManager] fileExistsAtPath:destination]) {
		// plugin already exists at destination
		[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
		NSBeginAlertSheet( NSLocalizedString( @"Plugin already exists", @"" ),
						   NSLocalizedString( @"No", @"" ),
						   NSLocalizedString( @"Yes", @"" ), nil, nil, self,
						   NULL, @selector(pluginExistsSelector:returnCode:contextInfo:),
						   filenameCopy,
						   NSLocalizedString( @"Plugin '%@' is already installed, do you want to overwrite it?", @"" ),
						   [pluginFile stringByDeletingPathExtension] );
	} else {
		[self pluginExistsSelector:nil returnCode:NSAlertAlternateReturn contextInfo:filenameCopy];
	}
}

@end

static Boolean caseInsensitiveStringComparator(const void *value1, const void *value2) {
	Class NSStringClass = [NSString class];
	return [(id)value1 isKindOfClass:NSStringClass] \
	    && [(id)value2 isKindOfClass:NSStringClass]  \
	    && ([(NSString *)value1 caseInsensitiveCompare:(NSString *)value2] == NSOrderedSame);
}

static CFHashCode passthroughStringHash(const void *value) {
	return [[(NSString *)value lowercaseString] hash];
}

#pragma mark -

@implementation NSDictionary (GrowlPluginKeys)

- (NSString *) pluginName {
	return [self objectForKey:GrowlPluginInfoKeyName];
}
- (NSString *) pluginAuthor {
	return [self objectForKey:GrowlPluginInfoKeyAuthor];
}
- (NSString *) pluginDescription {
	return [self objectForKey:GrowlPluginInfoKeyDescription];
}
- (NSString *) pluginVersion {
	return [self objectForKey:GrowlPluginInfoKeyVersion];
}
- (NSBundle *) pluginBundle {
	return [self objectForKey:GrowlPluginInfoKeyBundle];
}
- (NSString *) pluginPath {
	return [self objectForKey:GrowlPluginInfoKeyPath];
}
- (NSSet *) pluginTypes {
	return [self objectForKey:GrowlPluginInfoKeyTypes];
}
- (NSString *) pluginHumanReadableName {
	return [self objectForKey:GrowlPluginInfoKeyHumanReadableName];
}
- (NSString *) pluginIdentifier {
	return [self objectForKey:GrowlPluginInfoKeyIdentifier];
}
- (GrowlPlugin *) pluginInstance {
	return [self objectForKey:GrowlPluginInfoKeyInstance];
}

@end

#define ASSERT_IN_FUNCTION(condition, desc, ...)                                                      \
	[[NSAssertionHandler currentHandler] handleFailureInFunction:[NSString stringWithCString:__func__] \
															file:[NSString stringWithCString:__FILE__]  \
													  lineNumber:__LINE__                                \
													 description:desc, __VA_ARGS__];

int comparePluginHandlerRegistrationOrder(id a, id b, void *context) {
	GrowlPluginController *self = (GrowlPluginController *)context;
	NSArray *allPluginHandlers = [self allPluginHandlers];

	unsigned aIndex = [allPluginHandlers indexOfObjectIdenticalTo:a];
	unsigned bIndex = [allPluginHandlers indexOfObjectIdenticalTo:b];

	ASSERT_IN_FUNCTION(aIndex != NSNotFound, @"Attempted to compare two plug-in handlers, but the first object was not a (registered) plug-in handler! Description of object: %@", a);
	ASSERT_IN_FUNCTION(bIndex != NSNotFound, @"Attempted to compare two plug-in handlers, but the second object was not a (registered) plug-in handler! Description of object: %@", b);

	if(aIndex < bIndex)
		return NSOrderedAscending;
	else if(aIndex > bIndex)
		return NSOrderedDescending;
	else
		return NSOrderedSame;
}
