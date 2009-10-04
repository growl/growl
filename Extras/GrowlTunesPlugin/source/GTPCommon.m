//
//  GTPCommon.m
//  GrowlTunes
//
//  Created by Rudy Richter on 9/27/09.
//  Copyright 2009 The Growl Project. All rights reserved.
//

#import "GTPCommon.h"

NSString *APP_NAME = @"GrowlTunes";

NSString *ITUNES_APP_NAME = @"iTunes.app";
NSString *ITUNES_BUNDLE_ID = @"com.apple.itunes";

NSString *ITUNES_TRACK_CHANGED = @"Changed Tracks";
NSString *ITUNES_PAUSED = @"Paused";
NSString *ITUNES_STOPPED = @"Stopped";
NSString *ITUNES_PLAYING = @"Started Playing";

NSString *GTPBundleIdentifier = @"info.growl.growltunesplugin";

//preferences keys
NSString *GTPKeyCode = @"key";
NSString *GTPModifiers = @"modifiers";

NSString *tokenTitles[10] = { @"Track", @"Title", @"Artist", @"Album", @"Genre", @"Disc", @"Composer", @"Year", @"Rating", @"Length" };
NSString *mDefaultTitleFormat = @"<<Track>>. <<Title>>";
NSString *mDefaultMessageFormat = @"<<Length>>, (<<Rating>>)\n<<Album>>\n<<Artist>>";
