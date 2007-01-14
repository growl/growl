/*
 *  HotKey.c
 *  GrowlTunes
 *
 *  Created by rudy on 12/20/05.
 *  Copyright 2005-2007, The Growl Project. All rights reserved.
 *
 */

#include "HotKey.h"

static void _updateModifiersString(hotkey_t *hotkey) 
{
	GrowlLog("%s entered", __FUNCTION__);
	static long modToChar[4][2] =
	{
		{ cmdKey, 		0x2318 },
		{ optionKey,	0x2325 },
		{ controlKey,	0x005E },
		{ shiftKey,		0x21e7 }
	};

	if (hotkey->mModifierString)
		CFRelease(hotkey->mModifierString);
	hotkey->mModifierString = CFStringCreateMutable(kCFAllocatorDefault, 0);
	
	
	for (int i=0; i < 4; ++i)
		if (hotkey->mModifierCode & modToChar[i][0])
			CFStringAppendCharacters(hotkey->mModifierString, ((const UniChar *)(&(modToChar[i][1]))), 1);

	GrowlLog("%s exited", __FUNCTION__);
}

void hotkey_unregisterHotKeyAndHandler(hotkey_t *hotkey) 
{
	GrowlLog("%s entered", __FUNCTION__);
	if (hotkey->mHotKeyEventHandler) 
	{
		RemoveEventHandler(hotkey->mHotKeyEventHandler);
		//printf("%p ", hotkey->mHotKeyEventHandler);
	}
	if (hotkey->mHotKeyEventReference) 
	{
		UnregisterEventHotKey(hotkey->mHotKeyEventReference);
		//printf("%p\n", hotkey->mHotKeyEventReference);
	}
	GrowlLog("%s exited", __FUNCTION__);
}

static void _registerHotKeyAndHandler(hotkey_t *hotkey) 
{
	GrowlLog("%s entered", __FUNCTION__);
	//GrowlLog(1, CFSTR("a %p %p\n"), hotkey->mHotKeyEventHandler, hotkey->mHotKeyEventReference);
	hotkey_unregisterHotKeyAndHandler(hotkey);
	if ((!hotkey->mHotKeyEventHandler) && (!hotkey->mHotKeyEventReference)) 
	{
		RegisterEventHotKey(hotkey->mKeyCode, hotkey->mModifierCode, hotkey->mHotKeyID, GetEventDispatcherTarget(), 0, &hotkey->mHotKeyEventReference);
		InstallEventHandler(GetEventDispatcherTarget(), hotkey->mHotKeyEventHandlerProcPtr, 2, hotkey->mEventSpec, hotkey->mData, &hotkey->mHotKeyEventHandler);
	}
	GrowlLog("%s exited", __FUNCTION__);
}

static void _updateKeyCodeString(hotkey_t *hotkey) 
{
	GrowlLog("%s entered", __FUNCTION__);
	UCKeyboardLayout  *uchrData;
	void              *KCHRData;
	SInt32            keyLayoutKind;
	KeyboardLayoutRef currentLayout;
	UInt32            keyTranslateState;
	UInt32            deadKeyState;
	OSStatus          err = noErr;
	CFLocaleRef       locale = CFLocaleCopyCurrent();

	err = KLGetCurrentKeyboardLayout(&currentLayout);
	if (err != noErr)
	{
		GrowlLog("%s exited", __FUNCTION__);
		return;
	}
	
	err = KLGetKeyboardLayoutProperty(currentLayout, kKLKind, (const void **)&keyLayoutKind);
	if (err != noErr)
	{
		GrowlLog("%s exited", __FUNCTION__);
		return;
	}
	
	if (keyLayoutKind == kKLKCHRKind) 
	{
		err = KLGetKeyboardLayoutProperty(currentLayout, kKLKCHRData, (const void **)&KCHRData);
		if (err != noErr)
		{
			GrowlLog("%s exited", __FUNCTION__);
			return;
		}
	} 
	else 
	{
		err = KLGetKeyboardLayoutProperty(currentLayout, kKLuchrData, (const void **)&uchrData);
		if (err != noErr)
		{
			GrowlLog("%s exited", __FUNCTION__);
			return;
		}
	}

	if (hotkey->mKeyString)
		CFRelease(hotkey->mKeyString);

	if (keyLayoutKind == kKLKCHRKind) 
	{
		UInt32 charCode = KeyTranslate(KCHRData, hotkey->mKeyCode, &keyTranslateState);
		char theChar = ((char *)&charCode)[3];
		hotkey->mKeyString = CFStringCreateMutable(kCFAllocatorDefault, 0);
		CFStringAppendCharacters(hotkey->mKeyString, (UniChar *)&theChar, 1);
		CFStringCapitalize(hotkey->mKeyString, locale);
	}
	else 
	{
		UniCharCount maxStringLength = 4, actualStringLength;
		UniChar unicodeString[4];
		err = UCKeyTranslate(uchrData, hotkey->mKeyCode, kUCKeyActionDisplay, 0, LMGetKbdType(), kUCKeyTranslateNoDeadKeysBit, &deadKeyState, maxStringLength, &actualStringLength, unicodeString);
		hotkey->mKeyString = CFStringCreateMutable(kCFAllocatorDefault, 0);
		CFStringAppendCharacters(hotkey->mKeyString, unicodeString, actualStringLength);
	 	CFStringCapitalize(hotkey->mKeyString, locale);
	}

	CFRelease(locale);
	GrowlLog("%s exited", __FUNCTION__);
}

void hotkey_init(hotkey_t *hotkey, OSType inSignature, UInt32 inIdentifier, UInt32 inKeyCode, UInt32 inModifierCode, EventHandlerUPP inEventHandler) 
{
	GrowlLog("%s entered", __FUNCTION__);

	//setup our event specifier
	hotkey->mEventSpec[0].eventClass = kEventClassKeyboard;
	hotkey->mEventSpec[0].eventKind = kEventHotKeyPressed;

	hotkey->mEventSpec[1].eventClass = kEventClassKeyboard;
	hotkey->mEventSpec[1].eventKind = kEventHotKeyReleased;

	hotkey->mKeyCode = 0;
	hotkey->mKeyString = NULL;
	hotkey->mModifierCode = 0;
	hotkey->mModifierString = NULL;
	hotkey->mHotKeyString = NULL;

	//setup our global hot key
	hotkey->mHotKeyID.signature = inSignature;
	hotkey->mHotKeyID.id = inIdentifier;

	hotkey->mHotKeyEventReference = NULL;
	hotkey->mHotKeyEventHandler = NULL;
	hotkey->mHotKeyEventHandlerProcPtr = inEventHandler;
	hotkey->mData = NULL;

	hotkey_setKeyCode(hotkey, inKeyCode);
	hotkey_setModifierCode(hotkey, inModifierCode);

	//setKeyCodeAndModifiers(inKeyCode, inModifierCode);
	if (inEventHandler) 
	{
		_registerHotKeyAndHandler(hotkey);
	} 
	else 
	{
		printf("%s\n", "failed on event handler");
	}
	GrowlLog("%s exited", __FUNCTION__);
}

void hotkey_release(hotkey_t *hotkey)
{
	GrowlLog("%s entered", __FUNCTION__);
	//unregister it at the end to make sure that we don't trigger it accidentally
	UnregisterEventHotKey(hotkey->mHotKeyEventReference);

	//kill our event handler if it is still around
	RemoveEventHandler(hotkey->mHotKeyEventHandler);

	if (hotkey->mKeyString)
		CFRelease(hotkey->mKeyString);
	if (hotkey->mModifierString)
		CFRelease(hotkey->mModifierString);
	if (hotkey->mHotKeyString)
		CFRelease(hotkey->mHotKeyString);

	GrowlLog("%s exited", __FUNCTION__);
}

void hotkey_setKeyCodeAndModifiers(hotkey_t *hotkey, UInt32 inCode, UInt32 inModifiers) 
{
	GrowlLog("%s entered", __FUNCTION__);
	if ((inCode == 0) && (inModifiers == 0))
		hotkey_unregisterHotKeyAndHandler(hotkey);
	hotkey_setKeyCode(hotkey, inCode);
	hotkey_setModifierCode(hotkey, inModifiers);
	_registerHotKeyAndHandler(hotkey);
	GrowlLog("%s exited", __FUNCTION__);
}

void hotkey_setKeyCode(hotkey_t *hotkey, UInt32 inCode) 
{
	GrowlLog("%s entered", __FUNCTION__);
	hotkey->mKeyCode = inCode;
	_updateKeyCodeString(hotkey);
	GrowlLog("%s exited", __FUNCTION__);
}

UInt32 hotkey_keyCode(const hotkey_t *hotkey) 
{
	GrowlLog("%s entered", __FUNCTION__);
	GrowlLog("%s exited", __FUNCTION__);
	return hotkey->mKeyCode;
}

void hotkey_setModifierCode(hotkey_t *hotkey, UInt32 inModifiers) 
{
	GrowlLog("%s entered", __FUNCTION__);
	hotkey->mModifierCode = inModifiers;
	_updateModifiersString(hotkey);
	GrowlLog("%s exited", __FUNCTION__);
}

UInt32 hotkey_modifierCode(const hotkey_t *hotkey) 
{
	GrowlLog("%s entered", __FUNCTION__);
	GrowlLog("%s exited", __FUNCTION__);
	return hotkey->mModifierCode;
}

void hotkey_setData(hotkey_t *hotkey, struct Growl_Notification *inData) 
{
	GrowlLog("%s entered", __FUNCTION__);
	hotkey->mData = inData;
	if (hotkey->mHotKeyEventHandler) 
	{
		RemoveEventHandler(hotkey->mHotKeyEventHandler);
		//printf("%p ", hotkey->mHotKeyEventHandler);
	}
	if (hotkey->mData)
		InstallEventHandler(GetEventDispatcherTarget(), hotkey->mHotKeyEventHandlerProcPtr, 2, hotkey->mEventSpec, &hotkey->mData, &hotkey->mHotKeyEventHandler);
	GrowlLog("%s exited", __FUNCTION__);
}

CFStringRef hotkey_hotKeyString(hotkey_t *hotkey) 
{
	GrowlLog("%s entered", __FUNCTION__);
	GrowlShow(hotkey->mKeyString);
	GrowlShow(hotkey->mModifierString);
	if (hotkey->mHotKeyString)
		CFRelease(hotkey->mHotKeyString);
	hotkey->mHotKeyString = CFStringCreateMutableCopy(kCFAllocatorDefault, 0, hotkey->mModifierString);
	CFStringAppend(hotkey->mHotKeyString, CFSTR(" "));
	CFStringAppend(hotkey->mHotKeyString, hotkey->mKeyString);
	GrowlLog("%s exited", __FUNCTION__);
	return hotkey->mHotKeyString;
}

void hotkey_setEventHandler(hotkey_t *hotkey, EventHandlerUPP inEventHandler) 
{
	GrowlLog("%s entered", __FUNCTION__);
	if (hotkey->mHotKeyEventHandlerProcPtr)
		RemoveEventHandler(hotkey->mHotKeyEventHandler);
	hotkey->mHotKeyEventHandlerProcPtr = inEventHandler;
	if (hotkey->mData)
		InstallEventHandler(GetEventDispatcherTarget(), hotkey->mHotKeyEventHandlerProcPtr, 2, hotkey->mEventSpec, hotkey->mData, &hotkey->mHotKeyEventHandler);
	GrowlLog("%s exited", __FUNCTION__);
}

EventHandlerUPP hotkey_eventHandler(const hotkey_t *hotkey) 
{
	GrowlLog("%s entered", __FUNCTION__);
	GrowlLog("%s exited", __FUNCTION__);
	return hotkey->mHotKeyEventHandlerProcPtr;
}

CFStringRef hotkey_stringFromModifiers(const hotkey_t *hotkey) 
{
	GrowlLog("%s entered", __FUNCTION__);
	GrowlLog("%s exited", __FUNCTION__);
	return hotkey->mModifierString;
}

CFStringRef hotkey_stringFromKeyCode(const hotkey_t *hotkey) 
{
	GrowlLog("%s entered", __FUNCTION__);
	GrowlLog("%s exited", __FUNCTION__);
	return hotkey->mKeyString;
}

void hotkey_swapHotKeys(hotkey_t *hotkey) 
{
	GrowlLog("%s entered", __FUNCTION__);
	UnregisterEventHotKey(hotkey->mHotKeyEventReference);
	RemoveEventHandler(hotkey->mHotKeyEventHandler);
	RegisterEventHotKey(hotkey->mKeyCode, hotkey->mModifierCode, hotkey->mHotKeyID, GetEventDispatcherTarget(), 0, &hotkey->mHotKeyEventReference);
	InstallEventHandler(GetEventDispatcherTarget(), hotkey->mHotKeyEventHandlerProcPtr, 2, hotkey->mEventSpec, hotkey->mData, &hotkey->mHotKeyEventHandler);
	GrowlLog("%s exited", __FUNCTION__);
}
