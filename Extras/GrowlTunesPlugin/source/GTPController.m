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

/*
 Name: setupTitleString
 Function: configures the title string to be used by the notification based on the user's selected
 display settings and the information that is available from iTunes for the new track
 *
static void setupTitleString(const VisualPluginData *visualPluginData, CFMutableStringRef title)
{
	GrowlLog("%s entered", __FUNCTION__);
	CFStringDelete(title, CFRangeMake(0, CFStringGetLength(title)));
	if (visualPluginData->trackInfo.validFields & kITTINameFieldMask && gTrackFlag) 
	{
		if (visualPluginData->trackInfo.trackNumber > 0) 
		{
			if ((visualPluginData->trackInfo.numDiscs > 1) && gDiscFlag)
				CFStringAppendFormat(title, NULL, CFSTR("%d-"), visualPluginData->trackInfo.discNumber);
			CFStringAppendFormat(title, NULL, CFSTR("%d. "), visualPluginData->trackInfo.trackNumber);
		}
		CFStringAppendCharacters(title, &visualPluginData->trackInfo.name[1], visualPluginData->trackInfo.name[0]);
	}
	GrowlLog("%s exited", __FUNCTION__);
}

/*
 Name: setupDescString
 Function: configures the description string to be used by the notification based on the user's selected
 display settings and the information that is available from iTunes for the new track
 *
static void setupDescString(const VisualPluginData *visualPluginData, CFMutableStringRef desc)
{
	GrowlLog("%s entered", __FUNCTION__);
	CFStringRef album;
	CFStringRef artist;
	CFStringRef genre;
	CFStringRef	totalTime;
	CFStringRef rating;
	CFMutableStringRef tmp;
	
	CFMutableStringRef test = CFStringCreateMutable(kCFAllocatorDefault, 0);
	CFStringAppendCharacters(test, &visualPluginData->streamInfo.streamTitle[1], visualPluginData->streamInfo.streamTitle[0]);
	CFStringAppendCharacters(test, &visualPluginData->streamInfo.streamURL[1], visualPluginData->streamInfo.streamURL[0]);
	CFStringAppendCharacters(test, &visualPluginData->streamInfo.streamMessage[1], visualPluginData->streamInfo.streamMessage[0]);
	
	if (!CFStringGetLength(test)) 
	{
		if (visualPluginData->trackInfo.validFields & (kITTIArtistFieldMask|kITTIComposerFieldMask) && (gArtistFlag||gComposerFlag)) 
		{
			tmp = CFStringCreateMutable(kCFAllocatorDefault, 0);
			CFStringAppend(tmp, CFSTR("\n"));
			if (gArtistFlag)
				CFStringAppendCharacters(tmp, &visualPluginData->trackInfo.artist[1], visualPluginData->trackInfo.artist[0]);
			if (visualPluginData->trackInfo.composer[0] && gComposerFlag) 
			{
				CFStringAppend(tmp, CFSTR(" (Composed by "));
				CFStringAppendCharacters(tmp, &visualPluginData->trackInfo.composer[1], visualPluginData->trackInfo.composer[0]);
				CFStringAppend(tmp, CFSTR(")"));
			}
			artist = tmp;
		} 
		else if (visualPluginData->trackInfo.validFields & kITTIArtistFieldMask && gArtistFlag) 
		{
			tmp = CFStringCreateMutable(kCFAllocatorDefault, 0);
			CFStringAppendCharacters(tmp, &visualPluginData->trackInfo.artist[1], visualPluginData->trackInfo.artist[0]);
			artist = tmp;
		} 
		else 
		{
			artist = CFSTR("");
		}
		
		if (visualPluginData->trackInfo.validFields & (kITTIAlbumFieldMask|kITTIYearFieldMask) && (gAlbumFlag||gYearFlag)) 
		{
			tmp = CFStringCreateMutable(kCFAllocatorDefault, 0);
			CFStringAppend(tmp, CFSTR("\n"));
			if (gAlbumFlag) 
			{
				CFStringAppendCharacters(tmp, &visualPluginData->trackInfo.album[1], visualPluginData->trackInfo.album[0]);
				CFStringAppendFormat(tmp, NULL, CFSTR(" "));
			}
			if (gYearFlag)
				if(visualPluginData->trackInfo.year)
					CFStringAppendFormat(tmp, NULL, CFSTR("(%d)"), visualPluginData->trackInfo.year);
			album = tmp;
		} 
		else if (visualPluginData->trackInfo.validFields & kITTIAlbumFieldMask && gAlbumFlag) 
		{
			tmp = CFStringCreateMutable(kCFAllocatorDefault, 0);
			CFStringAppendCharacters(tmp, &visualPluginData->trackInfo.album[1], visualPluginData->trackInfo.album[0]);
			album = tmp;
		} 
		else 
		{
			album = CFSTR("");
		}
		if (visualPluginData->trackInfo.validFields & kITTIGenreFieldMask && gGenreFlag) 
		{
			tmp = CFStringCreateMutable(kCFAllocatorDefault, 0);
			CFStringAppend(tmp, CFSTR("\n"));
			CFStringAppendCharacters(tmp, &visualPluginData->trackInfo.genre[1], visualPluginData->trackInfo.genre[0]);
			genre = tmp;
		} 
		else 
		{
			genre = CFSTR("");
		}
		if (visualPluginData->trackInfo.validFields & kITTITotalTimeFieldMask) 
		{
			int minutes = visualPluginData->trackInfo.totalTimeInMS / 1000 / 60;
			int seconds = visualPluginData->trackInfo.totalTimeInMS / 1000 - minutes * 60;
			totalTime = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("%d:%02d"), minutes, seconds);
		} 
		else 
		{
			totalTime = CFSTR("");
		}
		
		rating = CFSTR("");
		if (gRatingFlag && visualPluginData->trackInfo.trackRating) 
		{
			CFStringRef starsString = createStringForRating(visualPluginData->trackInfo.trackRating, PINWHEEL_STAR);
			if (starsString)
			{
				CFStringRef separator = CFSTR(" - ");
				CFIndex tmpLength = CFStringGetLength(separator) + CFStringGetLength(starsString);
				
				tmp = CFStringCreateMutable(kCFAllocatorDefault, tmpLength);
				CFStringAppend(tmp, separator);
				CFStringAppend(tmp, starsString);
				CFRelease(starsString);
				rating = tmp;
			}
		}
		
		CFStringDelete(desc, CFRangeMake(0, CFStringGetLength(desc)));
		CFStringAppendFormat(desc, NULL, CFSTR("%@%@%@%@%@"), totalTime, rating, artist, album, genre);
		
		if (artist)
			CFRelease(artist);
		if (album)
			CFRelease(album);
		if (totalTime)
			CFRelease(totalTime);
		if (rating)
			CFRelease(rating);
	} 
	else 
	{
		CFStringDelete(desc, CFRangeMake(0, CFStringGetLength(desc)));
		CFStringAppendCharacters(desc, &visualPluginData->streamInfo.streamTitle[1], visualPluginData->streamInfo.streamTitle[0]);
		CFStringAppendFormat(desc, NULL, CFSTR("\n"));
		CFStringAppendCharacters(desc, &visualPluginData->streamInfo.streamURL[1], visualPluginData->streamInfo.streamURL[0]);
		CFStringAppendFormat(desc, NULL, CFSTR("\n"));
		CFStringAppendCharacters(desc, &visualPluginData->streamInfo.streamMessage[1], visualPluginData->streamInfo.streamMessage[0]);
		CFStringAppendFormat(desc, NULL, CFSTR("\n"));
	}
	if (test)
		CFRelease(test);
	GrowlLog("%s exited", __FUNCTION__);
}
*/
@end
