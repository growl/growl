/*
     File:       iTunesAPI.c

     Contains:   iTunes Plug-ins interfaces

     Version:    Technology: iTunes
                 Release:    1.1

     Copyright:  © 2003 by Apple Computer, Inc., all rights reserved.

     Bugs?:      For bug reports, consult the following page on
                 the World Wide Web:

                     http://developer.apple.com/bugreporter/

*/
#include "iTunesAPI.h"
#include "iTunesVisualAPI.h"

// SetNumVersion
//
void SetNumVersion (NumVersion *numVersion, UInt8 majorRev, UInt8 minorAndBugRev, UInt8 stage, UInt8 nonRelRev)
{
	numVersion->majorRev		= majorRev;
	numVersion->minorAndBugRev	= minorAndBugRev;
	numVersion->stage			= stage;
	numVersion->nonRelRev		= nonRelRev;
}


// ITCallApplication
//
OSStatus ITCallApplication (void *appCookie, ITAppProcPtr handler, OSType message, PlayerMessageInfo *messageInfo)
{
	PlayerMessageInfo	localMessageInfo;

	if (!messageInfo) {
		memset(&localMessageInfo, 0, sizeof(localMessageInfo));

		messageInfo = &localMessageInfo;
	}

	messageInfo->messageMajorVersion = kITCurrentPluginMajorMessageVersion;
	messageInfo->messageMinorVersion = kITCurrentPluginMinorMessageVersion;
	messageInfo->messageInfoSize	 = sizeof(PlayerMessageInfo);

	return handler(appCookie, message, messageInfo);
}


// PlayerSetFullScreen
//
OSStatus PlayerSetFullScreen (void *appCookie, ITAppProcPtr appProc, Boolean fullScreen)
{
	PlayerMessageInfo	messageInfo;

	memset(&messageInfo, 0, sizeof(messageInfo));

	messageInfo.u.setFullScreenMessage.fullScreen = fullScreen;

	return ITCallApplication(appCookie, appProc, kPlayerSetFullScreenMessage, &messageInfo);
}


// PlayerSetFullScreenOptions
//
OSStatus PlayerSetFullScreenOptions (void *appCookie, ITAppProcPtr appProc, SInt16 minBitDepth, SInt16 maxBitDepth, SInt16 preferredBitDepth, SInt16 desiredWidth, SInt16 desiredHeight)
{
	PlayerMessageInfo	messageInfo;

	memset(&messageInfo, 0, sizeof(messageInfo));

	messageInfo.u.setFullScreenOptionsMessage.minBitDepth		= minBitDepth;
	messageInfo.u.setFullScreenOptionsMessage.maxBitDepth		= maxBitDepth;
	messageInfo.u.setFullScreenOptionsMessage.preferredBitDepth = preferredBitDepth;
	messageInfo.u.setFullScreenOptionsMessage.desiredWidth		= desiredWidth;
	messageInfo.u.setFullScreenOptionsMessage.desiredHeight		= desiredHeight;

	return ITCallApplication(appCookie, appProc, kPlayerSetFullScreenOptionsMessage, &messageInfo);
}

// PlayerGetCurrentTrackCoverArt
//
OSStatus PlayerGetCurrentTrackCoverArt (void *appCookie, ITAppProcPtr appProc, Handle *coverArt, OSType *coverArtFormat)
{
	OSStatus			status;
	PlayerMessageInfo	messageInfo;

	memset(&messageInfo, 0, sizeof(messageInfo));

	messageInfo.u.getCurrentTrackCoverArtMessage.coverArt = nil;

	status = ITCallApplication(appCookie, appProc, kPlayerGetCurrentTrackCoverArtMessage, &messageInfo);

	*coverArt = messageInfo.u.getCurrentTrackCoverArtMessage.coverArt;
	if (coverArtFormat)
		*coverArtFormat = messageInfo.u.getCurrentTrackCoverArtMessage.coverArtFormat;
	return status;
}

// PlayerGetPluginData
//
OSStatus PlayerGetPluginData (void *appCookie, ITAppProcPtr appProc, void *dataPtr, UInt32 dataBufferSize, UInt32 *dataSize)
{
	OSStatus			status;
	PlayerMessageInfo	messageInfo;

	memset(&messageInfo, 0, sizeof(messageInfo));

	messageInfo.u.getPluginDataMessage.dataPtr			= dataPtr;
	messageInfo.u.getPluginDataMessage.dataBufferSize	= dataBufferSize;

	status = ITCallApplication(appCookie, appProc, kPlayerGetPluginDataMessage, &messageInfo);

	if (dataSize)
		*dataSize = messageInfo.u.getPluginDataMessage.dataSize;

	return status;
}

// PlayerSetPluginData
//
OSStatus PlayerSetPluginData (void *appCookie, ITAppProcPtr appProc, void *dataPtr, UInt32 dataSize)
{
	PlayerMessageInfo	messageInfo;

	memset(&messageInfo, 0, sizeof(messageInfo));

	messageInfo.u.setPluginDataMessage.dataPtr	= dataPtr;
	messageInfo.u.setPluginDataMessage.dataSize	= dataSize;

	return ITCallApplication(appCookie, appProc, kPlayerSetPluginDataMessage, &messageInfo);
}


// PlayerGetPluginNamedData
//
OSStatus PlayerGetPluginNamedData (void *appCookie, ITAppProcPtr appProc, ConstStringPtr dataName, void *dataPtr, UInt32 dataBufferSize, UInt32 *dataSize)
{
	OSStatus			status;
	PlayerMessageInfo	messageInfo;

	memset(&messageInfo, 0, sizeof(messageInfo));

	messageInfo.u.getPluginNamedDataMessage.dataName		= dataName;
	messageInfo.u.getPluginNamedDataMessage.dataPtr			= dataPtr;
	messageInfo.u.getPluginNamedDataMessage.dataBufferSize	= dataBufferSize;

	status = ITCallApplication(appCookie, appProc, kPlayerGetPluginNamedDataMessage, &messageInfo);

	if (dataSize)
		*dataSize = messageInfo.u.getPluginNamedDataMessage.dataSize;

	return status;
}


// PlayerSetPluginNamedData
//
OSStatus PlayerSetPluginNamedData (void *appCookie, ITAppProcPtr appProc, ConstStringPtr dataName, void *dataPtr, UInt32 dataSize)
{
	PlayerMessageInfo	messageInfo;

	memset(&messageInfo, 0, sizeof(messageInfo));

	messageInfo.u.setPluginNamedDataMessage.dataName	= dataName;
	messageInfo.u.setPluginNamedDataMessage.dataPtr		= dataPtr;
	messageInfo.u.setPluginNamedDataMessage.dataSize	= dataSize;

	return ITCallApplication(appCookie, appProc, kPlayerSetPluginNamedDataMessage, &messageInfo);
}


// PlayerIdle
//
OSStatus PlayerIdle (void *appCookie, ITAppProcPtr appProc)
{
	return ITCallApplication(appCookie, appProc, kPlayerIdleMessage, nil);
}


// PlayerShowAbout
//
void PlayerShowAbout (void *appCookie, ITAppProcPtr appProc)
{
	ITCallApplication(appCookie, appProc, kPlayerShowAboutMessage, nil);
}


// PlayerOpenURL
//
void PlayerOpenURL (void *appCookie, ITAppProcPtr appProc, SInt8 *string, UInt32 length)
{
	PlayerMessageInfo	messageInfo;

	memset(&messageInfo, 0, sizeof(messageInfo));

	messageInfo.u.openURLMessage.url	= string;
	messageInfo.u.openURLMessage.length	= length;

	ITCallApplication(appCookie, appProc, kPlayerOpenURLMessage, &messageInfo);
}

// PlayerUnregisterPlugin
//
OSStatus PlayerUnregisterPlugin (void *appCookie, ITAppProcPtr appProc, PlayerMessageInfo *messageInfo)
{
	return ITCallApplication(appCookie, appProc, kPlayerUnregisterPluginMessage, messageInfo);
}


// PlayerRegisterVisualPlugin
//
OSStatus PlayerRegisterVisualPlugin (void *appCookie, ITAppProcPtr appProc, PlayerMessageInfo *messageInfo)
{
	return ITCallApplication(appCookie, appProc, kPlayerRegisterVisualPluginMessage, messageInfo);
}

// PlayerGetPluginITFileSpec
//
OSStatus PlayerGetPluginITFileSpec (void *appCookie, ITAppProcPtr appProc, ITFileSpec *pluginFileSpec)
{
	PlayerMessageInfo	messageInfo;

	memset(&messageInfo, 0, sizeof(messageInfo));
	
	messageInfo.u.getPluginITFileSpecMessage.fileSpec = pluginFileSpec;
	
	return ITCallApplication(appCookie, appProc, kPlayerGetPluginITFileSpecMessage, &messageInfo);
}


// PlayerGetFileTrackInfo
//
OSStatus PlayerGetFileTrackInfo (void *appCookie, ITAppProcPtr appProc, const ITFileSpec *fileSpec, ITTrackInfo *trackInfo)
{
	PlayerMessageInfo	messageInfo;

	memset(&messageInfo, 0, sizeof(messageInfo));

	messageInfo.u.getFileTrackInfoMessage.fileSpec 	= fileSpec;
	messageInfo.u.getFileTrackInfoMessage.trackInfo = trackInfo;
	
	return ITCallApplication(appCookie, appProc, kPlayerGetFileTrackInfoMessage, &messageInfo);
}

// PlayerSetFileTrackInfo
//
OSStatus PlayerSetFileTrackInfo (void *appCookie, ITAppProcPtr appProc, const ITFileSpec *fileSpec, const ITTrackInfo *trackInfo)
{
	PlayerMessageInfo	messageInfo;

	memset(&messageInfo, 0, sizeof(messageInfo));
	
	messageInfo.u.setFileTrackInfoMessage.fileSpec 	= fileSpec;
	messageInfo.u.setFileTrackInfoMessage.trackInfo = trackInfo;
	
	return ITCallApplication(appCookie, appProc, kPlayerSetFileTrackInfoMessage, &messageInfo);
}

// PlayerGetITTrackInfoSize
//
OSStatus PlayerGetITTrackInfoSize (void *appCookie, ITAppProcPtr appProc, UInt32 appPluginMajorVersion, UInt32 appPluginMinorVersion, UInt32 *itTrackInfoSize)
{
	PlayerMessageInfo	messageInfo;
	OSStatus			status;
	
	/*
	 Note: appPluginMajorVersion and appPluginMinorVersion are the versions given to the plugin by iTunes in the plugin's init message.
			  These versions are *not* the version of the API used when the plugin was compiled.
	 */
	
	*itTrackInfoSize = 0;

	memset(&messageInfo, 0, sizeof(messageInfo));
	
	status = ITCallApplication(appCookie, appProc, kPlayerGetITTrackInfoSizeMessage, &messageInfo);
	if( status == noErr ) {
		*itTrackInfoSize = messageInfo.u.getITTrackInfoSizeMessage.itTrackInfoSize;
	} else if (appPluginMajorVersion == 10 && appPluginMinorVersion == 2) {
		// iTunes 2.0.x
		
		*itTrackInfoSize = ((UInt32) &((ITTrackInfo *) 0)->composer);
		
		status = noErr;
	} else if (appPluginMajorVersion == 10 && appPluginMinorVersion == 3) {
		// iTunes 3.0.x
		
		*itTrackInfoSize = ((UInt32) &((ITTrackInfo *) 0)->beatsPerMinute);
		
		status = noErr;
	} else {
		// iTunes 4.0 and later implement the kPlayerGetITTrackInfoSizeMessage message. If you got here
		// then the appPluginMajorVersion or appPluginMinorVersion are incorrect.
		
		status = paramErr;
	}
	
	if (status == noErr && (*itTrackInfoSize) > sizeof(ITTrackInfo) ) {
		// iTunes is using a larger ITTrackInfo than the one when this plugin was compiled. Pin *itTrackInfoSize to the plugin's known size
		
		*itTrackInfoSize = sizeof(ITTrackInfo);
	}
	
	return status;
}
