//
//  GTPController.m
//  GrowlTunes
//
//  Created by Rudy Richter on 9/27/09.
//  Copyright 2009 The Growl Project. All rights reserved.
//

#import "GTPController.h"

@implementation GTPController

@synthesize settings = _settings;
@synthesize notification = _notification;
@synthesize keyCombo = _keyCombo;

- (void)setup
{
	NSString *privateFrameworksPath = [[NSBundle bundleForClass:[self class]] privateFrameworksPath];
	NSString *ShortcutRecorderPath = [privateFrameworksPath stringByAppendingPathComponent:@"ShortcutRecorder.framework"];
	NSString *GrowlPath = [privateFrameworksPath stringByAppendingPathComponent:@"Growl.framework"];
	
	[[NSBundle bundleWithPath:ShortcutRecorderPath] load];
	[[NSBundle bundleWithPath:GrowlPath] load];
	
	NSInteger keyCode = -1;
	NSInteger modifiers = -1;
	
	//read the settings
	[self setSettings:[[[NSUserDefaults standardUserDefaults] persistentDomainForName:GTPBundleIdentifier] mutableCopy]];
	if(![self settings])
	{
		NSMutableDictionary *settings = [NSMutableDictionary dictionary];
		[settings setValue:[NSNumber numberWithInteger:40] forKey:GTPKeyCode];
		[settings setValue:[NSNumber numberWithInteger:(cmdKey | shiftKey)] forKey:GTPModifiers];
		[settings setValue:mDefaultTitleFormat forKey:@"titleString"];
		[settings setValue:mDefaultMessageFormat forKey:@"descriptionString"];
		[self setSettings:settings];
		[[NSUserDefaults standardUserDefaults] setPersistentDomain:[self settings] forName:GTPBundleIdentifier];
		
	}
	keyCode = [[[self settings] valueForKey:GTPKeyCode] integerValue];
	modifiers = [[[self settings] valueForKey:GTPModifiers] integerValue];
	
	//configure the hotkey
	_keyCombo = [[SGKeyCombo alloc] initWithKeyCode:keyCode modifiers:modifiers];
	SGHotKey *hotKey = [[[SGHotKey alloc] initWithIdentifier:GTPBundleIdentifier keyCombo:_keyCombo target:self action:@selector(showCurrentTrack:)] autorelease];
	[[SGHotKeyCenter sharedCenter] registerHotKey:hotKey];
	
	//setup growl
	[NSClassFromString(@"GrowlApplicationBridge") setGrowlDelegate:self];

	[self setNotification:[GTPNotification notification]];
	
	[[self notification] setTitleFormat:[[self settings] objectForKey:@"titleString"]];
	[[self notification] setDescriptionFormat:[[self settings] objectForKey:@"descriptionString"]];


	//configure the plugins
	archivePlugin = nil;
	plugins = [[self loadPlugins] retain];
	NSLog(@"plugins: %@\n", plugins);
}

- (void)showCurrentTrack:(id)sender
{
#pragma unused(sender)
	NSDictionary *noteDict = [[self notification] dictionary];

	[GrowlApplicationBridge notifyWithDictionary:noteDict];
}

- (void)showSettingsWindow
{	
	if(!_settingsWindow)
		_settingsWindow = [[GTPSettingsWindowController alloc] initWithWindowNibName:@"Settings"];
	[_settingsWindow setDelegate:self];
	[_settingsWindow setKeyCombo:_keyCombo];
	[_settingsWindow showWindow:self];
	
}

- (NSData*)artworkForTitle:(NSString *)track byArtist:(NSString *)artist onAlbum:(NSString *)album composedBy:(NSString*)composer isCompilation:(BOOL)compilation
{
	NSLog(@"artworkForTitle: %@ %@ %@ %@ %d", track, artist, album, composer, compilation);
	NSData *result;
	NSImage *artwork = nil;
	
	NSEnumerator *pluginEnum = [plugins objectEnumerator];
	id <GrowlTunesPlugin> plugin;
	while (!artwork && (plugin = [pluginEnum nextObject])) {
		artwork = [plugin artworkForTitle:track
								 byArtist:artist
								  onAlbum:album
							   composedBy:composer
							isCompilation:compilation];
		NSLog(@"plugin: %@ %@", plugin, artwork);
		if (artwork && [plugin usesNetwork])
			[archivePlugin archiveImage:artwork	track:track artist:artist album:album composer:composer compilation:compilation];
	}	
	//NSLog(@"plugin: %@ %@", plugin, artwork);
	result = [artwork TIFFRepresentation];
	return [result autorelease];
}

#pragma mark GrowlApplicationBridgeDelegate

- (NSDictionary *)registrationDictionaryForGrowl 
{
	NSArray	*allNotes = [[NSArray alloc] initWithObjects:
						 ITUNES_TRACK_CHANGED,
						 ITUNES_PLAYING,
						 nil];
	
	NSDictionary *readableNames = [NSDictionary dictionaryWithObjectsAndKeys:
								   NSLocalizedString(@"Changed Tracks", nil), ITUNES_TRACK_CHANGED,
								   NSLocalizedString(@"Started Playing", nil), ITUNES_PLAYING,
								   nil];
	
	NSImage			*iTunesIcon = [[NSWorkspace sharedWorkspace] iconForApplication:ITUNES_APP_NAME];
	NSDictionary	*regDict = [NSDictionary dictionaryWithObjectsAndKeys:
								APP_NAME,                        GROWL_APP_NAME,
								[iTunesIcon TIFFRepresentation], GROWL_APP_ICON,
								allNotes,                        GROWL_NOTIFICATIONS_ALL,
								allNotes,                        GROWL_NOTIFICATIONS_DEFAULT,
								readableNames,					 GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES,
								nil];
	[allNotes release];
	return regDict;
}

- (NSString *)applicationNameForGrowl 
{
	return APP_NAME;
}

#pragma mark GTPSettingsWindowController Delegate
- (void)keyComboChanged:(SGKeyCombo*)newCombo
{
	[self setKeyCombo:newCombo];
	
	SGHotKey *hotKey = [[[SGHotKey alloc] initWithIdentifier:GTPBundleIdentifier keyCombo:newCombo target:self action:@selector(showCurrentTrack:)] autorelease];
	[[SGHotKeyCenter sharedCenter] registerHotKey:hotKey];
}

- (void)titleStringChanged:(NSString*)newTitle
{
	
}

- (void)descriptionStringChanged:(NSString*)newDescription
{
	
}

#pragma mark Plug-ins

// This function is used to sort plugins, trying first the local ones, and then the network ones
static int comparePlugins(id <GrowlTunesPlugin> plugin1, id <GrowlTunesPlugin> plugin2, void *context) {
#pragma unused(context)
	BOOL b1 = [plugin1 usesNetwork];
	BOOL b2 = [plugin2 usesNetwork];
	if (b2 && !b1) //b1 is local; b2 is network
		return NSOrderedAscending;
	else if (b1 && !b2) //b1 is network; b2 is local
		return NSOrderedDescending;
	else //both have the same behaviour
		return NSOrderedAscending;
}

- (NSMutableArray *) loadPlugins {
	NSMutableArray *newPlugins = [[NSMutableArray alloc] init];
	NSMutableArray *lastPlugins = [[NSMutableArray alloc] init];
	if (newPlugins) {
		NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
		NSString *pluginsPath = [myBundle builtInPlugInsPath];
		NSString *applicationSupportPath = [@"~/Library/Application Support/GrowlTunes/Plugins" stringByExpandingTildeInPath];
		NSArray *loadPathsArray = [NSArray arrayWithObjects:pluginsPath, applicationSupportPath, nil];
		NSEnumerator *loadPathsEnum = [loadPathsArray objectEnumerator];
		NSString *loadPath;
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		static NSString *pluginPathExtension = @"plugin";
		
		while ((loadPath = [loadPathsEnum nextObject])) {
			//NSLog(@"loadPath: %@\n", loadPath);
			NSEnumerator *pluginEnum = [[[NSFileManager defaultManager] directoryContentsAtPath:loadPath] objectEnumerator];
			NSString *curPath;
			
			while ((curPath = [pluginEnum nextObject])) {
				//NSLog(@"currentPath: %@\n", curPath);
				if ([[curPath pathExtension] isEqualToString:pluginPathExtension]) {
					curPath = [pluginsPath stringByAppendingPathComponent:curPath];
					NSBundle *plugin = [NSBundle bundleWithPath:curPath];
					
					if ([plugin load]) {
						Class principalClass = [plugin principalClass];
						
						if ([principalClass conformsToProtocol:@protocol(GrowlTunesPlugin)]) {
							id instance = [[principalClass alloc] init];
							[newPlugins addObject:instance];
							
							if (!archivePlugin && ([principalClass conformsToProtocol:@protocol(GrowlTunesPluginArchive)])) {
								archivePlugin = [instance retain];
																//NSLog(@"plug-in %@ is archive-Plugin with id %p", [curPath lastPathComponent], instance);
							}
							[instance release];
														//NSLog(@"Loaded plug-in \"%@\" with id %p", [curPath lastPathComponent], instance);
						} else
							NSLog(@"Loaded plug-in \"%@\" does not conform to protocol", [curPath lastPathComponent]);
					} else
						NSLog(@"Could not load plug-in \"%@\"", [curPath lastPathComponent]);
				}
			}
		}
		
		[pool release];
		[newPlugins addObjectsFromArray:lastPlugins];
		[lastPlugins release];
		[newPlugins autorelease];
	}
	
	// sort the plugins, putting the one that uses network last
	return (NSMutableArray *)[newPlugins sortedArrayUsingFunction:comparePlugins context:NULL];
}

@end

@implementation NSObject(GrowlTunesDummyPlugin)

- (NSImage *) artworkForTitle:(NSString *)track
					 byArtist:(NSString *)artist
					  onAlbum:(NSString *)album
				isCompilation:(BOOL)compilation
{
#pragma unused(track,artist,album,compilation)
	NSLog(@"Dummy plug-in %p called for artwork", self);
	return nil;
}

@end
