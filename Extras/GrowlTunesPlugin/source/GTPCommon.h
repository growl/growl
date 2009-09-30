/*
 *  GTPCommon.h
 *  GrowlTunes
 *
 *  Created by Rudy Richter on 9/27/09.
 *  Copyright 2009 The Growl Project. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>
#import "iTunesVisualAPI.h"

extern NSString *APP_NAME;

extern NSString *ITUNES_APP_NAME;
extern NSString *ITUNES_BUNDLE_ID;

extern NSString *ITUNES_TRACK_CHANGED;
extern NSString *ITUNES_PAUSED;
extern NSString *ITUNES_STOPPED;
extern NSString *ITUNES_PLAYING;

extern NSString *GTPBundleIdentifier;

extern NSString *GTPKeyCode;
extern NSString *GTPModifiers;

extern NSString *tokenTitles [];
extern NSString *mDefaultTitleFormat;
extern NSString *mDefaultMessageFormat;

typedef struct VisualPluginData {
	void				*appCookie;
	ITAppProcPtr		appProc;
	
	ITTrackInfo			trackInfo;
	ITStreamInfo		streamInfo;
	
	Boolean				playing;
	Boolean				padding[3];
} VisualPluginData;
