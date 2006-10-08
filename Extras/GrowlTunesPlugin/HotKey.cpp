/*
 *  HotKey.cpp
 *  GrowlTunes
 *
 *  Created by rudy on 12/20/05.
 *  Copyright 2005 __MyCompanyName__. All rights reserved.
 *
 */

#include "HotKey.h"

HotKey::HotKey(OSType inSignature, UInt32 inIdentifier, UInt32 inKeyCode, UInt32 inModifierCode, EventHandlerUPP inEventHandler) {
	printf("%s\n", __FUNCTION__);
	
	mHotKeyEventReference = NULL;
	mHotKeyEventHandler = NULL;
	mHotKeyEventHandlerProcPtr = NULL;
	mData = NULL;
	mKeyCode = 0;
	mModifierCode = 0;
	
	//setup our event specifier
	mEventSpec[0].eventClass = kEventClassKeyboard;
	mEventSpec[0].eventKind = kEventHotKeyPressed;
	
	mEventSpec[1].eventClass = kEventClassKeyboard;
	mEventSpec[1].eventKind = kEventHotKeyReleased;
						
	//setup our global hot key
	mHotKeyID.signature = inSignature;
	mHotKeyID.id = inIdentifier;
	
	mHotKeyEventHandlerProcPtr = inEventHandler;
	
	setKeyCode(inKeyCode);
	setModifierCode(inModifierCode);
	
	//setKeyCodeAndModifiers(inKeyCode, inModifierCode);
	if(inEventHandler) {
		_registerHotKeyAndHandler();
	} else {
		printf("%s\n", "failed on event handler");	
	}
}
	
HotKey::~HotKey() {
	printf("%s\n", __FUNCTION__);
	//unregister it at the end to make sure that we don't trigger it accidentally
	UnregisterEventHotKey(mHotKeyEventReference);
			
	//kill our event handler if it is still around
	RemoveEventHandler(mHotKeyEventHandler);
		
	if(mKeyString)
		CFRelease(mKeyString);
	if(mModifierString)
		CFRelease(mModifierString);
}

void HotKey::setKeyCodeAndModifiers(UInt32 inCode, UInt32 inModifiers) {
	printf("%s %ld %ld\n", __FUNCTION__, inCode, inModifiers);
	if((inCode == 0) && (inModifiers == 0))
		unregisterHotKeyAndHandler();
	setKeyCode(inCode);
	setModifierCode(inModifiers);
	_registerHotKeyAndHandler();
}

void HotKey::setKeyCode (UInt32 inCode) {
	printf("%s\n", __FUNCTION__);
	mKeyCode = inCode;
	_updateKeyCodeString();
}
	
UInt32 HotKey::keyCode (void) {
	printf("%s\n", __FUNCTION__);
	return mKeyCode;
}
	
void HotKey::setModifierCode (UInt32 inModifiers) {
	printf("%s\n", __FUNCTION__);
	mModifierCode = inModifiers;
	_updateModifiersString();
}
	
UInt32 HotKey::modifierCode (void) {
	printf("%s\n", __FUNCTION__);
	return mModifierCode;
}

void HotKey::setData (Growl_Notification *inData) {
	printf("%s %p %p\n", __FUNCTION__, mData, inData);
	mData = inData;
	if(mHotKeyEventHandler) {
		RemoveEventHandler(mHotKeyEventHandler);
		printf("%p ", mHotKeyEventHandler);
	}
	if(mData) {
		InstallEventHandler(GetEventDispatcherTarget(), mHotKeyEventHandlerProcPtr, 2, mEventSpec, &mData, &mHotKeyEventHandler);		
	}
}

CFStringRef HotKey::hotKeyString (void) {
	printf("%s\n", __FUNCTION__);
	mHotKeyString = CFStringCreateMutableCopy(kCFAllocatorDefault, 0, mModifierString);
	CFStringAppend(mHotKeyString, CFSTR(" "));
	CFShow(mKeyString);
	CFShow(mModifierString);
	CFStringAppend(mHotKeyString, mKeyString);
	return mHotKeyString;
}

void HotKey::setEventHandler( EventHandlerUPP inEventHandler ) {
	printf("%s\n", __FUNCTION__);
	if(mHotKeyEventHandlerProcPtr)
		RemoveEventHandler(mHotKeyEventHandler);
	mHotKeyEventHandlerProcPtr = inEventHandler;
	if(mData)
		InstallEventHandler(GetEventDispatcherTarget(), mHotKeyEventHandlerProcPtr, 2, mEventSpec, mData, &mHotKeyEventHandler);
}

EventHandlerUPP HotKey::eventHandler (void) {
	printf("%s\n", __FUNCTION__);
	return mHotKeyEventHandlerProcPtr;
}
	
CFStringRef HotKey::stringFromModifiers (void) {
	printf("%s\n", __FUNCTION__);
	return mModifierString;
}

CFStringRef HotKey::stringFromKeyCode (void) {
	printf("%s\n", __FUNCTION__);
	return mKeyString;
}
	
void HotKey::_updateKeyCodeString (void) {
	printf("%s\n", __FUNCTION__);
	UCKeyboardLayout	*uchrData;
    void		*KCHRData;
    SInt32		keyLayoutKind;
	KeyboardLayoutRef currentLayout;
	UInt32		keyTranslateState;
    UInt32		deadKeyState;
	OSStatus err = noErr;
	CFLocaleRef locale = CFLocaleCopyCurrent();

	err = KLGetCurrentKeyboardLayout( &currentLayout );
	if(err != noErr)
		return;
	
	err = KLGetKeyboardLayoutProperty( currentLayout, kKLKind, (const void **)&keyLayoutKind );
	if (err != noErr) 
		return;

	if (keyLayoutKind == kKLKCHRKind) {
		err = KLGetKeyboardLayoutProperty( currentLayout, kKLKCHRData, (const void **)&KCHRData );
		if (err != noErr) 
			return;
	} else {
		err = KLGetKeyboardLayoutProperty( currentLayout, kKLuchrData, (const void **)&uchrData );
		if (err !=  noErr) 
			return;
	}
	
	if (keyLayoutKind == kKLKCHRKind) {
        UInt32 charCode = KeyTranslate( KCHRData, mKeyCode, &keyTranslateState );
        char theChar = ((char *)&charCode)[3];
        CFStringRef temp = CFStringCreateWithCharacters(kCFAllocatorDefault, (UniChar*)theChar, 1);
		mKeyString = CFStringCreateMutableCopy(kCFAllocatorDefault, 0,temp);
		CFStringCapitalize(mKeyString, locale);
		if(temp)
			CFRelease(temp);
		return;
    } else {
        UniCharCount maxStringLength = 4, actualStringLength;
        UniChar unicodeString[4];
        err = UCKeyTranslate( uchrData, mKeyCode, kUCKeyActionDisplay, 0, LMGetKbdType(), kUCKeyTranslateNoDeadKeysBit, &deadKeyState, maxStringLength, &actualStringLength, unicodeString );
        CFStringRef temp = CFStringCreateWithCharacters(kCFAllocatorDefault, unicodeString, 1);
		mKeyString = CFStringCreateMutableCopy(kCFAllocatorDefault, 0,temp);
		CFStringCapitalize(mKeyString, locale);
		if(temp)
			CFRelease(temp);
		return;
    }    
	return;
}

void HotKey::_updateModifiersString (void) {
	printf("%s\n", __FUNCTION__);
	static long modToChar[4][2] =
	{
		{ cmdKey, 		0x23180000 },
		{ optionKey,	0x23250000 },
		{ controlKey,	0x005E0000 },
		{ shiftKey,		0x21e70000 }
	};
		
	mModifierString = CFStringCreateMutable(kCFAllocatorDefault, 0);
	CFStringRef charString;
	long i;
	
	for(i=0; i < 4; i++) {
		if(mModifierCode & modToChar[i][0] ) {
			charString = CFStringCreateWithCharacters(kCFAllocatorDefault, ((const UniChar*)&modToChar[i][1]), 1);
			CFStringAppend(mModifierString, charString);
			if(charString)
				CFRelease(charString);
		}
	}
	
	if(!mModifierString)
			CFStringAppend(mModifierString, CFSTR(""));
}

void HotKey::unregisterHotKeyAndHandler() {
	printf("%s\n", __FUNCTION__);
	if(mHotKeyEventHandler) {
		RemoveEventHandler(mHotKeyEventHandler);
		printf("%p ", mHotKeyEventHandler);
	}
	if(mHotKeyEventReference) {
		UnregisterEventHotKey(mHotKeyEventReference);
		printf("%p\n", mHotKeyEventReference);
	}
}
	
void HotKey::_registerHotKeyAndHandler () {
	printf("%s\n", __FUNCTION__);
	CFLog(1, CFSTR("a %p %p\n"), mHotKeyEventHandler, mHotKeyEventReference);	
	unregisterHotKeyAndHandler();
	if((!mHotKeyEventHandler) && (!mHotKeyEventReference)) {
		RegisterEventHotKey (mKeyCode, mModifierCode, mHotKeyID, GetEventDispatcherTarget(), 0, &mHotKeyEventReference);
		InstallEventHandler(GetEventDispatcherTarget(), mHotKeyEventHandlerProcPtr, 2, mEventSpec, mData, &mHotKeyEventHandler);
	}
}


void HotKey::swapHotKeys(void) {
	UnregisterEventHotKey(mHotKeyEventReference);
	RemoveEventHandler(mHotKeyEventHandler);
	RegisterEventHotKey (mKeyCode, mModifierCode, mHotKeyID, GetEventDispatcherTarget(), 0, &mHotKeyEventReference);
	InstallEventHandler(GetEventDispatcherTarget(), mHotKeyEventHandlerProcPtr, 2, mEventSpec, mData, &mHotKeyEventHandler);
}
