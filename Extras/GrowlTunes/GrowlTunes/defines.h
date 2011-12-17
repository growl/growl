#define StateStopped ITunesEPlSStopped
#define StatePlaying ITunesEPlSPlaying
#define StatePaused ITunesEPlSPaused
#define StateFastForward ITunesEPlSFastForwarding
#define StateRewind ITunesEPlSRewinding

//#define RENOTIFY_STREAM_KEY @"reNotifyOnStreamingTrackChange"
#define NOTIFY_ITUNES_FRONTMOST @"notifyWhenITunesIsFrontmost"

#define ITUNES_BUNDLE_ID @"com.apple.iTunes"
#define PLAYER_INFO_ID ITUNES_BUNDLE_ID ".playerInfo"
#define SOURCE_SAVED_ID ITUNES_BUNDLE_ID ".sourceSaved"

#define NotifierChangedTracks           @"Changed Tracks"
#define NotifierPaused                  @"Paused"
#define NotifierStopped                 @"Stopped"
#define NotifierStarted                 @"started"

#define NotifierChangedTracksReadable   NSLocalizedString(@"Changed Tracks", nil)
#define NotifierPausedReadable          NSLocalizedString(@"Paused", nil)
#define NotifierStoppedReadable         NSLocalizedString(@"Stopped", nil)
#define NotifierStartedReadable         NSLocalizedString(@"Started", nil)


#define formattingTypes                 @"podcast", @"stream", @"show", @"movie", @"musicVideo", @"music"
#define formattingAttributes            @"title", @"line1", @"line2", @"line3"

#define TokenAlbum                      @"album"
#define TokenAlbumReadable              NSLocalizedString(@"Album", nil)
#define TokenAlbumArtist                @"albumArtist"
#define TokenAlbumArtistReadable        NSLocalizedString(@"Album Artist", nil)
#define TokenArtist                     @"artist"
#define TokenArtistReadable             NSLocalizedString(@"Artist", nil)
#define TokenBestArtist                 @"bestArtist"
#define TokenBestArtistReadable         NSLocalizedString(@"Album Artist or Artist", nil)
#define TokenBestDescription            @"bestDescription"
#define TokenBestDescriptionReadable    NSLocalizedString(@"Long Description, Comment, or Description", nil)
#define TokenComment                    @"comment"
#define TokenCommentReadable            NSLocalizedString(@"Comment", nil)
#define TokenDescription                @"description"
#define TokenDescriptionReadable        NSLocalizedString(@"Description", nil)
#define TokenEpisodeID                  @"episodeID"
#define TokenEpisodeIDReadable          NSLocalizedString(@"Episode ID", nil)
#define TokenEpisodeNumber              @"episodeNumber"
#define TokenEpisodeNumberReadable      NSLocalizedString(@"Episode Number", nil)
#define TokenLongDescription            @"longDescription"
#define TokenLongDescriptionReadable    NSLocalizedString(@"Long Description", nil)
#define TokenName                       @"name"
#define TokenNameReadable               NSLocalizedString(@"Name", nil)
#define TokenSeasonNumber               @"seasonNumber"
#define TokenSeasonNumberReadable       NSLocalizedString(@"Season Number", nil)
#define TokenShow                       @"show"
#define TokenShowReadable               NSLocalizedString(@"Show", nil)
#define TokenStreamTitle                @"streamTitle"
#define TokenStreamTitleReadable        NSLocalizedString(@"Stream Title", nil)
#define TokenTrackCount                 @"trackCount"
#define TokenTrackCountReadable         NSLocalizedString(@"Track Count", nil)
#define TokenTrackNumber                @"trackNumber"
#define TokenTrackNumberReadable        NSLocalizedString(@"Track Number", nil)
#define TokenTime                       @"time"
#define TokenTimeReadable               NSLocalizedString(@"Play Time", nil)
#define TokenVideoKindName              @"videoKindName"
#define TokenVideoKindNameReadable      NSLocalizedString(@"Video Kind", nil)
