/*
 * iTunes.h
 */

#import <AppKit/AppKit.h>
#import <ScriptingBridge/ScriptingBridge.h>


@class ITunesPrintSettings, ITunesApplication, ITunesItem, ITunesArtwork, ITunesEncoder, ITunesEQPreset, ITunesPlaylist, ITunesAudioCDPlaylist, ITunesDevicePlaylist, ITunesLibraryPlaylist, ITunesRadioTunerPlaylist, ITunesSource, ITunesTrack, ITunesAudioCDTrack, ITunesDeviceTrack, ITunesFileTrack, ITunesSharedTrack, ITunesURLTrack, ITunesUserPlaylist, ITunesFolderPlaylist, ITunesVisual, ITunesWindow, ITunesBrowserWindow, ITunesEQWindow, ITunesPlaylistWindow;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wfour-char-constants"

// printout kind
enum ITunesEKnd {
	ITunesEKndTrackListing = 'kTrk' /* a basic listing of tracks within a playlist */,
	ITunesEKndAlbumListing = 'kAlb' /* a listing of a playlist grouped by album */,
	ITunesEKndCdInsert = 'kCDi' /* a printout of the playlist for jewel case inserts */
};
typedef enum ITunesEKnd ITunesEKnd;

// printing error handling
enum ITunesEnum {
	ITunesEnumStandard = 'lwst' /* Standard PostScript error handling */,
	ITunesEnumDetailed = 'lwdt' /* print a detailed report of PostScript errors */
};
typedef enum ITunesEnum ITunesEnum;

// player state
enum ITunesEPlS {
	ITunesEPlSStopped = 'kPSS',
	ITunesEPlSPlaying = 'kPSP',
	ITunesEPlSPaused = 'kPSp',
	ITunesEPlSFastForwarding = 'kPSF',
	ITunesEPlSRewinding = 'kPSR'
};
typedef enum ITunesEPlS ITunesEPlS;

// repeat mode
enum ITunesERpt {
	ITunesERptOff = 'kRpO',
	ITunesERptOne = 'kRp1',
	ITunesERptAll = 'kAll'
};
typedef enum ITunesERpt ITunesERpt;

// visual size
enum ITunesEVSz {
	ITunesEVSzSmall = 'kVSS',
	ITunesEVSzMedium = 'kVSM',
	ITunesEVSzLarge = 'kVSL'
};
typedef enum ITunesEVSz ITunesEVSz;

// source
enum ITunesESrc {
	ITunesESrcLibrary = 'kLib',
	ITunesESrcIPod = 'kPod',
	ITunesESrcAudioCD = 'kACD',
	ITunesESrcMP3CD = 'kMCD',
	ITunesESrcDevice = 'kDev',
	ITunesESrcRadioTuner = 'kTun',
	ITunesESrcSharedLibrary = 'kShd',
	ITunesESrcUnknown = 'kUnk'
};
typedef enum ITunesESrc ITunesESrc;

// search area
enum ITunesESrA {
	ITunesESrAAlbums = 'kSrL' /* albums only */,
	ITunesESrAAll = 'kAll' /* all text fields */,
	ITunesESrAArtists = 'kSrR' /* artists only */,
	ITunesESrAComposers = 'kSrC' /* composers only */,
	ITunesESrADisplayed = 'kSrV' /* visible text fields */,
	ITunesESrASongs = 'kSrS' /* song names only */
};
typedef enum ITunesESrA ITunesESrA;

// special kind
enum ITunesESpK {
	ITunesESpKNone = 'kNon',
	ITunesESpKBooks = 'kSpA',
	ITunesESpKFolder = 'kSpF',
	ITunesESpKGenius = 'kSpG',
	ITunesESpKITunesU = 'kSpU',
	ITunesESpKLibrary = 'kSpL',
	ITunesESpKMovies = 'kSpI',
	ITunesESpKMusic = 'kSpZ',
	ITunesESpKPartyShuffle = 'kSpS',
	ITunesESpKPodcasts = 'kSpP',
	ITunesESpKPurchasedMusic = 'kSpM',
	ITunesESpKTVShows = 'kSpT'
};
typedef enum ITunesESpK ITunesESpK;

// video kind
enum ITunesEVdK {
	ITunesEVdKNone = 'kNon' /* not a video or unknown video kind */,
	ITunesEVdKMovie = 'kVdM' /* movie track */,
	ITunesEVdKMusicVideo = 'kVdV' /* music video track */,
	ITunesEVdKTVShow = 'kVdT' /* TV show track */
};
typedef enum ITunesEVdK ITunesEVdK;

// rating kind
enum ITunesERtK {
	ITunesERtKUser = 'kRtU' /* user-specified rating */,
	ITunesERtKComputed = 'kRtC' /* iTunes-computed rating */
};
typedef enum ITunesERtK ITunesERtK;

#pragma clang diagnostic pop // ignored "-Wfour-char-constants"


/*
 * Standard Suite
 */

@interface ITunesPrintSettings : SBObject

@property (readonly) NSInteger copies;  // the number of copies of a document to be printed
@property (readonly) BOOL collating;  // Should printed copies be collated?
@property (readonly) NSInteger startingPage;  // the first page of the document to be printed
@property (readonly) NSInteger endingPage;  // the last page of the document to be printed
@property (readonly) NSInteger pagesAcross;  // number of logical pages laid across a physical page
@property (readonly) NSInteger pagesDown;  // number of logical pages laid out down a physical page
@property (readonly) ITunesEnum errorHandling;  // how errors are handled
@property (copy, readonly) NSDate *requestedPrintTime;  // the time at which the desktop printer should print the document
@property (copy, readonly) NSArray *printerFeatures;  // printer specific options
@property (copy, readonly) NSString *faxNumber;  // for fax number
@property (copy, readonly) NSString *targetPrinter;  // for target printer

- (void) printPrintDialog:(BOOL)printDialog withProperties:(ITunesPrintSettings *)withProperties kind:(ITunesEKnd)kind theme:(NSString *)theme;  // Print the specified object(s)
- (void) close;  // Close an object
- (void) delete;  // Delete an element from an object
- (SBObject *) duplicateTo:(SBObject *)to;  // Duplicate one or more object(s)
- (BOOL) exists;  // Verify if an object exists
- (void) open;  // open the specified object(s)
- (void) playOnce:(BOOL)once;  // play the current track or the specified track or file.

@end



/*
 * iTunes Suite
 */

// The application program
@interface ITunesApplication : SBApplication

- (SBElementArray *) browserWindows;
- (SBElementArray *) encoders;
- (SBElementArray *) EQPresets;
- (SBElementArray *) EQWindows;
- (SBElementArray *) playlistWindows;
- (SBElementArray *) sources;
- (SBElementArray *) visuals;
- (SBElementArray *) windows;

@property (copy) ITunesEncoder *currentEncoder;  // the currently selected encoder (MP3, AIFF, WAV, etc.)
@property (copy) ITunesEQPreset *currentEQPreset;  // the currently selected equalizer preset
@property (copy, readonly) ITunesPlaylist *currentPlaylist;  // the playlist containing the currently targeted track
@property (copy, readonly) NSString *currentStreamTitle;  // the name of the current song in the playing stream (provided by streaming server)
@property (copy, readonly) NSString *currentStreamURL;  // the URL of the playing stream or streaming web site (provided by streaming server)
@property (copy, readonly) ITunesTrack *currentTrack;  // the current targeted track
@property (copy) ITunesVisual *currentVisual;  //  the currently selected visual plug-in
@property BOOL EQEnabled;  // is the equalizer enabled?
@property BOOL fixedIndexing;  // true if all AppleScript track indices should be independent of the play order of the owning playlist.
@property BOOL frontmost;  // is iTunes the frontmost application?
@property BOOL fullScreen;  // are visuals displayed using the entire screen?
@property (copy, readonly) NSString *name;  // the name of the application
@property BOOL mute;  // has the sound output been muted?
@property NSInteger playerPosition;  // the player’s position within the currently playing track in seconds.
@property (readonly) ITunesEPlS playerState;  // is iTunes stopped, paused, or playing?
@property (copy, readonly) SBObject *selection;  // the selection visible to the user
@property NSInteger soundVolume;  // the sound output volume (0 = minimum, 100 = maximum)
@property (copy, readonly) NSString *version;  // the version of iTunes
@property BOOL visualsEnabled;  // are visuals currently being displayed?
@property ITunesEVSz visualSize;  // the size of the displayed visual

- (void) printPrintDialog:(BOOL)printDialog withProperties:(ITunesPrintSettings *)withProperties kind:(ITunesEKnd)kind theme:(NSString *)theme;  // Print the specified object(s)
- (void) run;  // run iTunes
- (void) quit;  // quit iTunes
- (ITunesTrack *) add:(NSArray *)x to:(SBObject *)to;  // add one or more files to a playlist
- (void) backTrack;  // reposition to beginning of current track or go to previous track if already at start of current track
- (ITunesTrack *) convert:(NSArray *)x;  // convert one or more files or tracks
- (void) fastForward;  // skip forward in a playing track
- (void) nextTrack;  // advance to the next track in the current playlist
- (void) pause;  // pause playback
- (void) playOnce:(BOOL)once;  // play the current track or the specified track or file.
- (void) playpause;  // toggle the playing/paused state of the current track
- (void) previousTrack;  // return to the previous track in the current playlist
- (void) resume;  // disable fast forward/rewind and resume playback, if playing.
- (void) rewind;  // skip backwards in a playing track
- (void) stop;  // stop playback
- (void) update;  // update the specified iPod
- (void) eject;  // eject the specified iPod
- (void) subscribe:(NSString *)x;  // subscribe to a podcast feed
- (void) updateAllPodcasts;  // update all subscribed podcast feeds
- (void) updatePodcast;  // update podcast feed
- (void) openLocation:(NSString *)x;  // Opens a Music Store or audio stream URL

@end

// an item
@interface ITunesItem : SBObject

@property (copy, readonly) SBObject *container;  // the container of the item
- (NSInteger) id;  // the id of the item
@property (readonly) NSInteger index;  // The index of the item in internal application order.
@property (copy) NSString *name;  // the name of the item
@property (copy, readonly) NSString *persistentID;  // the id of the item as a hexidecimal string. This id does not change over time.

- (void) printPrintDialog:(BOOL)printDialog withProperties:(ITunesPrintSettings *)withProperties kind:(ITunesEKnd)kind theme:(NSString *)theme;  // Print the specified object(s)
- (void) close;  // Close an object
- (void) delete;  // Delete an element from an object
- (SBObject *) duplicateTo:(SBObject *)to;  // Duplicate one or more object(s)
- (BOOL) exists;  // Verify if an object exists
- (void) open;  // open the specified object(s)
- (void) playOnce:(BOOL)once;  // play the current track or the specified track or file.
- (void) reveal;  // reveal and select a track or playlist

@end

// a piece of art within a track
@interface ITunesArtwork : ITunesItem

@property (copy) NSImage *data;  // data for this artwork, in the form of a picture
@property (copy) NSString *objectDescription;  // description of artwork as a string
@property (readonly) BOOL downloaded;  // was this artwork downloaded by iTunes?
@property (copy, readonly) NSNumber *format;  // the data format for this piece of artwork
@property NSInteger kind;  // kind or purpose of this piece of artwork
@property (copy) NSData *rawData;  // data for this artwork, in original format


@end

// converts a track to a specific file format
@interface ITunesEncoder : ITunesItem

@property (copy, readonly) NSString *format;  // the data format created by the encoder


@end

// equalizer preset configuration
@interface ITunesEQPreset : ITunesItem

@property double band1;  // the equalizer 32 Hz band level (-12.0 dB to +12.0 dB)
@property double band2;  // the equalizer 64 Hz band level (-12.0 dB to +12.0 dB)
@property double band3;  // the equalizer 125 Hz band level (-12.0 dB to +12.0 dB)
@property double band4;  // the equalizer 250 Hz band level (-12.0 dB to +12.0 dB)
@property double band5;  // the equalizer 500 Hz band level (-12.0 dB to +12.0 dB)
@property double band6;  // the equalizer 1 kHz band level (-12.0 dB to +12.0 dB)
@property double band7;  // the equalizer 2 kHz band level (-12.0 dB to +12.0 dB)
@property double band8;  // the equalizer 4 kHz band level (-12.0 dB to +12.0 dB)
@property double band9;  // the equalizer 8 kHz band level (-12.0 dB to +12.0 dB)
@property double band10;  // the equalizer 16 kHz band level (-12.0 dB to +12.0 dB)
@property (readonly) BOOL modifiable;  // can this preset be modified?
@property double preamp;  // the equalizer preamp level (-12.0 dB to +12.0 dB)
@property BOOL updateTracks;  // should tracks which refer to this preset be updated when the preset is renamed or deleted?


@end

// a list of songs/streams
@interface ITunesPlaylist : ITunesItem

- (SBElementArray *) tracks;

@property (readonly) NSInteger duration;  // the total length of all songs (in seconds)
@property (copy) NSString *name;  // the name of the playlist
@property (copy, readonly) ITunesPlaylist *parent;  // folder which contains this playlist (if any)
@property BOOL shuffle;  // play the songs in this playlist in random order?
@property (readonly) long long size;  // the total size of all songs (in bytes)
@property ITunesERpt songRepeat;  // playback repeat mode
@property (readonly) ITunesESpK specialKind;  // special playlist kind
@property (copy, readonly) NSString *time;  // the length of all songs in MM:SS format
@property (readonly) BOOL visible;  // is this playlist visible in the Source list?

- (void) moveTo:(SBObject *)to;  // Move playlist(s) to a new location
- (ITunesTrack *) searchFor:(NSString *)for_ only:(ITunesESrA)only;  // search a playlist for tracks matching the search string. Identical to entering search text in the Search field in iTunes.

@end

// a playlist representing an audio CD
@interface ITunesAudioCDPlaylist : ITunesPlaylist

- (SBElementArray *) audioCDTracks;

@property (copy) NSString *artist;  // the artist of the CD
@property BOOL compilation;  // is this CD a compilation album?
@property (copy) NSString *composer;  // the composer of the CD
@property NSInteger discCount;  // the total number of discs in this CD’s album
@property NSInteger discNumber;  // the index of this CD disc in the source album
@property (copy) NSString *genre;  // the genre of the CD
@property NSInteger year;  // the year the album was recorded/released


@end

// a playlist representing the contents of a portable device
@interface ITunesDevicePlaylist : ITunesPlaylist

- (SBElementArray *) deviceTracks;


@end

// the master music library playlist
@interface ITunesLibraryPlaylist : ITunesPlaylist

- (SBElementArray *) fileTracks;
- (SBElementArray *) URLTracks;
- (SBElementArray *) sharedTracks;


@end

// the radio tuner playlist
@interface ITunesRadioTunerPlaylist : ITunesPlaylist

- (SBElementArray *) URLTracks;


@end

// a music source (music library, CD, device, etc.)
@interface ITunesSource : ITunesItem

- (SBElementArray *) audioCDPlaylists;
- (SBElementArray *) devicePlaylists;
- (SBElementArray *) libraryPlaylists;
- (SBElementArray *) playlists;
- (SBElementArray *) radioTunerPlaylists;
- (SBElementArray *) userPlaylists;

@property (readonly) long long capacity;  // the total size of the source if it has a fixed size
@property (readonly) long long freeSpace;  // the free space on the source if it has a fixed size
@property (readonly) ITunesESrc kind;

- (void) update;  // update the specified iPod
- (void) eject;  // eject the specified iPod

@end

// playable audio source
@interface ITunesTrack : ITunesItem

- (SBElementArray *) artworks;

@property (copy) NSString *album;  // the album name of the track
@property (copy) NSString *albumArtist;  // the album artist of the track
@property NSInteger albumRating;  // the rating of the album for this track (0 to 100)
@property (readonly) ITunesERtK albumRatingKind;  // the rating kind of the album rating for this track
@property (copy) NSString *artist;  // the artist/source of the track
@property (readonly) NSInteger bitRate;  // the bit rate of the track (in kbps)
@property double bookmark;  // the bookmark time of the track in seconds
@property BOOL bookmarkable;  // is the playback position for this track remembered?
@property NSInteger bpm;  // the tempo of this track in beats per minute
@property (copy) NSString *category;  // the category of the track
@property (copy) NSString *comment;  // freeform notes about the track
@property BOOL compilation;  // is this track from a compilation album?
@property (copy) NSString *composer;  // the composer of the track
@property (readonly) NSInteger databaseID;  // the common, unique ID for this track. If two tracks in different playlists have the same database ID, they are sharing the same data.
@property (copy, readonly) NSDate *dateAdded;  // the date the track was added to the playlist
@property (copy) NSString *objectDescription;  // the description of the track
@property NSInteger discCount;  // the total number of discs in the source album
@property NSInteger discNumber;  // the index of the disc containing this track on the source album
@property (readonly) double duration;  // the length of the track in seconds
@property BOOL enabled;  // is this track checked for playback?
@property (copy) NSString *episodeID;  // the episode ID of the track
@property NSInteger episodeNumber;  // the episode number of the track
@property (copy) NSString *EQ;  // the name of the EQ preset of the track
@property double finish;  // the stop time of the track in seconds
@property BOOL gapless;  // is this track from a gapless album?
@property (copy) NSString *genre;  // the music/audio genre (category) of the track
@property (copy) NSString *grouping;  // the grouping (piece) of the track. Generally used to denote movements within a classical work.
@property (copy, readonly) NSString *kind;  // a text description of the track
@property (copy) NSString *longDescription;
@property (copy) NSString *lyrics;  // the lyrics of the track
@property (copy, readonly) NSDate *modificationDate;  // the modification date of the content of this track
@property NSInteger playedCount;  // number of times this track has been played
@property (copy) NSDate *playedDate;  // the date and time this track was last played
@property (readonly) BOOL podcast;  // is this track a podcast episode?
@property NSInteger rating;  // the rating of this track (0 to 100)
@property (readonly) ITunesERtK ratingKind;  // the rating kind of this track
@property (copy, readonly) NSDate *releaseDate;  // the release date of this track
@property (readonly) NSInteger sampleRate;  // the sample rate of the track (in Hz)
@property NSInteger seasonNumber;  // the season number of the track
@property BOOL shufflable;  // is this track included when shuffling?
@property NSInteger skippedCount;  // number of times this track has been skipped
@property (copy) NSDate *skippedDate;  // the date and time this track was last skipped
@property (copy) NSString *show;  // the show name of the track
@property (copy) NSString *sortAlbum;  // override string to use for the track when sorting by album
@property (copy) NSString *sortArtist;  // override string to use for the track when sorting by artist
@property (copy) NSString *sortAlbumArtist;  // override string to use for the track when sorting by album artist
@property (copy) NSString *sortName;  // override string to use for the track when sorting by name
@property (copy) NSString *sortComposer;  // override string to use for the track when sorting by composer
@property (copy) NSString *sortShow;  // override string to use for the track when sorting by show name
@property (readonly) NSInteger size;  // the size of the track (in bytes)
@property double start;  // the start time of the track in seconds
@property (copy, readonly) NSString *time;  // the length of the track in MM:SS format
@property NSInteger trackCount;  // the total number of tracks on the source album
@property NSInteger trackNumber;  // the index of the track on the source album
@property BOOL unplayed;  // is this track unplayed?
@property ITunesEVdK videoKind;  // kind of video track
@property NSInteger volumeAdjustment;  // relative volume adjustment of the track (-100% to 100%)
@property NSInteger year;  // the year the track was recorded/released


@end

// a track on an audio CD
@interface ITunesAudioCDTrack : ITunesTrack

@property (copy, readonly) NSURL *location;  // the location of the file represented by this track


@end

// a track residing on a portable music player
@interface ITunesDeviceTrack : ITunesTrack


@end

// a track representing an audio file (MP3, AIFF, etc.)
@interface ITunesFileTrack : ITunesTrack

@property (copy) NSURL *location;  // the location of the file represented by this track

- (void) refresh;  // update file track information from the current information in the track’s file

@end

// a track residing in a shared library
@interface ITunesSharedTrack : ITunesTrack


@end

// a track representing a network stream
@interface ITunesURLTrack : ITunesTrack

@property (copy) NSString *address;  // the URL for this track

- (void) download;  // download podcast episode

@end

// custom playlists created by the user
@interface ITunesUserPlaylist : ITunesPlaylist

- (SBElementArray *) fileTracks;
- (SBElementArray *) URLTracks;
- (SBElementArray *) sharedTracks;

@property BOOL shared;  // is this playlist shared?
@property (readonly) BOOL smart;  // is this a Smart Playlist?


@end

// a folder that contains other playlists
@interface ITunesFolderPlaylist : ITunesUserPlaylist


@end

// a visual plug-in
@interface ITunesVisual : ITunesItem


@end

// any window
@interface ITunesWindow : ITunesItem

@property NSRect bounds;  // the boundary rectangle for the window
@property (readonly) BOOL closeable;  // does the window have a close box?
@property (readonly) BOOL collapseable;  // does the window have a collapse (windowshade) box?
@property BOOL collapsed;  // is the window collapsed?
@property NSPoint position;  // the upper left position of the window
@property (readonly) BOOL resizable;  // is the window resizable?
@property BOOL visible;  // is the window visible?
@property (readonly) BOOL zoomable;  // is the window zoomable?
@property BOOL zoomed;  // is the window zoomed?


@end

// the main iTunes window
@interface ITunesBrowserWindow : ITunesWindow

@property BOOL minimized;  // is the small player visible?
@property (copy, readonly) SBObject *selection;  // the selected songs
@property (copy) ITunesPlaylist *view;  // the playlist currently displayed in the window


@end

// the iTunes equalizer window
@interface ITunesEQWindow : ITunesWindow

@property BOOL minimized;  // is the small EQ window visible?


@end

// a sub-window showing a single playlist
@interface ITunesPlaylistWindow : ITunesWindow

@property (copy, readonly) SBObject *selection;  // the selected songs
@property (copy, readonly) ITunesPlaylist *view;  // the playlist displayed in the window


@end
