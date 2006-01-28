//  GrowlTunes.c
//  GrowlTunesPlugin
//
//  Created by rudy on 11/27/05.
//  Copyright 2005 The Growl Project. All rights reserved.


/**\
|**|	includes
\**/

#include "iTunesVisualAPI.h"
#include "Growl/Growl.h"

/**\
|**|	typedef's, struct's, enum's, etc.
\**/

#ifndef GROWLTUNES_EXPORT
#define GROWLTUNES_EXPORT __attribute__((visibility("default")))
#endif

#define kTVisualPluginName              "\pGrowlTunes"
#define	kTVisualPluginCreator           'GRWL'

#define	kTVisualPluginMajorVersion		1
#define	kTVisualPluginMinorVersion		0
#define	kTVisualPluginReleaseStage		finalStage
#define	kTVisualPluginNonFinalRelease	0

#define ITUNES_TRACK_CHANGED	CFSTR("Changed Tracks")
#define ITUNES_PAUSED			CFSTR("Paused")
#define ITUNES_STOPPED			CFSTR("Stopped")
#define ITUNES_PLAYING			CFSTR("Started Playing")

enum
{
	kTrackSettingID		= 3,
	kDiscSettingID		= 4,
	kArtistSettingID	= 5,
	kComposerSettingID	= 6,
	kAlbumSettingID		= 7,
	kYearSettingID		= 8,
	kGenreSettingID		= 9,
	kOKSettingID		= 10
};

typedef struct Growl_Delegate Growl_Delegate;
typedef struct Growl_Notification Growl_Notification;
static Growl_Delegate delegate;

typedef Boolean (*GrowlSetDelegateProcPtr)(struct Growl_Delegate *newDelegate);
static GrowlSetDelegateProcPtr GrowlTunes_SetDelegate;

typedef void (*GrowlPostNotificationProcPtr)(const struct Growl_Notification *notification);
static GrowlPostNotificationProcPtr GrowlTunes_PostNotification;

typedef Boolean (*GrowlIsInstalledProcPtr)(void);
static GrowlIsInstalledProcPtr GrowlTunes_GrowlIsInstalled;

typedef struct VisualPluginData {
	void				*appCookie;
	ITAppProcPtr		appProc;

	ITTrackInfo			trackInfo;
	ITStreamInfo		streamInfo;

	Boolean				playing;
	Boolean				padding[3];
} VisualPluginData;

extern CFArrayCallBacks notificationCallbacks;

static Boolean gTrackFlag		= true;
static Boolean gDiscFlag		= true;
static Boolean gArtistFlag		= true;
static Boolean gComposerFlag	= true;
static Boolean gAlbumFlag		= true;
static Boolean gYearFlag		= true;
static Boolean gGenreFlag		= true;

static EventHotKeyRef reNotifyHotKeyRef = NULL;
static EventHandlerRef hotKeyEventHandlerRef = NULL;

/**\
|**|	exported function prototypes
\**/

extern OSStatus iTunesPluginMainMachO(OSType message, PluginMessageInfo *messageInfo, void *refCon);
extern void CFLog(int priority, CFStringRef format, ...);

static OSStatus hotKeyEventHandler(EventHandlerCallRef inHandlerRef, EventRef inEvent, void *refCon);
static pascal OSStatus settingsControlHandler(EventHandlerCallRef inRef, EventRef inEvent, void *userData);
static void setupDescString(const VisualPluginData *visualPluginData, CFMutableStringRef desc);
static void setupTitleString(const VisualPluginData *visualPluginData, CFMutableStringRef title);

/*
	settingsControlHandler
*/
static pascal OSStatus settingsControlHandler(EventHandlerCallRef inRef, EventRef inEvent, void *userData)
{
    WindowRef wind = NULL;
    ControlID controlID;
    ControlRef control = NULL;
	inRef = NULL;
	userData = NULL;
    //get control hit by event
    GetEventParameter(inEvent, kEventParamDirectObject, typeControlRef, NULL, sizeof(ControlRef), NULL, &control);
    wind=GetControlOwner(control);
    GetControlID(control,&controlID);
	char *string = (char *)&controlID.signature;
	CFLog(1, CFSTR("%s %c%c%c%c\n"), __FUNCTION__, string[0], string[1], string[2], string[3]);
    switch (controlID.id){
        case kTrackSettingID:
                gTrackFlag = GetControlValue(control);
                break;
        case kDiscSettingID:
                gDiscFlag = GetControlValue(control);
                break;
        case kArtistSettingID:
                gArtistFlag = GetControlValue(control);
                break;
        case kComposerSettingID:
                gComposerFlag = GetControlValue(control);
                break;
        case kAlbumSettingID:
                gAlbumFlag = GetControlValue(control);
                break;
        case kYearSettingID:
                gYearFlag = GetControlValue(control);
                break;
        case kGenreSettingID:
                gGenreFlag = GetControlValue(control);
                break;
		case kOKSettingID:
                HideWindow(wind);
                break;
    }
    return noErr;
}

static void setupTitleString(const VisualPluginData *visualPluginData, CFMutableStringRef title)
{
	CFStringDelete(title, CFRangeMake(0, CFStringGetLength(title)));
	if (visualPluginData->trackInfo.validFields & kITTINameFieldMask && gTrackFlag) {
		if (visualPluginData->trackInfo.trackNumber > 0) {
			if ((visualPluginData->trackInfo.numDiscs > 1) && gDiscFlag)
				CFStringAppendFormat(title, NULL, CFSTR("%d-"), visualPluginData->trackInfo.discNumber);
			CFStringAppendFormat(title, NULL, CFSTR("%d. "), visualPluginData->trackInfo.trackNumber);
		}
		CFStringAppendCharacters(title, &visualPluginData->trackInfo.name[1], visualPluginData->trackInfo.name[0]);
	}
}

static void setupDescString(const VisualPluginData *visualPluginData, CFMutableStringRef desc)
{
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

	if (!CFStringGetLength(test)) {
		if (visualPluginData->trackInfo.validFields & (kITTIArtistFieldMask|kITTIComposerFieldMask) && (gArtistFlag||gComposerFlag)) {
			tmp = CFStringCreateMutable(kCFAllocatorDefault, 0);
			CFStringAppend(tmp, CFSTR("\n"));
			if (gArtistFlag)
				CFStringAppendCharacters(tmp, &visualPluginData->trackInfo.artist[1], visualPluginData->trackInfo.artist[0]);
			if (visualPluginData->trackInfo.composer[0] && gComposerFlag) {
				CFStringAppend(tmp, CFSTR(" (Composed by "));
				CFStringAppendCharacters(tmp, &visualPluginData->trackInfo.composer[1], visualPluginData->trackInfo.composer[0]);
				CFStringAppend(tmp, CFSTR(")"));
			}
			artist = tmp;
		} else if (visualPluginData->trackInfo.validFields & kITTIArtistFieldMask && gArtistFlag) {
			tmp = CFStringCreateMutable(kCFAllocatorDefault, 0);
			CFStringAppendCharacters(tmp, &visualPluginData->trackInfo.artist[1], visualPluginData->trackInfo.artist[0]);
			artist = tmp;
		} else {
			artist = CFSTR("");
		}
		if (visualPluginData->trackInfo.validFields & (kITTIAlbumFieldMask|kITTIYearFieldMask) && (gAlbumFlag||gYearFlag)) {
			tmp = CFStringCreateMutable(kCFAllocatorDefault, 0);
			CFStringAppend(tmp, CFSTR("\n"));
			if (gAlbumFlag) {
				CFStringAppendCharacters(tmp, &visualPluginData->trackInfo.album[1], visualPluginData->trackInfo.album[0]);
				CFStringAppendFormat(tmp, NULL, CFSTR(" "));
			}
			if (gYearFlag)
				CFStringAppendFormat(tmp, NULL, CFSTR("(%d)"), visualPluginData->trackInfo.year);
			album = tmp;
		} else if (visualPluginData->trackInfo.validFields & kITTIAlbumFieldMask && gAlbumFlag) {
			tmp = CFStringCreateMutable(kCFAllocatorDefault, 0);
			CFStringAppendCharacters(tmp, &visualPluginData->trackInfo.album[1], visualPluginData->trackInfo.album[0]);
			album = tmp;
		} else {
			album = CFSTR("");
		}
		if (visualPluginData->trackInfo.validFields & kITTIGenreFieldMask && gGenreFlag) {
			tmp = CFStringCreateMutable(kCFAllocatorDefault, 0);
			CFStringAppend(tmp, CFSTR("\n"));
			CFStringAppendCharacters(tmp, &visualPluginData->trackInfo.genre[1], visualPluginData->trackInfo.genre[0]);
			genre = tmp;
		} else {
			genre = CFSTR("");
		}
		if (visualPluginData->trackInfo.validFields & kITTITotalTimeFieldMask) {
			int minutes = visualPluginData->trackInfo.totalTimeInMS / 1000 / 60;
			int seconds = visualPluginData->trackInfo.totalTimeInMS / 1000 - minutes * 60;
			totalTime = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("%d:%02d - "), minutes, seconds);
		} else {
			totalTime = CFSTR("");
		}

		UniChar star = 0x272F;
		UniChar dot = 0x00B7;
		rating = CFSTR("");
		UniChar buf[5] = {dot,dot,dot,dot,dot};

		switch (visualPluginData->trackInfo.userRating) {
			case 100:
				buf[4] = star;
			case 80:
				buf[3] = star;
			case 60:
				buf[2] = star;
			case 40:
				buf[1] = star;
			case 20:
				buf[0] = star;
		}
		tmp = CFStringCreateMutable(kCFAllocatorDefault, 0);
		CFStringAppendCharacters(tmp, buf, 5);
		rating = tmp;

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
	} else {
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
}

static OSStatus VisualPluginHandler(OSType message, VisualPluginMessageInfo *messageInfo, void *refCon)
{
	OSStatus         err = noErr;
	VisualPluginData *visualPluginData;
	static Growl_Notification notification;
	static CFMutableStringRef title = NULL;
	static CFMutableStringRef desc = NULL;
	static CFDataRef coverArtDataRef = NULL;
	char *string;
	visualPluginData = (VisualPluginData *)refCon;

	if (message != 'vrnd') {
		string = (char *)&message;
		CFLog(1, CFSTR("%s %c%c%c%c\n"), __FUNCTION__, string[0], string[1], string[2], string[3]);
	}

	err = noErr;

	switch (message) {
		/*
			Sent when the visual plugin is registered.  The plugin should do minimal
			memory allocations here.  The resource fork of the plugin is still available.
		*/
		case kVisualPluginInitMessage:
			visualPluginData = (VisualPluginData *)calloc(1, sizeof(VisualPluginData));
			if (!visualPluginData) {
				err = memFullErr;
				break;
			}

			visualPluginData->appCookie	= messageInfo->u.initMessage.appCookie;
			visualPluginData->appProc	= messageInfo->u.initMessage.appProc;

			messageInfo->u.initMessage.options = kPluginWantsToBeLeftOpen;
			messageInfo->u.initMessage.refCon = (void *)visualPluginData;

			title = CFStringCreateMutable(kCFAllocatorDefault, 0);
			desc = CFStringCreateMutable(kCFAllocatorDefault, 0);

			InitGrowlNotification(&notification);

			notification.name          = ITUNES_PLAYING;
			notification.title         = title;
			notification.description   = desc;
			notification.identifier    = CFSTR("GrowlTunes");
			//notification.priority      = priority;
			//notification.isSticky      = isSticky;
			//notification.clickContext  = NULL;
			//notification.clickCallback = NULL;
			//notification.enabledByDefault      = isDefault;
			break;

		/*
			Sent when the visual plugin is unloaded
		*/
		case kVisualPluginCleanupMessage:
			if (title)
				CFRelease(title);
			if (desc)
				CFRelease(desc);
			if (coverArtDataRef)
				CFRelease(coverArtDataRef);
			if (visualPluginData)
				free(visualPluginData);
			break;

		/*
			Sent when the visual plugin is enabled.  iTunes currently enables all
			loaded visual plugins.  The plugin should not do anything here.
		*/
		case kVisualPluginEnableMessage:
		case kVisualPluginDisableMessage:
			break;

		/*
			Sent if the plugin requests idle messages.  Do this by setting the kVisualWantsIdleMessages
			option in the RegisterVisualMessage.options field.
		*/
		case kVisualPluginIdleMessage:
			break;

		/*
			Sent if the plugin requests the ability for the user to configure it.  Do this by setting
			the kVisualWantsConfigure option in the RegisterVisualMessage.options field.
		*/
		case kVisualPluginConfigureMessage: {
			static EventTypeSpec controlEvent={kEventClassControl, kEventControlHit};
			static const ControlID kTrackSettingControlID	= {'cbox', kTrackSettingID};
			static const ControlID kDiscSettingControlID	= {'cbox', kDiscSettingID};
			static const ControlID kArtistSettingControlID	= {'cbox', kArtistSettingID};
			static const ControlID kComposerSettingControlID= {'cbox', kComposerSettingID};
			static const ControlID kAlbumSettingControlID	= {'cbox', kAlbumSettingID};
			static const ControlID kYearSettingControlID	= {'cbox', kYearSettingID};
			static const ControlID kGenreSettingControlID	= {'cbox', kGenreSettingID};

			static WindowRef  settingsDialog = NULL;
			static ControlRef trackpref		 = NULL;
			static ControlRef discpref		 = NULL;
			static ControlRef artistpref	 = NULL;
			static ControlRef composerpref	 = NULL;
			static ControlRef albumpref		 = NULL;
			static ControlRef yearpref		 = NULL;
			static ControlRef genrepref		 = NULL;

			if (!settingsDialog) {
				IBNibRef		nibRef; //we have to find our bundle to load the nib inside of it

				CFBundleRef GrowlTunesPlugin;

				GrowlTunesPlugin=CFBundleGetBundleWithIdentifier(CFSTR("com.growl.growltunes"));
				if (!GrowlTunesPlugin) {
					CFLog(1, CFSTR("bad bundle reference"));
				} else {
					CreateNibReferenceWithCFBundle(GrowlTunesPlugin, CFSTR("SettingsDialog"), &nibRef);

					CreateWindowFromNib(nibRef, CFSTR("PluginSettings"), &settingsDialog);
					DisposeNibReference(nibRef);
					InstallWindowEventHandler(settingsDialog, NewEventHandlerUPP(settingsControlHandler), 1, &controlEvent, 0, NULL);
					GetControlByID(settingsDialog, &kTrackSettingControlID, &trackpref);
					GetControlByID(settingsDialog, &kDiscSettingControlID, &discpref);
					GetControlByID(settingsDialog, &kArtistSettingControlID, &artistpref);
					GetControlByID(settingsDialog, &kComposerSettingControlID, &composerpref);
					GetControlByID(settingsDialog, &kAlbumSettingControlID, &albumpref);
					GetControlByID(settingsDialog, &kYearSettingControlID, &yearpref);
					GetControlByID(settingsDialog, &kGenreSettingControlID, &genrepref);
				}
			}
			SetControlValue(trackpref, gTrackFlag);
			SetControlValue(discpref, gDiscFlag);
			SetControlValue(artistpref, gArtistFlag);
			SetControlValue(composerpref, gComposerFlag);
			SetControlValue(albumpref, gAlbumFlag);
			SetControlValue(yearpref, gYearFlag);
			SetControlValue(genrepref, gGenreFlag);
			ShowWindow(settingsDialog);
			break;
		}

		/*
			Sent when iTunes is no longer displayed.
		*/
		case kVisualPluginHideWindowMessage:
			break;

		/*
			Sent when iTunes needs to change the port or rectangle of the currently
			displayed visual.
		*/
		case kVisualPluginSetWindowMessage:
			break;

		/*
			Sent for the visual plugin to render a frame.
		*/
		case kVisualPluginRenderMessage:
			break;
		/*
			Sent in response to an update event.  The visual plugin should update
			into its remembered port.  This will only be sent if the plugin has been
			previously given a ShowWindow message.
		*/
		case kVisualPluginUpdateMessage:
			break;
		/*
			Sent when iTunes is going to show the visual plugin in a port.  At
			this point,the plugin should allocate any large buffers it needs.
		*/
		case kVisualPluginShowWindowMessage:
			break;

		/*
			Sent when the player starts.
		*/
		case kVisualPluginPlayMessage: {
			if (messageInfo->u.playMessage.trackInfo)
				visualPluginData->trackInfo = *messageInfo->u.playMessage.trackInfoUnicode;
			else
				memset(&visualPluginData->trackInfo, 0, sizeof(visualPluginData->trackInfo));

			if (messageInfo->u.playMessage.streamInfo)
				visualPluginData->streamInfo = *messageInfo->u.playMessage.streamInfoUnicode;
			else
				memset(&visualPluginData->streamInfo, 0, sizeof(visualPluginData->streamInfo));

			setupTitleString(visualPluginData, title);
			setupDescString(visualPluginData, desc);

			Handle coverArt = NULL;
			OSType format;
			err = PlayerGetCurrentTrackCoverArt(visualPluginData->appCookie, visualPluginData->appProc, &coverArt, &format);
			if (coverArtDataRef)
				CFRelease(coverArtDataRef);
			if ((err == noErr) && coverArt) {
				//get our data ready for the notificiation.
				coverArtDataRef = CFDataCreate(kCFAllocatorDefault, (const UInt8 *)*coverArt, GetHandleSize(coverArt));
			} else {
				coverArtDataRef = NULL;
				string = (char *)&format;
				CFLog(1, CFSTR("%d: %c%c%c%c"), err, string[0], string[1], string[2], string[3]);
			}

			notification.iconData = coverArtDataRef;

			GrowlTunes_PostNotification(&notification);
			EventTypeSpec eventSpec[2] = {{ kEventClassKeyboard, kEventHotKeyPressed },{ kEventClassKeyboard, kEventHotKeyReleased }};
			if (hotKeyEventHandlerRef)
				RemoveEventHandler(hotKeyEventHandlerRef);
			InstallEventHandler(GetEventDispatcherTarget(), (EventHandlerProcPtr)hotKeyEventHandler, 2, eventSpec, &notification, &hotKeyEventHandlerRef);

			if (coverArt)
				DisposeHandle(coverArt);
			visualPluginData->playing = true;
			break;
		}

		/*
			Sent when the player changes the current track information.  This
			is used when the information about a track changes,or when the CD
			moves onto the next track.  The visual plugin should update any displayed
			information about the currently playing song.
		*/
		case kVisualPluginChangeTrackMessage:
			if (messageInfo->u.changeTrackMessage.streamInfo)
				visualPluginData->streamInfo = *messageInfo->u.changeTrackMessage.streamInfoUnicode;
			else
				memset(&visualPluginData->streamInfo, 0, sizeof(visualPluginData->streamInfo));

			setupTitleString(visualPluginData, title);
			setupDescString(visualPluginData, desc);

			GrowlTunes_PostNotification(&notification);
			break;

		/*
			Sent when the player stops.
		*/
		case kVisualPluginStopMessage:
			visualPluginData->playing = false;
			break;

		/*
			Sent when the player changes position.
		*/
		case kVisualPluginSetPositionMessage:
			break;

		/*
			Sent when the player pauses.  iTunes does not currently use pause or unpause.
			A pause in iTunes is handled by stopping and remembering the position.
		*/
		case kVisualPluginPauseMessage:
			visualPluginData->playing = false;
			break;

		/*
			Sent when the player unpauses.  iTunes does not currently use pause or unpause.
			A pause in iTunes is handled by stopping and remembering the position.
		*/
		case kVisualPluginUnpauseMessage:
			visualPluginData->playing = true;
			break;

		/*
			Sent to the plugin in response to a MacOS event.  The plugin should return noErr
			for any event it handles completely,or an error (unimpErr) if iTunes should handle it.
		*/
		case kVisualPluginEventMessage:
			err = unimpErr;
			break;

		default:
			err = unimpErr;
			break;
	}
	return err;
}


static OSStatus hotKeyEventHandler(EventHandlerCallRef inHandlerRef, EventRef inEvent, void *refCon)
{
	#pragma unused(inHandlerRef, inEvent, refCon)
	CFLog(1, CFSTR("hot key"));
	if (GetEventKind(inEvent) == kEventHotKeyReleased) {
		CFLog(1, CFSTR("%p\n"), refCon);
		if (!refCon) {
			CFLog(1, CFSTR("no notification to display"));
		} else {
			struct Growl_Notification *notification = (struct Growl_Notification *)refCon;
			//CFLog(1, CFSTR("%d %d\n"), CFGetRetainCount(notification->name), CFGetRetainCount(notification->title));
			GrowlTunes_PostNotification(notification);
		}
	}
	return noErr;
}

/*
	RegisterVisualPlugin
*/
static OSStatus RegisterVisualPlugin(PluginMessageInfo *messageInfo)
{
	CFLog(1, CFSTR("%s"), __FUNCTION__);

	PlayerMessageInfo playerMessageInfo;

	memset(&playerMessageInfo.u.registerVisualPluginMessage, 0, sizeof(playerMessageInfo.u.registerVisualPluginMessage));

	memcpy(playerMessageInfo.u.registerVisualPluginMessage.name, kTVisualPluginName, kTVisualPluginName[0] + 1);

	SetNumVersion(&playerMessageInfo.u.registerVisualPluginMessage.pluginVersion, kTVisualPluginMajorVersion, kTVisualPluginMinorVersion, kTVisualPluginReleaseStage, kTVisualPluginNonFinalRelease);

	playerMessageInfo.u.registerVisualPluginMessage.options        = kVisualWantsConfigure;
	playerMessageInfo.u.registerVisualPluginMessage.handler        = (VisualPluginProcPtr)VisualPluginHandler;
	playerMessageInfo.u.registerVisualPluginMessage.registerRefCon = NULL;
	playerMessageInfo.u.registerVisualPluginMessage.creator        = kTVisualPluginCreator;

	return PlayerRegisterVisualPlugin(messageInfo->u.initMessage.appCookie, messageInfo->u.initMessage.appProc, &playerMessageInfo);
}

/**\
|**|	main entrypoint
\**/

GROWLTUNES_EXPORT OSStatus iTunesPluginMainMachO(OSType message, PluginMessageInfo *messageInfo, void *refCon)
{
#pragma unused(refCon)
	OSStatus		err = noErr;
	CFLog(1, CFSTR("%s"), __FUNCTION__);
	switch (message) {
		case kPluginInitMessage:
			err = RegisterVisualPlugin(messageInfo);
			//register with growl and setup our delegate
			CFBundleRef growlTunesBundle = CFBundleGetBundleWithIdentifier(CFSTR("com.growl.growltunes"));
			CFURLRef privateFrameworksURL = CFBundleCopyPrivateFrameworksURL(growlTunesBundle);
			CFURLRef growlBundleURL = CFURLCreateCopyAppendingPathComponent(kCFAllocatorDefault, privateFrameworksURL, CFSTR("Growl.framework"), true);
			CFRelease(privateFrameworksURL);
			CFBundleRef growlBundle = CFBundleCreate(kCFAllocatorDefault, growlBundleURL);
			CFRelease(growlBundleURL);
			if (growlBundle) {
				if (CFBundleLoadExecutable(growlBundle)) {
					//manually load these buggers since just weak linking the framework doesn't cut it.
					GrowlTunes_SetDelegate = (GrowlSetDelegateProcPtr)CFBundleGetFunctionPointerForName(growlBundle, CFSTR("Growl_SetDelegate"));
					GrowlTunes_PostNotification = (GrowlPostNotificationProcPtr)CFBundleGetFunctionPointerForName(growlBundle, CFSTR("Growl_PostNotification"));
					GrowlTunes_GrowlIsInstalled = (GrowlIsInstalledProcPtr)CFBundleGetFunctionPointerForName(growlBundle, CFSTR("Growl_IsInstalled"));

					if (GrowlTunes_SetDelegate && GrowlTunes_PostNotification && GrowlTunes_GrowlIsInstalled) {

						InitGrowlDelegate(&delegate);

						CFMutableArrayRef allNotifications = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
						CFArrayAppendValue(allNotifications, ITUNES_PLAYING);
						CFArrayAppendValue(allNotifications, ITUNES_TRACK_CHANGED);

						CFMutableArrayRef defaultNotifications = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
						CFArrayAppendValue(defaultNotifications, ITUNES_PLAYING);
						CFArrayAppendValue(defaultNotifications, ITUNES_TRACK_CHANGED);

						CFTypeRef keys[3] = { GROWL_APP_NAME, GROWL_NOTIFICATIONS_ALL, GROWL_NOTIFICATIONS_DEFAULT };
						CFTypeRef values[3] = { CFSTR("GrowlTunes"), allNotifications, defaultNotifications };
						delegate.registrationDictionary = CFDictionaryCreate(
														 kCFAllocatorDefault, keys, values, 3,
														 &kCFTypeDictionaryKeyCallBacks,
														 &kCFTypeDictionaryValueCallBacks);
						CFRelease(allNotifications);
						CFRelease(defaultNotifications);
						if (GrowlTunes_SetDelegate(&delegate))
							CFLog(1, CFSTR("registered"));
						else
							CFLog(1, CFSTR("not registered"));

						if (!GrowlTunes_GrowlIsInstalled()) {
							//notify the user that growl isn't installed and as such that there won't be any notifications for this session of iTunes.
						}

						//setup our global hot key
						EventHotKeyID hotKeyID;
						hotKeyID.signature = 'GRTU';
						hotKeyID.id = 0xDEADBEEF;

						RegisterEventHotKey (40, cmdKey | optionKey, hotKeyID, GetEventDispatcherTarget(), 0, &reNotifyHotKeyRef);

						//this installed event handler is specifically to trap our event so we don't crash
						//if the user tries to trigger the notification before a real handler is installed
						EventTypeSpec eventSpec[2] = {{ kEventClassKeyboard, kEventHotKeyPressed },{ kEventClassKeyboard, kEventHotKeyReleased }};
						InstallEventHandler(GetEventDispatcherTarget(), (EventHandlerProcPtr)hotKeyEventHandler, 2, eventSpec, NULL, &hotKeyEventHandlerRef);

						if (growlBundle)
							CFRelease(growlBundle);
					} else {
						err = unimpErr;
					}
				}

			}
			break;

		case kPluginCleanupMessage:
			err = noErr;
			if (delegate.registrationDictionary)
				CFRelease(delegate.registrationDictionary);

			//unregister it at the end of the iTunes session to make sure that we don't trigger it accidentally
			UnregisterEventHotKey(reNotifyHotKeyRef);

			//kill our event handler if it is still around
			RemoveEventHandler(hotKeyEventHandlerRef);

			break;

		default:
			err = unimpErr;
			break;
	}

	return err;
}
