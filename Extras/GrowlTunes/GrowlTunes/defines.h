#pragma mark iTunes.h shortcuts
#define StateStopped                    ITunesEPlSStopped
#define StatePlaying                    ITunesEPlSPlaying
#define StatePaused                     ITunesEPlSPaused
#define StateFastForward                ITunesEPlSFastForwarding
#define StateRewind                     ITunesEPlSRewinding

#pragma mark beta expiry
#if defined(BETA) && BETA
#   define DAYSTOEXPIRY                 14
#endif

#pragma mark compilation metadata
#define COMPILED_ON                     __DATE__
#define COMPILED_AT                     __TIME__
#define COMPILER_VERSION                __VERSION__

#pragma mark defaults setting names
#define NOTIFY_ITUNES_FRONTMOST         @"notifyWhenITunesIsFrontmost"
#define NOTIFY_ON_PAUSE						@"notifyOnPause"
#define NOTIFY_ON_STOP						@"notifyOnStop"

#pragma mark bundle/notification IDs
#define ITUNES_BUNDLE_ID                @"com.apple.iTunes"
#define PLAYER_INFO_ID                  ITUNES_BUNDLE_ID ".playerInfo"
#define SOURCE_SAVED_ID                 ITUNES_BUNDLE_ID ".sourceSaved"

#pragma mark growl notification names
#define NotifierChangedTracks           @"Changed Tracks"
#define NotifierPaused                  @"Paused"
#define NotifierStopped                 @"Stopped"
#define NotifierStarted                 @"started"
#define NotifierChangedTracksReadable   NSLocalizedString(@"Changed Tracks", nil)
#define NotifierPausedReadable          NSLocalizedString(@"Paused", nil)
#define NotifierStoppedReadable         NSLocalizedString(@"Stopped", nil)
#define NotifierStartedReadable         NSLocalizedString(@"Started", nil)

#pragma mark formatting helpers
#define podcastReadable                 NSLocalizedStringWithDefaultValue(@"PodcastFormatTitle", @"Localizable", [NSBundle mainBundle], @"Podcast", nil)
#define streamReadable                  NSLocalizedStringWithDefaultValue(@"StreamFormatTitle", @"Localizable", [NSBundle mainBundle], @"Stream", nil)
#define showReadable                    NSLocalizedStringWithDefaultValue(@"ShowFormatTitle", @"Localizable", [NSBundle mainBundle], @"Show", nil)
#define movieReadable                   NSLocalizedStringWithDefaultValue(@"MovieFormatTitle", @"Localizable", [NSBundle mainBundle], @"Movie", nil)
#define musicVideoReadable              NSLocalizedStringWithDefaultValue(@"MusicVideoFormatTitle", @"Localizable", [NSBundle mainBundle], @"Music Video", nil)
#define musicReadable                   NSLocalizedStringWithDefaultValue(@"MusicFormatTitle", @"Localizable", [NSBundle mainBundle], @"Music", nil)

#define formattingTypes                 @"podcast", @"stream", @"show", @"movie", @"musicVideo", @"music"
#define typeFileNames						@"Podcast", @"Stream", @"Show", @"Movie", @"MusicVideo", @"Music"
//#define formattingTypesReadable       podcastReadable, streamReadable, showReadable, movieReadable, musicVideoReadable, musicReadable
#define formattingAttributes            @"titleArray", @"descriptionArray"

#pragma mark formatting token names
#define TokenAlbum                      @"album"
#define TokenAlbumArtist                @"albumArtist"
#define TokenArtist                     @"artist"
#define TokenBestArtist                 @"bestArtist"
#define TokenBestDescription            @"bestDescription"
#define TokenComment                    @"comment"
#define TokenDescription                @"description"
#define TokenEpisodeID                  @"episodeID"
#define TokenEpisodeNumber              @"episodeNumber"
#define TokenLongDescription            @"longDescription"
#define TokenName                       @"name"
#define TokenSeasonNumber               @"seasonNumber"
#define TokenShow                       @"show"
#define TokenStreamTitle                @"streamTitle"
#define TokenTrackCount                 @"trackCount"
#define TokenTrackNumber                @"trackNumber"
#define TokenTime                       @"time"
#define TokenVideoKindName              @"videoKindName"
#define TokenRating						@"rating"
#define TokenEpisode					@"episode"

#pragma mark formatting token text
#define TokenAlbumReadable              NSLocalizedString(@"Album", nil)
#define TokenAlbumArtistReadable        NSLocalizedString(@"Album Artist", nil)
#define TokenArtistReadable             NSLocalizedString(@"Artist", nil)
#define TokenBestArtistReadable         NSLocalizedString(@"Album Artist or Artist", nil)
#define TokenBestDescriptionReadable    NSLocalizedString(@"Long Description, Comment, or Description", nil)
#define TokenCommentReadable            NSLocalizedString(@"Comment", nil)
#define TokenDescriptionReadable        NSLocalizedString(@"Description", nil)
#define TokenEpisodeIDReadable          NSLocalizedString(@"Episode ID", nil)
#define TokenEpisodeNumberReadable      NSLocalizedString(@"Episode Number", nil)
#define TokenLongDescriptionReadable    NSLocalizedString(@"Long Description", nil)
#define TokenNameReadable               NSLocalizedString(@"Name", nil)
#define TokenSeasonNumberReadable       NSLocalizedString(@"Season Number", nil)
#define TokenShowReadable               NSLocalizedString(@"Show", nil)
#define TokenStreamTitleReadable        NSLocalizedString(@"Stream Title", nil)
#define TokenTrackCountReadable         NSLocalizedString(@"Track Count", nil)
#define TokenTrackNumberReadable        NSLocalizedString(@"Track Number", nil)
#define TokenTimeReadable               NSLocalizedString(@"Play Time", nil)
#define TokenVideoKindNameReadable      NSLocalizedString(@"Video Kind", nil)
#define TokenRatingReadable				NSLocalizedString(@"Rating", nil)
#define TokenEpisodeReadable			NSLocalizedString(@"Episode", nil)

#pragma mark menu entries
#define MenuPlayPause                   NSLocalizedStringWithDefaultValue(@"PlayPauseMenuTitle", @"Localizable", [NSBundle mainBundle], @"▶ Play/Pause", @"Play pause menu text")
#define MenuNextTrack                   NSLocalizedStringWithDefaultValue(@"NextTrackMenuTitle", @"Localizable", [NSBundle mainBundle], @"→ Next Track", @"Next track menu text")
#define MenuPreviousTrack               NSLocalizedStringWithDefaultValue(@"PreviousTrackMenuTitle", @"Localizable", [NSBundle mainBundle], @"← Previous Track", @"Previous track menu text")
#define MenuRating						NSLocalizedStringWithDefaultValue(@"RatingsMenuTitle", @"Localizable", [NSBundle mainBundle], @"Rating", @"ratings menu text")
#define MenuVolume						NSLocalizedStringWithDefaultValue(@"VolumeMenuTitle", @"Localizable", [NSBundle mainBundle], @"Volume", @"volume menu text")
#define MenuBringITunesToFront			NSLocalizedStringWithDefaultValue(@"BringiTunesToFrontMenuTitle", @"Localizable", [NSBundle mainBundle], @"Bring iTunes to Front", @"bring itunes to front menu text")
#define MenuQuitBoth					NSLocalizedStringWithDefaultValue(@"QuitBothMenuTitle", @"Localizable", [NSBundle mainBundle], @"Quit Both", @"quit both menu text")
#define MenuQuitITunes					NSLocalizedStringWithDefaultValue(@"QuitiTunesMenuTitle", @"Localizable", [NSBundle mainBundle], @"Quit iTunes", @"quit itunes menu text")
#define MenuQuitGrowlTunes				NSLocalizedStringWithDefaultValue(@"QuitGrowlTunesMenuTitle", @"Localizable", [NSBundle mainBundle], @"Quit GrowlTunes", @"quit growltunes menu text")
#define MenuStartITunes					NSLocalizedStringWithDefaultValue(@"StartiTunesMenuTitle", @"Localizable", [NSBundle mainBundle], @"Start iTunes", @"start itunes menu text")
#define MenuPreferences					NSLocalizedStringWithDefaultValue(@"PreferencesMenuTitle", @"Localizable", [NSBundle mainBundle], @"Preferences", @"Preferences menu text")

#pragma mark prefs window entries
#define PreferencesWindowTitle			NSLocalizedStringWithDefaultValue(@"PreferencesWindowTitle", @"Localizable", [NSBundle mainBundle], @"Preferences", @"title for the Preferences Window")
#define GeneralTabTitle			NSLocalizedStringWithDefaultValue(@"GeneralTabTitle", @"Localizable", [NSBundle mainBundle], @"General", @"title for the General Tab")
#define FormatTabTitle			NSLocalizedStringWithDefaultValue(@"FormatTabTitle", @"Localizable", [NSBundle mainBundle], @"Media Types", @"title for the Format Tab")
#define HotKeysTabTitle			NSLocalizedStringWithDefaultValue(@"HotKeysTabTitle", @"Localizable", [NSBundle mainBundle], @"Shortcuts", @"title for the HotKeys Tab")

#define StartAtLoginTitle				NSLocalizedStringWithDefaultValue(@"StartAtLoginTitle", @"Localizable", [NSBundle mainBundle], @"Start at login:", @"title for the start at login switch")
#define IconPositionTitle				NSLocalizedStringWithDefaultValue(@"IconPositionTitle", @"Localizable", [NSBundle mainBundle], @"Icon position:", @"title for the icon position pop-up")
#define MenuIconPositionTitle				NSLocalizedStringWithDefaultValue(@"MenuIconPositionTitle", @"Localizable", [NSBundle mainBundle], @"Menu", @"title for the menu icon position menu item")
#define DockIconPositionTitle				NSLocalizedStringWithDefaultValue(@"DockIconPositionTitle", @"Localizable", [NSBundle mainBundle], @"Dock", @"title for the dock icon position menu item")
#define BothIconPositionTitle				NSLocalizedStringWithDefaultValue(@"BothIconPositionTitle", @"Localizable", [NSBundle mainBundle], @"Both", @"title for the both icon position menu item")
#define NoneIconPositionTitle				NSLocalizedStringWithDefaultValue(@"NoneIconPositionTitle", @"Localizable", [NSBundle mainBundle], @"None", @"title for the none icon position menu item")

#define NotifyWheniTunesIsInFront		NSLocalizedStringWithDefaultValue(@"NotifyWheniTunesIsInFrontTitle", @"Localizable", [NSBundle mainBundle], @"Notify when iTunes is in the front", @"title for the notify when in foreground checkbox")
#define NotifyOnPause		NSLocalizedStringWithDefaultValue(@"NotifyOnPauseTitle", @"Localizable", [NSBundle mainBundle], @"Notify on Pause", @"title for the notify on pause checkbox")
#define NotifyOnStop		NSLocalizedStringWithDefaultValue(@"NotifyOnStopTitle", @"Localizable", [NSBundle mainBundle], @"Notify on Stop", @"title for the notify on stop checkbox")

#define NotificationTitleTitle		NSLocalizedStringWithDefaultValue(@"NotificationTitleTitle", @"Localizable", [NSBundle mainBundle], @"Title:", @"title for the notification title format field")
#define NotificationDescriptionTitle		NSLocalizedStringWithDefaultValue(@"NotificationDescriptionTitle", @"Localizable", [NSBundle mainBundle], @"Description:", @"title for the notification description format field")
#define AvailableTagsTitle		NSLocalizedStringWithDefaultValue(@"AvailableTagsTitle", @"Localizable", [NSBundle mainBundle], @"Available Tags:", @"title for the available tags cloud field")


#pragma mark HotKeys Tab
#define NowPlayingTitle		NSLocalizedStringWithDefaultValue(@"NowPlayingTitle", @"Localizable", [NSBundle mainBundle], @"Now Playing:", @"title for the available tags cloud field")
#define VolumeUpTitle		NSLocalizedStringWithDefaultValue(@"VolumeUpTitle", @"Localizable", [NSBundle mainBundle], @"Volume Up:", @"title for the available tags cloud field")
#define VolumeDownTitle		NSLocalizedStringWithDefaultValue(@"VolumeDownTitle", @"Localizable", [NSBundle mainBundle], @"Volume Down:", @"title for the available tags cloud field")
#define NextTrackTitle		NSLocalizedStringWithDefaultValue(@"NextTrackTitle", @"Localizable", [NSBundle mainBundle], @"Next Track:", @"title for the available tags cloud field")
#define PreviousTrackTitle		NSLocalizedStringWithDefaultValue(@"PreviousTrackTitle", @"Localizable", [NSBundle mainBundle], @"Previous Track:", @"title for the available tags cloud field")
#define PlayPauseTitle		NSLocalizedStringWithDefaultValue(@"PlayPauseTitle", @"Localizable", [NSBundle mainBundle], @"Play/Pause:", @"title for the available tags cloud field")
#define ActivateiTunesTitle		NSLocalizedStringWithDefaultValue(@"ActivateiTunesTitle", @"Localizable", [NSBundle mainBundle], @"Activate iTunes:", @"title for the available tags cloud field")



#pragma mark alert messages
#define MessageTextEffectiveUponRestart NSLocalizedStringWithDefaultValue(@"MessageTextEffectiveUponRestart", @"Localizable", [NSBundle mainBundle], @"This setting will take effect when GrowlTunes restarts", @"the setting the user changed will only become effective when the user relaunches the application")
#define AlertTitleStartAtLogin NSLocalizedStringWithDefaultValue(@"AlertTitleStartAtLogin", @"Localizable", [NSBundle mainBundle], @"Alert! Enabling this option will add GrowlTunes to your login items", @"start at login alert title informing the user what's going to happen")
#define AlertMessageStartAtLogin NSLocalizedStringWithDefaultValue(@"AlertMessageStartAtLogin", @"Localizable", [NSBundle mainBundle], @"Allowing this will let GrowlTunes launch everytime you login, so that it is available when you use iTunes", @"inform the user that in order to receive notifiations from iTunes they should set GrowlTunes to launch at login")


#define OkButtonTitle NSLocalizedStringWithDefaultValue(@"OkButtonTitle", @"Localizable", [NSBundle mainBundle], @"OK", @"OK Button Title")
#define CancelButtonTitle NSLocalizedStringWithDefaultValue(@"CancelButtonTitle", @"Localizable", [NSBundle mainBundle], @"Cancel", @"Cancel Button Title")

#define BackgroundAlertTitle NSLocalizedStringWithDefaultValue(@"BackgroundAlertTitle", @"Localizable", [NSBundle mainBundle], @"Warning! Enabling this option will cause GrowlTunes to run in the background", @"User wants to run GrowlTunes in the background, no icons in the menu or dock")
#define BackgroundAlertMessage NSLocalizedStringWithDefaultValue(@"BackgroundAlertMessage", @"Localizable", [NSBundle mainBundle], @"Enabling this option will cause GrowlTunes to run without showing a dock icon or a menu item.\n\nTo access preferences, tap GrowlTunes in Launchpad, or open GrowlTunes in Finder.", @"User wants to run GrowlTunes in the background, no icons in the menu or dock")


#pragma mark Hot Keys

//identifiers
#define NowPlayingHotKeyIdentifier				@"com.growl.growltunes.nowplaying"
#define VolumeUpHotKeyIdentifier				@"com.growl.growltunes.volumeup"
#define VolumeDownHotKeyIdentifier				@"com.growl.growltunes.volumedown"
#define NextTrackHotKeyIdentifier				@"com.growl.growltunes.nextTrack"
#define PreviousTrackHotKeyIdentifier			@"com.growl.growltunes.previousTrack"
#define PlayPauseHotKeyIdentifier				@"com.growl.growltunes.playpause"
#define ActivateHotKeyIdentifier				@"com.growl.growltunes.activateiTunes"


