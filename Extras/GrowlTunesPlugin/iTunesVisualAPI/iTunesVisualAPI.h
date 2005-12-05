/*
     File:       iTunesVisualAPI.h

     Contains:   iTunes Visual Plug-ins interfaces

     Version:    Technology: iTunes
                 Release:    1.1

     Copyright:  © 2003 by Apple Computer, Inc., all rights reserved.

     Bugs?:      For bug reports, consult the following page on
                 the World Wide Web:

                     http://developer.apple.com/bugreporter/

*/
#ifndef ITUNESVISUALAPI_H_
#define ITUNESVISUALAPI_H_

#include "iTunesAPI.h"

#if PRAGMA_ONCE
#pragma once
#endif

#ifdef __cplusplus
extern "C" {
#endif

#if PRAGMA_STRUCT_ALIGN
    #pragma options align=power
#elif PRAGMA_STRUCT_PACKPUSH
    #pragma pack(push, 2)
#elif PRAGMA_STRUCT_PACK
    #pragma pack(2)
#endif

struct ITTrackInfoV1 {
	ITTIFieldMask		validFields;
	UInt32				reserved;						/* Must be zero */

	Str255				name;
	Str255				fileName;
	Str255				artist;
	Str255				album;

	Str255				genre;
	Str255				kind;

	UInt32				trackNumber;
	UInt32				numTracks;

	UInt16				year;
	SInt16				soundVolumeAdjustment;			/* Valid range is -255 to +255 */

	Str255				eqPresetName;
	Str255				comments;

	UInt32				totalTimeInMS;
	UInt32				startTimeInMS;
	UInt32				stopTimeInMS;

	UInt32				sizeInBytes;

	UInt32				bitRate;
	UInt32				sampleRateFixed;

	OSType				fileType;

	UInt32				date;
	UInt32				unusedReserved2;				/* Must be zero */

	ITTrackAttributes	attributes;
	ITTrackAttributes	validAttributes;				/* Mask indicating which attributes are applicable */

	OSType				fileCreator;
};
typedef struct ITTrackInfoV1 ITTrackInfoV1;

enum {
	kCurrentITStreamInfoVersion = 1
};

struct ITStreamInfoV1 {
	SInt32				version;
	Str255				streamTitle;
	Str255				streamURL;
	Str255				streamMessage;
};
typedef struct ITStreamInfoV1 ITStreamInfoV1;


enum {
	kITVisualPluginMajorMessageVersion = 10,
	kITVisualPluginMinorMessageVersion = 5
};

enum {
	/* VisualPlugin messages */

	kVisualPluginIdleMessage			= 'null',

	kVisualPluginInitMessage			= 'init',
	kVisualPluginCleanupMessage			= 'clr ',

	kVisualPluginConfigureMessage		= 'cnfg',	/* Configure the plugin (may not be enabled) */

	kVisualPluginEnableMessage			= 'von ',	/* Turn on the module (automatic)*/
	kVisualPluginDisableMessage			= 'voff',	/* Turn off the module */

	kVisualPluginShowWindowMessage			= 'show',	/* Show the plugin window (allocate large memory here!) */
	kVisualPluginHideWindowMessage			= 'hide',	/* Hide the plugin window (deallocate large memory here!) */

	kVisualPluginSetWindowMessage			= 'swin',	/* Change the window parameters */

	kVisualPluginRenderMessage			= 'vrnd',	/* Render to window */

	kVisualPluginUpdateMessage			= 'vupd',	/* Update the window */

	kVisualPluginPlayMessage			= 'vply',	/* Playing a track */
	kVisualPluginChangeTrackMessage			= 'ctrk',	/* Change track (for CD continuous play) */
	kVisualPluginStopMessage			= 'vstp',	/* Stopping a track */
	kVisualPluginSetPositionMessage			= 'setp',	/* Setting the position of a track */

	kVisualPluginPauseMessage			= 'vpau',	/* Pausing a track (unused - Pause is stop) */
	kVisualPluginUnpauseMessage			= 'vunp',	/* Unpausing a track (unused - Pause is stop) */

	kVisualPluginEventMessage			= 'vevt',	/* Mac-event. */

	kVisualPluginDisplayChangedMessage	= 'dchn'	/* Something about display state changed */
};

/*
	VisualPlugin messages
*/

enum {
	kVisualMaxDataChannels		= 2,

	kVisualNumWaveformEntries	= 512,
	kVisualNumSpectrumEntries	= 512
};

enum {
	/* ShowWindow options */

	kWindowIsFullScreen = (1L << 0),
	kWindowIsStretched	= (1L << 1)
};

struct RenderVisualData {
	UInt8							numWaveformChannels;
	UInt8							waveformData[kVisualMaxDataChannels][kVisualNumWaveformEntries];

	UInt8							numSpectrumChannels;
	UInt8							spectrumData[kVisualMaxDataChannels][kVisualNumSpectrumEntries];
};
typedef struct RenderVisualData RenderVisualData;

struct VisualPluginInitMessage {
	UInt32							messageMajorVersion;	/* Input */
	UInt32							messageMinorVersion;	/* Input */
	NumVersion						appVersion;				/* Input */

	void *							appCookie;				/* Input */
	ITAppProcPtr					appProc;				/* Input */

	OptionBits						options;				/* Output */
	void *							refCon;					/* Output */
};
typedef struct VisualPluginInitMessage VisualPluginInitMessage;

struct VisualPluginShowWindowMessage {
	CGrafPtr						port;					/* Input */
	Rect							drawRect;				/* Input */
	OptionBits						options;				/* Input */
};
typedef struct VisualPluginShowWindowMessage VisualPluginShowWindowMessage;

struct VisualPluginSetWindowMessage {
	CGrafPtr						port;					/* Input */
	Rect							drawRect;				/* Input */
	OptionBits						options;				/* Input */
};
typedef struct VisualPluginSetWindowMessage VisualPluginSetWindowMessage;

struct VisualPluginPlayMessage {
	ITTrackInfoV1 *					trackInfo;				/* Input */
	ITStreamInfoV1 *				streamInfo;				/* Input */
	SInt32							volume;					/* Input */

	UInt32							bitRate;				/* Input */

	SoundComponentData				soundFormat;			/* Input */
	ITTrackInfo *					trackInfoUnicode;		/* Input */
	ITStreamInfo *					streamInfoUnicode;		/* Input */
};
typedef struct VisualPluginPlayMessage VisualPluginPlayMessage;

struct VisualPluginChangeTrackMessage {
	ITTrackInfoV1 *					trackInfo;				/* Input */
	ITStreamInfoV1 *				streamInfo;				/* Input */
	ITTrackInfo *					trackInfoUnicode;		/* Input */
	ITStreamInfo *					streamInfoUnicode;		/* Input */
};
typedef struct VisualPluginChangeTrackMessage VisualPluginChangeTrackMessage;

struct VisualPluginRenderMessage {
	RenderVisualData *				renderData;				/* Input */
	UInt32							timeStampID;			/* Input */
};
typedef struct VisualPluginRenderMessage VisualPluginRenderMessage;

struct VisualPluginSetPositionMessage {
	UInt32							positionTimeInMS;		/* Input */
};
typedef struct VisualPluginSetPositionMessage VisualPluginSetPositionMessage;

struct VisualPluginEventMessage {
	EventRecord *					event;					/* Input */
};
typedef struct VisualPluginEventMessage VisualPluginEventMessage;

enum {
	kVisualDisplayDepthChanged 	= 1 << 0,					/* the display's depth has changed */
	kVisualDisplayRectChanged	= 1 << 1,					/* the display's location changed */
	kVisualWindowMovedMoved 	= 1 << 2					/* the window has moved location */
};

struct VisualPluginDisplayChangedMessage {
	UInt32							flags;		/* Input */
};
typedef struct VisualPluginDisplayChangedMessage VisualPluginDisplayChangedMessage;

struct VisualPluginMessageInfo {
	union {
		VisualPluginInitMessage				initMessage;
		VisualPluginShowWindowMessage		showWindowMessage;
		VisualPluginSetWindowMessage		setWindowMessage;
		VisualPluginPlayMessage				playMessage;
		VisualPluginChangeTrackMessage		changeTrackMessage;
		VisualPluginRenderMessage			renderMessage;
		VisualPluginSetPositionMessage		setPositionMessage;
		VisualPluginDisplayChangedMessage	displayChangedMessage;
	} u;
};
typedef struct VisualPluginMessageInfo VisualPluginMessageInfo;

#if PRAGMA_STRUCT_ALIGN
    #pragma options align=reset
#elif PRAGMA_STRUCT_PACKPUSH
    #pragma pack(pop)
#elif PRAGMA_STRUCT_PACK
    #pragma pack()
#endif

#ifdef __cplusplus
}
#endif

#endif /* ITUNESVISUALAPI_H_ */
