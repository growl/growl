//  GrowlTunes.c
//  GrowlTunesPlugin
//
//  Created by rudy on 11/27/05.
//  Copyright 2005-2007, The Growl Project. All rights reserved.


/**\
|**|	includes
\**/

#include "iTunesVisualAPI.h"
#import "GTPController.h"

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


#define GTP CFSTR("info.growl.growltunes")


/**\
|**|	exported function prototypes
\**/

extern OSStatus iTunesPluginMainMachO(OSType message, PluginMessageInfo *messageInfo, void *refCon);

/*
	Name: VisualPluginHandler
	Function: handles the event loop that iTunes provides through the iTunes visual plugin api
*/
static OSStatus VisualPluginHandler(OSType message, VisualPluginMessageInfo *messageInfo, void *refCon)
{
	OSStatus         err = noErr;
	VisualPluginData *visualPluginData;
	visualPluginData = (VisualPluginData *)refCon;

	
	/*if (message != 'vrnd') 
	{
		char *string = (char *)&message;
		NSLog(@"%s %c%c%c%c\n", __FUNCTION__, string[0], string[1], string[2], string[3]);
	}*/
	

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

			break;

		/*
			Sent when the visual plugin is unloaded
		*/
		case kVisualPluginCleanupMessage:
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
			//TODO: set this up to bring up the GTP settings dialog
			//run the cocoa dialog through the GTPC
			[[GTPController sharedInstance] showSettingsWindow];
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
		case kVisualPluginChangeTrackMessage:
		{
			if (messageInfo->u.playMessage.trackInfo)
				visualPluginData->trackInfo = *messageInfo->u.playMessage.trackInfoUnicode;
			else
				memset(&visualPluginData->trackInfo, 0, sizeof(visualPluginData->trackInfo));
			
			if (messageInfo->u.playMessage.streamInfo)
				visualPluginData->streamInfo = *messageInfo->u.playMessage.streamInfoUnicode;
			else
				memset(&visualPluginData->streamInfo, 0, sizeof(visualPluginData->streamInfo));

									 
			GTPNotification *notification = [[GTPController sharedInstance] notification];
			[notification setVisualPluginData:visualPluginData];
			[notification setState:(message == kVisualPluginPlayMessage)];
			//Get cover art
			Handle coverArt = NULL;
			OSType format;
			err = PlayerGetCurrentTrackCoverArt(visualPluginData->appCookie, visualPluginData->appProc, &coverArt, &format);
			if((err == noErr) && coverArt)
				[notification setArtwork:[NSData dataWithBytes:*coverArt length:GetHandleSize(coverArt)]];
			else
				[notification setArtwork:[[[NSWorkspace sharedWorkspace] iconForApplication:@"iTunes"] TIFFRepresentation]];
			
			if (coverArt)
				DisposeHandle(coverArt);
		
			[[GTPController sharedInstance] showCurrentTrack:nil];

			visualPluginData->playing = true;
			break;
		}

		/*
			Sent when the player changes the current track information.  This
			is used when the information about a track changes,or when the CD
			moves onto the next track.  The visual plugin should update any displayed
			information about the currently playing song.
		*/
		//case kVisualPluginChangeTrackMessage:
		//{
		//	break;
		//}

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

/*
	Name: RegisterVisualPlugin
	Function: registers GrowlTunes with the iTunes plugin api
*/
static OSStatus RegisterVisualPlugin(PluginMessageInfo *messageInfo)
{
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

/*
	Name: iTunesPluginMainMachO
	Function: the main entrypoint for the plugin, handles the init and dealloc messages that are given to it by iTunes
*/
GROWLTUNES_EXPORT OSStatus iTunesPluginMainMachO(OSType message, PluginMessageInfo *messageInfo, void *refCon)
{
#pragma unused(refCon)
	OSStatus		err = noErr;
	switch (message) 
	{
		case kPluginInitMessage:
			err = RegisterVisualPlugin(messageInfo);

			[[GTPController sharedInstance] setup];
			
			break;

		case kPluginCleanupMessage:
			err = noErr;

			break;

		default:
			err = unimpErr;
			break;
	}
	
	return err;
}
