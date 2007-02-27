//  GrowlTunes.c
//  GrowlTunesPlugin
//
//  Created by rudy on 11/27/05.
//  Copyright 2005-2007, The Growl Project. All rights reserved.


/**\
|**|	includes
\**/

#include "GrowlLog.h"
#include "HotKey.h"
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
#define kBundleID						CFSTR("info.growl.growltunesplugin")

#define	kTVisualPluginMajorVersion		1
#define	kTVisualPluginMinorVersion		0
#define	kTVisualPluginReleaseStage		finalStage
#define	kTVisualPluginNonFinalRelease	0

#define ITUNES_TRACK_CHANGED	CFSTR("Changed Tracks")
#define ITUNES_PAUSED			CFSTR("Paused")
#define ITUNES_STOPPED			CFSTR("Stopped")
#define ITUNES_PLAYING			CFSTR("Started Playing")

#define GTP CFSTR("info.growl.growltunes")
enum
{
	kTrackSettingID		= 3,
	kDiscSettingID		= 4,
	kArtistSettingID	= 5,
	kComposerSettingID	= 6,
	kAlbumSettingID		= 7,
	kYearSettingID		= 8,
	kGenreSettingID		= 9,
	kRatingSettingID	= 10,
	kHotKeySettingID	= 11,
	kHotKeySetID		= 12,
	kArtWorkSetID		= 13,
	kGTPSetID			= 14,
	kArtWorkDBID		= 45,
	kArtworkGBID		= 44,
	kOKSettingID		= 1
};

enum
{
	kHotKeySheetNoneID = 3,
	kHotKeySheetCancelID = 4,
	kHotKeySheetOKID = 5,
	kHotKeySheetSettingID = 6
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

static Boolean gGTPFlag			= true;
static Boolean gTrackFlag		= true;
static Boolean gDiscFlag		= true;
static Boolean gArtistFlag		= true;
static Boolean gComposerFlag	= true;
static Boolean gAlbumFlag		= true;
static Boolean gYearFlag		= true;
static Boolean gGenreFlag		= true;
static Boolean gRatingFlag		= true;
static Boolean gArtWorkFlag		= true;
static CFIndex gKey;
static CFIndex gModifier;

static CFRunLoopSourceRef		alertRunLoopSource = NULL;

static pascal OSStatus sheetControlHandler(EventHandlerCallRef inRef, EventRef inEvent, void *userData);
static OSStatus hotKeyEventHandler(EventHandlerCallRef inHandlerRef, EventRef inEvent, void *refCon);

static ControlRef hotkeypref = NULL;
static void *mode = NULL;

static hotkey_t notificationHotKey;
static UInt32 newHotKeyValue = 0;
static UInt32 newHotKeyModifiersValue = 0;

static CFBundleRef growlTunesBundle;
static struct Growl_Notification notification;

/**\
|**|	exported function prototypes
\**/

extern OSStatus iTunesPluginMainMachO(OSType message, PluginMessageInfo *messageInfo, void *refCon);

static void handleClick(CFUserNotificationRef userNotification, CFOptionFlags responseFlags);

static OSStatus hotKeyEventHandler(EventHandlerCallRef inHandlerRef, EventRef inEvent, void *refCon);
static pascal OSStatus settingsControlHandler(EventHandlerCallRef inRef, EventRef inEvent, void *userData);
static void setupDescString(const VisualPluginData *visualPluginData, CFMutableStringRef desc);
static void setupTitleString(const VisualPluginData *visualPluginData, CFMutableStringRef title);
static pascal void readPreferences (void);
static pascal void writePreferences (void);
static pascal void newNibSheetWindow(WindowRef parent);
//static pascal OSStatus MyGetSetItemData(ControlRef browser, DataBrowserItemID itemID, DataBrowserPropertyID property, DataBrowserItemDataRef itemData, Boolean changeValue);


/*
	Name: getHotKeyString
	Function: convert the modifier and key codes into a string that can be displayed to the user in the hotkey
			  display field
*/
static CFStringRef getHotKeyString(void) 
{
	GrowlLog("%s entered", __FUNCTION__);
	CFMutableStringRef hotkeyString;
	GrowlLog("%d %d\n", hotkey_keyCode(&notificationHotKey), hotkey_modifierCode(&notificationHotKey));

	if ((hotkey_keyCode(&notificationHotKey) == kNoHotKeyKeyCode) && (hotkey_modifierCode(&notificationHotKey) == kNoHotKeyModifierCode)) 
	{
		hotkeyString = (CFMutableStringRef)CFSTR("(none)");
	} 
	else 
	{
		hotkeyString = (CFMutableStringRef)hotkey_hotKeyString(&notificationHotKey);
	}
	GrowlShow(hotkeyString);
	GrowlLog("%s exited", __FUNCTION__);
	return hotkeyString;
}

/*
	Name: readPreferences
	Function: to read the preferences out of the plist and store them into variables
*/
static void readPreferences (void)
{
	GrowlLog("%s entered", __FUNCTION__);
	Boolean success;
	Boolean temp;

	//read in the settings for display
	temp = CFPreferencesGetAppBooleanValue(CFSTR("GTP"), GTP, &success);
	if (success)
		gGTPFlag = temp;

	temp = CFPreferencesGetAppBooleanValue(CFSTR("Track"), GTP, &success);
	if (success)
		gTrackFlag = temp;

	temp = CFPreferencesGetAppBooleanValue(CFSTR("Disc"), GTP, &success);
	if (success)
		gDiscFlag = temp;

	temp = CFPreferencesGetAppBooleanValue(CFSTR("Artist"), GTP, &success);
	if (success)
		gArtistFlag = temp;

	temp = CFPreferencesGetAppBooleanValue(CFSTR("Composer"), GTP, &success);
	if (success)
		gComposerFlag = temp;

	temp = CFPreferencesGetAppBooleanValue(CFSTR("Album"), GTP, &success);
	if (success)
		gAlbumFlag = temp;

	temp = CFPreferencesGetAppBooleanValue(CFSTR("Year"), GTP, &success);
	if (success)
		gYearFlag = temp;

	temp = CFPreferencesGetAppBooleanValue(CFSTR("Genre"), GTP, &success);
	if (success)
		gGenreFlag = temp;

	temp = CFPreferencesGetAppBooleanValue(CFSTR("Rating"), GTP, &success);
	if (success)
		gRatingFlag = temp;

	temp = CFPreferencesGetAppBooleanValue(CFSTR("ArtWork"), GTP, &success);
	if (success)
		gArtWorkFlag = temp;

	gKey = CFPreferencesGetAppIntegerValue(CFSTR("Key"), GTP, &success);
	if (success) 
	{
		//GrowlLog(1, CFSTR("%ld\n"), gKey);
	} 
	else 
	{
		gKey = 40;
	}

	gModifier = CFPreferencesGetAppIntegerValue(CFSTR("Modifiers"), GTP, &success);
	if (success) 
	{
		//GrowlLog(1, CFSTR("%ld\n"), gModifier);
	} 
	else 
	{
		gModifier = (cmdKey | optionKey);
	}

	if (gKey && gModifier)
		hotkey_init(&notificationHotKey, 'GRTU', 0xDEADBEEF, gKey, gModifier, NewEventHandlerUPP(&hotKeyEventHandler));

	//if we were unsuccessful in reading in all our settings then it means either we're creating a new plist file
	//or that the user has manually edited the plist and has deleted one or more of the keys from the file and we should
	//force recreation to ensure proper interface display
	if (!success)
		writePreferences();
	
	GrowlLog("%s exited", __FUNCTION__);
}

/*
	Name: writePreferences
	Function: write out the default settings or the user selected settings to the plist
*/
static void writePreferences (void)
{
	GrowlLog("%s entered", __FUNCTION__);
	
	//store the display settings for the notifications
	CFPreferencesSetAppValue(CFSTR("GTP"), (gGTPFlag ? kCFBooleanTrue : kCFBooleanFalse), GTP);
	CFPreferencesSetAppValue(CFSTR("Track"), (gTrackFlag ? kCFBooleanTrue : kCFBooleanFalse), GTP);
	CFPreferencesSetAppValue(CFSTR("Disc"), (gDiscFlag ? kCFBooleanTrue : kCFBooleanFalse), GTP);
	CFPreferencesSetAppValue(CFSTR("Artist"), (gArtistFlag ? kCFBooleanTrue : kCFBooleanFalse), GTP);
	CFPreferencesSetAppValue(CFSTR("Composer"), (gComposerFlag ? kCFBooleanTrue : kCFBooleanFalse), GTP);
	CFPreferencesSetAppValue(CFSTR("Album"), (gAlbumFlag ? kCFBooleanTrue : kCFBooleanFalse), GTP);
	CFPreferencesSetAppValue(CFSTR("Year"), (gYearFlag ? kCFBooleanTrue : kCFBooleanFalse), GTP);
	CFPreferencesSetAppValue(CFSTR("Genre"), (gGenreFlag ? kCFBooleanTrue : kCFBooleanFalse), GTP);
	CFPreferencesSetAppValue(CFSTR("Rating"), (gRatingFlag ? kCFBooleanTrue: kCFBooleanFalse), GTP);
	CFPreferencesSetAppValue(CFSTR("ArtWork"), (gArtWorkFlag ? kCFBooleanTrue: kCFBooleanFalse), GTP);

	CFIndex key = hotkey_keyCode(&notificationHotKey);
	CFIndex modifiers = hotkey_modifierCode(&notificationHotKey);

	//GrowlLog(1, CFSTR("%ld %ld\n"), key, modifiers);
	//if the key is zero then the selection is defaulted, use key code for k
	if (key == 0) 
	{
		key = 40;
		hotkey_setKeyCode(&notificationHotKey, key);
	}
	CFNumberRef hk = CFNumberCreate( kCFAllocatorDefault, kCFNumberSInt32Type, &key);
	CFPreferencesSetAppValue( CFSTR("Key"), hk, GTP);

	if (modifiers == 0) 
	{
		modifiers = (cmdKey | optionKey);
		hotkey_setModifierCode(&notificationHotKey, modifiers);
	}
	CFNumberRef mod = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &modifiers);
	CFPreferencesSetAppValue(CFSTR("Modifiers"), mod, GTP);

	CFPreferencesAppSynchronize(GTP);
	GrowlLog("%s exited", __FUNCTION__);
}

/*
	Name: settingsControlHandler
	Function: event handling loop for the settings window, deals with value changes and writing the settings out to the plist
*/
static pascal OSStatus settingsControlHandler(EventHandlerCallRef inRef, EventRef inEvent, void *userData)
{
	GrowlLog("%s entered", __FUNCTION__);

	WindowRef wind = NULL;
	ControlID controlID;
	ControlRef control = NULL;
	ControlRef artworkDB = NULL;
	ControlRef artworkGB = NULL;
	static const ControlID artwork	= {'cbox', kArtWorkDBID};
	static const ControlID groupbox	= {'cbox', kArtworkGBID};

	inRef = NULL;
	userData = NULL;

	//get control hit by event
	GetEventParameter(inEvent, kEventParamDirectObject, typeControlRef, NULL, sizeof(ControlRef), NULL, &control);
	wind=GetControlOwner(control);
	GetControlID(control, &controlID);
	GetControlByID(wind, &artwork, &artworkDB);
	GetControlByID(wind, &groupbox, &artworkGB);

	//char *string = (char *)&controlID.signature;
	//GrowlLog(1, CFSTR("%s %c%c%c%c\n"), __FUNCTION__, string[0], string[1], string[2], string[3]);
	switch (controlID.id)
	{
		case kGTPSetID:
			gGTPFlag = GetControlValue(control);
			if (gGTPFlag) 
			{
				hotkey_setKeyCodeAndModifiers(&notificationHotKey, gKey, gModifier);
				hotkey_swapHotKeys(&notificationHotKey);
			} 
			else 
			{
				//we need to kill the hotkey so that it doesn't trigger when GTP is off
				hotkey_setKeyCodeAndModifiers(&notificationHotKey, kNoHotKeyKeyCode, kNoHotKeyModifierCode);
				hotkey_swapHotKeys(&notificationHotKey);
			}
			break;
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
		case kRatingSettingID:
			gRatingFlag = GetControlValue(control);
			break;
		case kArtWorkSetID:
			gArtWorkFlag = GetControlValue(control);

			if (gArtWorkFlag) 
			{
				//GrowlLog(1, CFSTR("artwork enabled\n"));
				//enable the Artwork controls since we've enabled artwork gathering
				EnableControl(artworkDB);
			} 
			else 
			{
				//GrowlLog(1, CFSTR("artwork disabled\n"));
				//disable the artwork controls since we've turned off artwork gathering
				DisableControl(artworkDB);
			}
			break;
		case kArtWorkDBID:
			//don't do anything for right now
			break;
		case kOKSettingID:
			writePreferences();
			HideWindow(wind);
			break;
		case kHotKeySetID:
			//run the hot key capture sheet
			//GrowlLog(1, CFSTR("run the capture sheet"));
			newNibSheetWindow(wind);
			CFStringRef hotKeyString = getHotKeyString();
			SetControlData(hotkeypref, 0, kControlStaticTextCFStringTag, sizeof(CFStringRef), &hotKeyString);
			break;
	}
	
	GrowlLog("%s exited", __FUNCTION__);
	return noErr;
}

static pascal void newNibSheetWindow(WindowRef parent)
{
	GrowlLog("%s entered", __FUNCTION__);
	
	static EventTypeSpec controlEvent[3] = {{kEventClassControl,kEventControlHit}, {kEventClassKeyboard, kEventRawKeyDown}, {kEventClassKeyboard, kEventRawKeyRepeat}};
	static const ControlID kHotKeyTextControlID = {'text', kHotKeySheetSettingID};
	static ControlRef sheethotkeypref	= NULL;

	IBNibRef 		nibRef;
	WindowRef		wind = NULL;

	newHotKeyValue = hotkey_keyCode(&notificationHotKey);
	newHotKeyModifiersValue = hotkey_modifierCode(&notificationHotKey);
	CreateNibReferenceWithCFBundle(growlTunesBundle, CFSTR("SettingsDialog"), &nibRef);
	CreateWindowFromNib(nibRef, CFSTR("HotKeySheet"), &wind);
	DisposeNibReference(nibRef);
	GetControlByID(wind, &kHotKeyTextControlID, &sheethotkeypref);

	InstallWindowEventHandler(wind, NewEventHandlerUPP(sheetControlHandler), 3, controlEvent, &sheethotkeypref, NULL);
	CFStringRef hotKeyString = getHotKeyString();
	SetControlData(sheethotkeypref, 0, kControlStaticTextCFStringTag, sizeof(CFStringRef), &hotKeyString);
	mode = PushSymbolicHotKeyMode(kHIHotKeyModeAllDisabled);
	ShowSheetWindow(wind,parent);
	GrowlLog("%s exited", __FUNCTION__);
}

static pascal OSStatus sheetControlHandler(EventHandlerCallRef inRef, EventRef inEvent, void *userData) {
#pragma unused(inRef, userData)
	GrowlLog("%s entered", __FUNCTION__);

	WindowRef wind = NULL;
	ControlRef control = NULL;
	ControlRef *sheethotkeypref = (ControlRef *)userData;
	ControlID controlID;
	UInt32 eventClass = GetEventClass(inEvent);
	UInt32 eventKind = GetEventKind(inEvent);
	CFStringRef hotKeyString;

	if ((eventClass == kEventClassKeyboard) && ((eventKind == kEventRawKeyDown) || (eventKind == kEventRawKeyRepeat))) 
	{
		GetEventParameter(inEvent, kEventParamKeyModifiers, typeUInt32, NULL, sizeof(UInt32), NULL, &newHotKeyModifiersValue);
		GetEventParameter(inEvent, kEventParamKeyCode, typeUInt32, NULL, sizeof(UInt32), NULL, &newHotKeyValue);

		hotkey_t tempKey;
		hotkey_init(&tempKey, 'tmp ', 'test', newHotKeyValue, newHotKeyModifiersValue, NULL);
		hotKeyString = hotkey_hotKeyString(&tempKey);
		SetControlData(*sheethotkeypref, 0, kControlStaticTextCFStringTag, sizeof(CFStringRef), &hotKeyString);
		Draw1Control(*sheethotkeypref);
		hotkey_release(&tempKey);
	} 
	else if ((eventClass == kEventClassControl) && (eventKind == kEventControlHit)) 
	{
		GetEventParameter(inEvent, kEventParamDirectObject, typeControlRef, NULL, sizeof(ControlRef), NULL, &control);
		wind = GetControlOwner(control);
		GetControlID(control, &controlID);

		//char *string = (char *)&controlID.signature;

		switch (controlID.id) 
		{
			case kHotKeySheetNoneID:
				hotkey_setKeyCodeAndModifiers(&notificationHotKey, kNoHotKeyKeyCode, kNoHotKeyModifierCode);
				hotkey_swapHotKeys(&notificationHotKey);
				break;
			case kHotKeySheetOKID:
				//GrowlLog(1, CFSTR("%d  %d\n"), newHotKeyValue, newHotKeyModifiersValue);
				if ((newHotKeyValue != hotkey_keyCode(&notificationHotKey)) || (newHotKeyModifiersValue != hotkey_modifierCode(&notificationHotKey))) 
				{
					hotkey_setKeyCodeAndModifiers(&notificationHotKey, newHotKeyValue, newHotKeyModifiersValue);
					hotkey_swapHotKeys(&notificationHotKey);
				}
				break;
			case kHotKeySheetCancelID:
				//do nothing, they didn't change anything
				break;
			default:
				//do nothing, they didn't click on anything meaningful
				GrowlLog("%s exited", __FUNCTION__);
				return noErr;
		}
		hotKeyString = getHotKeyString();
		//GrowlLog(1, CFSTR("hotkeySTRINg: %@\n"), hotKeyString);
		SetControlData(hotkeypref, 0, kControlStaticTextCFStringTag, sizeof(CFStringRef), &hotKeyString);
		Draw1Control(hotkeypref);
		PopSymbolicHotKeyMode(mode);
		HideSheetWindow(wind);
		DisposeWindow(wind);
	}
	
	GrowlLog("%s exited", __FUNCTION__);
	return noErr;
}

/*
static void InstallDataBrowserCallbacks(ControlRef browser)
{
	DataBrowserCallbacks myCallbacks;

	//Use latest layout and callback signatures
	myCallbacks.version = kDataBrowserLatestCallbacks;
	verify_noerr(InitDataBrowserCallbacks(&myCallbacks));

	myCallbacks.u.v1.itemDataCallback =
		NewDataBrowserItemDataUPP(MyGetSetItemData);

	verify_noerr(SetDataBrowserCallbacks(browser, &myCallbacks));
}

static pascal OSStatus MyGetSetItemData(ControlRef browser, DataBrowserItemID itemID, DataBrowserPropertyID property, DataBrowserItemDataRef itemData, Boolean changeValue)
{
#pragma unused (browser, itemID, property, itemData, changeValue)
	//Str255 pascalString;
	OSStatus err = noErr;

	if (!changeValue)
		switch (property) {
			case kCheckboxColumn:
				if ((itemID % 5) == 2)
					err = ::SetDataBrowserItemDataButtonValue(itemData, kThemeButtonOn);
				err = ::SetDataBrowserItemDataDrawState(itemData, kThemeStateInactive);
				break;

			case kFlavorColumn:
			{	::GetIndString(pascalString, 128, itemID % 5 + 1);
				CFStringRef text = ::CFStringCreateWithPascalString(
					kCFAllocatorDefault, pascalString, kCFStringEncodingMacRoman);

				err = ::SetDataBrowserItemDataText(itemData, text); ::CFRelease(text);
			}	// Fall through to kIconOnlyColumn

		case kIconOnlyColumn:
			err = ::SetDataBrowserItemDataIcon(itemData, Container(itemID) ?
				icon[kFolder] : Alias(itemID) ? icon[kFolderAlias] : icon[kDocument]);
			break;

		case kColorColumn:
		{	::GetIndString(pascalString, 129, itemID % 5 + 1);
			CFStringRef text = ::CFStringCreateWithPascalString(
				kCFAllocatorDefault, pascalString, kCFStringEncodingMacRoman);
			err = ::SetDataBrowserItemDataText(itemData, text); ::CFRelease(text);
		}	break;

		case kIndexColumn:
		{	SInt16 mod5 = itemID % 5;
			if (mod5 == 0) mod5 = 5;
			::NumToString(mod5, pascalString);
			CFStringRef text = ::CFStringCreateWithPascalString(
				kCFAllocatorDefault, pascalString, kCFStringEncodingMacRoman);
			err = ::SetDataBrowserItemDataText(itemData, text); ::CFRelease(text);
		}	break;

		case kDateTimeColumn:
		{	LongDateCvt dt;
			dt.hl.lHigh = 0;
			GetDateTime( &dt.hl.lLow );
			dt.hl.lLow -= (((itemID - 1) % 10) * 28800 );
			err = ::SetDataBrowserItemDataLongDateTime(itemData, &dt.c );
		}	break;

		case kSliderColumn:
		case kProgressBarColumn:
		{	err = ::SetDataBrowserItemDataValue(itemData, (itemID % 5) * 20);
		}	break;

		case kPopupMenuColumn:
		{	if ((itemID % 5 + 1) != 1)
			{	err = ::SetDataBrowserItemDataMenuRef(itemData, menu);
			}
			err = ::SetDataBrowserItemDataValue(itemData, itemID % 5 + 1);
		}	break;

		case kDataBrowserItemSelfIdentityProperty:
		{	err = ::SetDataBrowserItemDataIcon(itemData, Container(itemID) ?
				icon[kFolder] : Alias(itemID) ? icon[kFolderAlias] : icon[kDocument]);
		}	// Fall through to text generator

		case kItemIDColumn:
		{	GenerateString(itemID, property, pascalString);
			CFStringRef text = ::CFStringCreateWithPascalString(
				kCFAllocatorDefault, pascalString, kCFStringEncodingMacRoman);
			err = ::SetDataBrowserItemDataText(itemData, text); ::CFRelease(text);
		}	break;

		case kDataBrowserItemIsActiveProperty:
			if ((itemID % 5) == 3)
				err = ::SetDataBrowserItemDataBooleanValue(itemData, false);
			break;

		case kDataBrowserItemIsEditableProperty:
			err = ::SetDataBrowserItemDataBooleanValue(itemData, true);
			break;

		case kDataBrowserItemIsContainerProperty:
			err = ::SetDataBrowserItemDataBooleanValue(itemData, Container(itemID));
			break;

		case kDataBrowserContainerAliasIDProperty:
			if (Alias(itemID))
				err = ::SetDataBrowserItemDataItemID(itemData, 4);
			break;

		case kDataBrowserItemParentContainerProperty:
			err = ::SetDataBrowserItemDataItemID(itemData, (itemID-1) / kItemsPerContainer);
			break;

		default:
			err = errDataBrowserPropertyNotSupported;
			break;
	}
	else err = errDataBrowserPropertyNotSupported;
	return err;
}
*/

/*
	Name: setupTitleString
	Function: configures the title string to be used by the notification based on the user's selected
			  display settings and the information that is available from iTunes for the new track
*/
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
*/
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
		if (gRatingFlag) 
		{
			UniChar star = 0x272F;
			UniChar dot = 0x00B7;
			UniChar buf[5] = {dot,dot,dot,dot,dot};

			switch (visualPluginData->trackInfo.userRating) 
			{
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
			CFStringAppend(tmp, CFSTR(" - "));
			CFStringAppendCharacters(tmp, buf, 5);
			rating = tmp;
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


/*
	Name: VisualPluginHandler
	Function: handles the event loop that iTunes provides through the iTunes visual plugin api
*/
static OSStatus VisualPluginHandler(OSType message, VisualPluginMessageInfo *messageInfo, void *refCon)
{
	GrowlLog("%s entered", __FUNCTION__);

	OSStatus         err = noErr;
	VisualPluginData *visualPluginData;
	static CFMutableStringRef title = NULL;
	static CFMutableStringRef desc = NULL;
	static CFDataRef coverArtDataRef = NULL;
	visualPluginData = (VisualPluginData *)refCon;

	/*
	if (message != 'vrnd') 
	{
		char *string = (char *)&message;
		GrowlLog(1, CFSTR("%s %c%c%c%c\n"), __FUNCTION__, string[0], string[1], string[2], string[3]);
	}
	*/

	err = noErr;

	switch (message) 
	{
		/*
			Sent when the visual plugin is registered.  The plugin should do minimal
			memory allocations here.  The resource fork of the plugin is still available.
		*/
		case kVisualPluginInitMessage:
			visualPluginData = (VisualPluginData *)calloc(1, sizeof(VisualPluginData));
			if (!visualPluginData) 
			{
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
		case kVisualPluginConfigureMessage: 
		{
			static EventTypeSpec controlEvent={kEventClassControl, kEventControlHit};
			static const ControlID kGTPSettingControlID     = {'cbox', kGTPSetID};
			static const ControlID kTrackSettingControlID	= {'cbox', kTrackSettingID};
			static const ControlID kDiscSettingControlID	= {'cbox', kDiscSettingID};
			static const ControlID kArtistSettingControlID	= {'cbox', kArtistSettingID};
			static const ControlID kComposerSettingControlID= {'cbox', kComposerSettingID};
			static const ControlID kAlbumSettingControlID	= {'cbox', kAlbumSettingID};
			static const ControlID kYearSettingControlID	= {'cbox', kYearSettingID};
			static const ControlID kGenreSettingControlID	= {'cbox', kGenreSettingID};
			static const ControlID kRatingSettingControlID	= {'cbox', kRatingSettingID};
			static const ControlID kHotKeyTextControlID		= {'text', kHotKeySettingID};
			static const ControlID kArtWorkSettingID		= {'cbox', kArtWorkSetID};
			//static const ControlID kArtWorkDBSettingID		= {'text', kArtWorkDBID};

			static WindowRef  settingsDialog = NULL;
			static ControlRef gtppref		 = NULL;
			static ControlRef trackpref		 = NULL;
			static ControlRef discpref		 = NULL;
			static ControlRef artistpref	 = NULL;
			static ControlRef composerpref	 = NULL;
			static ControlRef albumpref		 = NULL;
			static ControlRef yearpref		 = NULL;
			static ControlRef genrepref		 = NULL;
			static ControlRef ratingpref     = NULL;
			static ControlRef artworkpref	 = NULL;

			if (!settingsDialog) 
			{
				IBNibRef		nibRef; //we have to find our bundle to load the nib inside of it

				CFBundleRef GrowlTunesPlugin;

				GrowlTunesPlugin = CFBundleGetBundleWithIdentifier(kBundleID);
				if (GrowlTunesPlugin) 
				{
					CreateNibReferenceWithCFBundle(GrowlTunesPlugin, CFSTR("SettingsDialog"), &nibRef);

					CreateWindowFromNib(nibRef, CFSTR("PluginSettings"), &settingsDialog);
					DisposeNibReference(nibRef);
					InstallWindowEventHandler(settingsDialog, NewEventHandlerUPP(settingsControlHandler), 1, &controlEvent, 0, NULL);
					GetControlByID(settingsDialog, &kGTPSettingControlID, &gtppref);
					GetControlByID(settingsDialog, &kTrackSettingControlID, &trackpref);
					GetControlByID(settingsDialog, &kDiscSettingControlID, &discpref);
					GetControlByID(settingsDialog, &kArtistSettingControlID, &artistpref);
					GetControlByID(settingsDialog, &kComposerSettingControlID, &composerpref);
					GetControlByID(settingsDialog, &kAlbumSettingControlID, &albumpref);
					GetControlByID(settingsDialog, &kYearSettingControlID, &yearpref);
					GetControlByID(settingsDialog, &kGenreSettingControlID, &genrepref);
					GetControlByID(settingsDialog, &kRatingSettingControlID, &ratingpref);
					GetControlByID(settingsDialog, &kHotKeyTextControlID, &hotkeypref);
					GetControlByID(settingsDialog, &kArtWorkSettingID, &artworkpref);
				} 
				else  
				{
					//GrowlLog(1, CFSTR("bad bundle reference"));
				}
			}

			SetControlValue(gtppref, gGTPFlag);
			SetControlValue(trackpref, gTrackFlag);
			SetControlValue(discpref, gDiscFlag);
			SetControlValue(artistpref, gArtistFlag);
			SetControlValue(composerpref, gComposerFlag);
			SetControlValue(albumpref, gAlbumFlag);
			SetControlValue(yearpref, gYearFlag);
			SetControlValue(genrepref, gGenreFlag);
			SetControlValue(ratingpref, gRatingFlag);
			SetControlValue(artworkpref, gArtWorkFlag);

			CFStringRef hotKeyString = getHotKeyString();
			SetControlData(hotkeypref, 0, kControlStaticTextCFStringTag, sizeof(CFStringRef), &hotKeyString);

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
		case kVisualPluginPlayMessage: 
		{
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
			if (gArtWorkFlag) 
			{
				OSType format;
				err = PlayerGetCurrentTrackCoverArt(visualPluginData->appCookie, visualPluginData->appProc, &coverArt, &format);
				if (coverArtDataRef) 
				{
					CFRelease(coverArtDataRef);
					coverArtDataRef = NULL;
				}

				if ((err == noErr) && coverArt) 
				{
					//get our data ready for the notification.
					coverArtDataRef = CFDataCreate(kCFAllocatorDefault, (const UInt8 *)*coverArt, GetHandleSize(coverArt));
				} 
				else  
				{
					if (coverArtDataRef) 
					{
						CFRelease(coverArtDataRef);
						coverArtDataRef = NULL;
					}
					/*
					char *string = (char *)&format;
					GrowlLog(1, CFSTR("%d: %c%c%c%c"), err, string[0], string[1], string[2], string[3]);
					*/
				}
				notification.iconData = coverArtDataRef;
			} 
			else 
			{
				if (notification.iconData)
					CFRelease(notification.iconData);
				notification.iconData = NULL;
			}

			if (gGTPFlag)
				GrowlTunes_PostNotification(&notification);

			hotkey_setData(&notificationHotKey, &notification);
			//GrowlLog(1, notificationHotKey->hotKeyString());

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
		{
			if (messageInfo->u.changeTrackMessage.trackInfo)
				visualPluginData->trackInfo = *messageInfo->u.changeTrackMessage.trackInfoUnicode;
			else
				memset(&visualPluginData->trackInfo, 0, sizeof(visualPluginData->trackInfo));

			if (messageInfo->u.changeTrackMessage.streamInfo)
				visualPluginData->streamInfo = *messageInfo->u.changeTrackMessage.streamInfoUnicode;
			else
				memset(&visualPluginData->streamInfo, 0, sizeof(visualPluginData->streamInfo));

			setupTitleString(visualPluginData, title);
			setupDescString(visualPluginData, desc);

			Handle coverArt = NULL;
			if (gArtWorkFlag) 
			{
				OSType format;
				err = PlayerGetCurrentTrackCoverArt(visualPluginData->appCookie, visualPluginData->appProc, &coverArt, &format);
				if (coverArtDataRef) 
				{
					CFRelease(coverArtDataRef);
					coverArtDataRef = NULL;
				}
				
				if ((err == noErr) && coverArt) 
				{
					//get our data ready for the notification.
					coverArtDataRef = CFDataCreate(kCFAllocatorDefault, (const UInt8 *)*coverArt, GetHandleSize(coverArt));
				} 
				else  
				{
					if (coverArtDataRef) 
					{
						CFRelease(coverArtDataRef);
						coverArtDataRef = NULL;
					}
					//coverArtDataRef = NULL;
					/*
					char *string = (char *)&format;
					GrowlLog(1, CFSTR("%d: %c%c%c%c"), err, string[0], string[1], string[2], string[3]);
					*/
				}
				notification.iconData = coverArtDataRef;
			} 
			else 
			{
				if (notification.iconData)
					CFRelease(notification.iconData);
				notification.iconData = NULL;
			}

			if (gGTPFlag)
				GrowlTunes_PostNotification(&notification);

			if (coverArt)
				DisposeHandle(coverArt);
			break;
		}

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
	GrowlLog("%s exited", __FUNCTION__);
	return err;
}

/*
	Name: hotKeyEventHandler
	Function: handles the action that should occur when a hotkey is pressed
*/
static OSStatus hotKeyEventHandler(EventHandlerCallRef inHandlerRef, EventRef inEvent, void *refCon)
{
	#pragma unused(inHandlerRef)
	GrowlLog("%s entered", __FUNCTION__);
	//GrowlLog(1, CFSTR("hot key"));
	if (GetEventKind(inEvent) == kEventHotKeyReleased) 
	{
		//GrowlLog(1, CFSTR("%p\n"), refCon);
		if (!refCon) 
		{
			GrowlLog("no notification to display");
		} 
		else 
		{
			//struct Growl_Notification * notif = (struct Growl_Notification *)refCon;
			//GrowlLog(1, CFSTR("%p\n"), refCon);
			GrowlTunes_PostNotification(&notification);
		}
	}
	return noErr;
}

/*
	Name: doNotificationWithKeysAndValues
	Function: does a modal dialog that gives the user an opportunity to go get growl in the event of one of the failures
*/
static OSStatus doNotificationWithKeysAndValues (CFStringRef *keys, CFStringRef *values, int numberOfValues)
{
	GrowlLog("%s entered", __FUNCTION__);
	SInt32 error = noErr;
	CFDictionaryRef dialogProperties = CFDictionaryCreate(kCFAllocatorDefault,(const void**)keys, (const void**)values, numberOfValues, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks  );
	CFUserNotificationRef alert = CFUserNotificationCreate ( kCFAllocatorDefault, 0, kCFUserNotificationCautionAlertLevel, &error, (CFDictionaryRef)dialogProperties);
	alertRunLoopSource = CFUserNotificationCreateRunLoopSource( kCFAllocatorDefault, alert, &handleClick, 0);
	CFRunLoopAddSource( CFRunLoopGetCurrent(), alertRunLoopSource, kCFRunLoopDefaultMode);
	GrowlLog("%s exited", __FUNCTION__);
	return error;
}


static void handleClick(CFUserNotificationRef userNotification, CFOptionFlags responseFlags)
{		
	#pragma unused(userNotification)
	GrowlLog("%s entered", __FUNCTION__);
	CFURLRef url;
	OSStatus err = noErr;
	
	switch(responseFlags)
	{
		case kCFUserNotificationAlternateResponse:
				url = CFURLCreateWithString(kCFAllocatorDefault, CFSTR("http://www.growl.info/"), NULL);
				LSOpenCFURLRef(url, NULL);
				if(url)
					CFRelease(url);
				break;
		case kCFUserNotificationDefaultResponse:
				break;
		case kCFUserNotificationOtherResponse:
				url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, CFSTR("/Library/PreferencePanes/Growl.prefPane"), kCFURLPOSIXPathStyle, false);
				err = LSOpenCFURLRef(url, NULL);
				if(err != noErr)
				{
					FSRef homeDir;
					FSFindFolder(kUserDomain, kCurrentUserFolderType, kDontCreateFolder, &homeDir);
					
					url = CFURLCreateFromFSRef(kCFAllocatorDefault, &homeDir);
					url = CFURLCreateCopyAppendingPathComponent(kCFAllocatorDefault, url, CFSTR("Library/PreferencePanes/Growl.prefPane"), false);
					
					err = LSOpenCFURLRef(url, NULL);
				}
				
				if(url)
					CFRelease(url);
				break;
		default:
				break;
	}
	CFRunLoopRemoveSource(CFRunLoopGetCurrent(), alertRunLoopSource, kCFRunLoopCommonModes);
	GrowlLog("%s exited", __FUNCTION__);
}

/*
	Name: RegisterVisualPlugin
	Function: registers GrowlTunes with the iTunes plugin api
*/
static OSStatus RegisterVisualPlugin(PluginMessageInfo *messageInfo)
{
	GrowlLog("%s entered", __FUNCTION__);

	PlayerMessageInfo playerMessageInfo;

	memset(&playerMessageInfo.u.registerVisualPluginMessage, 0, sizeof(playerMessageInfo.u.registerVisualPluginMessage));

	memcpy(playerMessageInfo.u.registerVisualPluginMessage.name, kTVisualPluginName, kTVisualPluginName[0] + 1);

	SetNumVersion(&playerMessageInfo.u.registerVisualPluginMessage.pluginVersion, kTVisualPluginMajorVersion, kTVisualPluginMinorVersion, kTVisualPluginReleaseStage, kTVisualPluginNonFinalRelease);

	playerMessageInfo.u.registerVisualPluginMessage.options        = kVisualWantsConfigure;
	playerMessageInfo.u.registerVisualPluginMessage.handler        = (VisualPluginProcPtr)VisualPluginHandler;
	playerMessageInfo.u.registerVisualPluginMessage.registerRefCon = NULL;
	playerMessageInfo.u.registerVisualPluginMessage.creator        = kTVisualPluginCreator;

	GrowlLog("%s exited", __FUNCTION__);
	return PlayerRegisterVisualPlugin(messageInfo->u.initMessage.appCookie, messageInfo->u.initMessage.appProc, &playerMessageInfo);
}

/*
	Name: iTunesPluginMainMachO
	Function: the main entrypoint for the plugin, handles the init and dealloc messages that are given to it by iTunes
*/
GROWLTUNES_EXPORT OSStatus iTunesPluginMainMachO(OSType message, PluginMessageInfo *messageInfo, void *refCon)
{
#pragma unused(refCon)
	GrowlLog("%s entered", __FUNCTION__);
	OSStatus		err = noErr;
	switch (message) 
	{
		case kPluginInitMessage:
			err = RegisterVisualPlugin(messageInfo);

			//register with growl and setup our delegate
			growlTunesBundle = CFBundleGetBundleWithIdentifier(kBundleID);
			CFURLRef privateFrameworksURL = CFBundleCopyPrivateFrameworksURL(growlTunesBundle);
			CFURLRef growlBundleURL = CFURLCreateCopyAppendingPathComponent(kCFAllocatorDefault, privateFrameworksURL, CFSTR("Growl.framework"), true);
			CFRelease(privateFrameworksURL);
			CFBundleRef growlBundle = CFBundleCreate(kCFAllocatorDefault, growlBundleURL);
			CFRelease(growlBundleURL);
			if (growlBundle) 
			{
				if (CFBundleLoadExecutable(growlBundle)) 
				{
					//manually load these buggers since just weak linking the framework doesn't cut it.
					GrowlTunes_SetDelegate = (GrowlSetDelegateProcPtr)CFBundleGetFunctionPointerForName(growlBundle, CFSTR("Growl_SetDelegate"));
					GrowlTunes_PostNotification = (GrowlPostNotificationProcPtr)CFBundleGetFunctionPointerForName(growlBundle, CFSTR("Growl_PostNotification"));
					GrowlTunes_GrowlIsInstalled = (GrowlIsInstalledProcPtr)CFBundleGetFunctionPointerForName(growlBundle, CFSTR("Growl_IsInstalled"));

					if (GrowlTunes_SetDelegate && GrowlTunes_PostNotification && GrowlTunes_GrowlIsInstalled) 
					{
						InitGrowlDelegate(&delegate);

						CFMutableArrayRef allNotifications = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
						CFArrayAppendValue(allNotifications, ITUNES_PLAYING);
						CFArrayAppendValue(allNotifications, ITUNES_TRACK_CHANGED);

						CFMutableArrayRef defaultNotifications = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
						CFArrayAppendValue(defaultNotifications, ITUNES_PLAYING);
						CFArrayAppendValue(defaultNotifications, ITUNES_TRACK_CHANGED);

						CFTypeRef keys[3] = { GROWL_APP_NAME, GROWL_NOTIFICATIONS_ALL, GROWL_NOTIFICATIONS_DEFAULT };
						CFTypeRef values[3] = { CFSTR("GrowlTunes"), allNotifications, defaultNotifications };
						delegate.registrationDictionary = CFDictionaryCreate( kCFAllocatorDefault, keys, values, 3, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
						CFRelease(allNotifications);
						CFRelease(defaultNotifications);
						
						CFIndex num = 6;
						CFStringRef alert_keys[num];
						CFStringRef alert_values[num];
						
						alert_keys[0] = kCFUserNotificationAlertHeaderKey;
						alert_keys[1] = kCFUserNotificationAlertMessageKey;
						alert_keys[2] = kCFUserNotificationDefaultButtonTitleKey;
						alert_keys[3] = kCFUserNotificationAlternateButtonTitleKey;
						alert_keys[4] = kCFUserNotificationOtherButtonTitleKey;
						alert_keys[5] = kCFUserNotificationIconURLKey;

						if (!GrowlTunes_SetDelegate(&delegate))
						{							
							CFURLRef growlTunesBundleURL = CFBundleCopyBundleURL(growlTunesBundle);
							alert_values[0] = CFSTR("Growl Registration Error");
							alert_values[1] = CFSTR("Growl notifications aren't available, your install of Growl is either broken or you need to update your Growl install.");
							alert_values[2] = CFSTR("OK");
							alert_values[3] = CFSTR("Get Growl");
							alert_values[4] = CFSTR("Open Growl");
							alert_values[5] = (CFStringRef)CFBundleCopyResourceURLInDirectory (growlTunesBundleURL, CFSTR("growl"), CFSTR("png"), NULL);

							doNotificationWithKeysAndValues(alert_keys,alert_values,num);
							if(alert_values[4])
								CFRelease(alert_values[4]);
							if(growlTunesBundleURL)
								CFRelease(growlTunesBundleURL);
						}
						
						if (!GrowlTunes_GrowlIsInstalled()) 
						{
							//notify the user that growl isn't installed and as such that there won't be any notifications for this session of iTunes.														
							CFURLRef growlTunesBundleURL = CFBundleCopyBundleURL(growlTunesBundle);
							alert_values[0] = CFSTR("Growl is not installed.");
							alert_values[1] = CFSTR("Growl notifications aren't available, you need to install Growl.");
							alert_values[2] = CFSTR("OK");
							alert_values[3] = CFSTR("Get Growl");
							alert_values[4] = CFSTR("Open Growl");
							alert_values[5] = (CFStringRef)CFBundleCopyResourceURLInDirectory (growlTunesBundleURL, CFSTR("growl"), CFSTR("png"), NULL);
							
							doNotificationWithKeysAndValues(alert_keys,alert_values,num);
							if(alert_values[4])
								CFRelease(alert_values[4]);
							if(growlTunesBundleURL)
								CFRelease(growlTunesBundleURL);
						}

						//read our settings
						readPreferences();

						if (growlBundle)
							CFRelease(growlBundle);
					} 
					else 
					{
						err = unimpErr;
					}
				}

			}
			break;

		case kPluginCleanupMessage:
			err = noErr;
			if (delegate.registrationDictionary)
				CFRelease(delegate.registrationDictionary);

			//Dispose of the hotkeys
			hotkey_release(&notificationHotKey);

			break;

		default:
			err = unimpErr;
			break;
	}
	
	GrowlLog("%s exited", __FUNCTION__);
	return err;
}
