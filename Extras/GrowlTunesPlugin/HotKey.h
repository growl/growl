/*
 *  HotKey.h
 *  GrowlTunes
 *
 *  Created by rudy on 12/20/05.
 *  Copyright 2005 The Growl Project. All rights reserved.
 *
 */

#include <Carbon/Carbon.h>
#include "Growl/Growl.h"

#define kNoHotKeyModifierCode (UInt32)-1
#define kNoHotKeyKeyCode (UInt32)-1

#ifdef __cplusplus
extern "C" {
#endif

extern void CFLog(int priority, CFStringRef format, ...);

#ifdef __cplusplus
}
#endif

class HotKey {

public:
	HotKey(OSType inSignature, UInt32 inIdentifier, UInt32 inKeyCode, UInt32 inModifierCode, EventHandlerUPP inEventHandler);
	~HotKey();
	
	void setKeyCode (UInt32 inCode);
	UInt32 keyCode (void);
	void setModifierCode (UInt32 inModifiers);
	UInt32 modifierCode (void);
	
	CFStringRef hotKeyString (void);
	
	void setData (Growl_Notification *inData);
	void setEventHandler( EventHandlerUPP inEventHandler );	
	EventHandlerUPP eventHandler (void);
		
	void setKeyCodeAndModifiers(UInt32 inCode, UInt32 inModifiers);
	CFStringRef stringFromModifiers (void);
	CFStringRef stringFromKeyCode (void);
	
	void unregisterHotKeyAndHandler();
	void swapHotKeys(void);

private:
	void _updateModifiersString (void);
	void _updateKeyCodeString (void);
	
	void _registerHotKeyAndHandler (void);
	
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
	Growl_Notification			*mData;
};
