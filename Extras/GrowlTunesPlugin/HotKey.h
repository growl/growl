/*
 *  HotKey.h
 *  GrowlTunes
 *
 *  Created by rudy on 12/20/05.
 *  Copyright 2005-2007 The Growl Project. All rights reserved.
 *
 */

#ifndef HOTKEY_H_INCLUDED
#define HOTKEY_H_INCLUDED

#include <Carbon/Carbon.h>
#include "Growl/Growl.h"
#include "GrowlLog.h"

#define kNoHotKeyModifierCode (UInt32)-1
#define kNoHotKeyKeyCode (UInt32)-1

typedef struct hotkey_s {
	EventTypeSpec				mEventSpec[2]; 
	UInt32						mKeyCode;
	CFMutableStringRef			mKeyString;
	UInt32						mModifierCode;
	CFMutableStringRef			mModifierString;
		
	CFMutableStringRef			mHotKeyString;
		
	EventHotKeyID				mHotKeyID;
	EventHotKeyRef				mHotKeyEventReference;
	EventHandlerRef				mHotKeyEventHandler;
	EventHandlerUPP				mHotKeyEventHandlerProcPtr;
	struct Growl_Notification	*mData;
} hotkey_t;

void hotkey_init(hotkey_t *hotkey, OSType inSignature, UInt32 inIdentifier, UInt32 inKeyCode, UInt32 inModifierCode, EventHandlerUPP inEventHandler);
void hotkey_release(hotkey_t *hotkey);

void hotkey_setKeyCode(hotkey_t *hotkey, UInt32 inCode);
UInt32 hotkey_keyCode(const hotkey_t *hotkey);
void hotkey_setModifierCode(hotkey_t *hotkey, UInt32 inModifiers);
UInt32 hotkey_modifierCode(const hotkey_t *hotkey);

CFStringRef hotkey_hotKeyString(hotkey_t *hotkey);
	
void hotkey_setData(hotkey_t *hotkey, struct Growl_Notification *inData);
void hotkey_setEventHandler(hotkey_t *hotkey, EventHandlerUPP inEventHandler);
EventHandlerUPP hotkey_eventHandler(const hotkey_t *hotkey);
		
void hotkey_setKeyCodeAndModifiers(hotkey_t *hotkey, UInt32 inCode, UInt32 inModifiers);
CFStringRef hotkey_stringFromModifiers(const hotkey_t *hotkey);
CFStringRef hotkey_stringFromKeyCode(const hotkey_t *hotkey);

void hotkey_unregisterHotKeyAndHandler(hotkey_t *hotkey);
void hotkey_swapHotKeys(hotkey_t *hotkey);

#endif
