/*

BSD License

Copyright (c) 2004, Keith Anderson
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

*	Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.
*	Redistributions in binary form must reproduce the above copyright notice,
	this list of conditions and the following disclaimer in the documentation
	and/or other materials provided with the distribution.
*	Neither the name of keeto.net or Keith Anderson nor the names of its
	contributors may be used to endorse or promote products derived
	from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


*/


#import "PrefsWindowController.h"

#import "Prefs.h"

#define EXPIRE_NEVER_TAG 1024
#define EXPIRE_DAY_TAG 1025
#define EXPIRE_WEEK_TAG 1026
#define EXPIRE_MONTH_TAG 1027


@implementation PrefsWindowController

-(id)init{
    self = [super initWithWindowNibName:@"Prefs"];
    if( self ){
        //KNDebug(@"PrefsCont: init");
		NSArray *					libSources = NSSearchPathForDirectoriesInDomains( NSAllLibrariesDirectory, NSAllDomainsMask, YES );
		NSFileManager *				fileManager = [NSFileManager defaultManager];
		NSEnumerator *				pathEnumerator = [libSources objectEnumerator];
		NSDirectoryEnumerator *		dirEnumerator = nil;
		NSString *					path = nil;
		NSString *					soundName = nil;
		
		soundNames = [[NSMutableArray alloc] init];
		while( path = [pathEnumerator nextObject] ){
			dirEnumerator = [fileManager enumeratorAtPath: [NSString stringWithFormat:@"%@/Sounds",path]];
			while( soundName = [dirEnumerator nextObject] ){
				if( [NSSound soundNamed: [soundName stringByDeletingPathExtension]] ){
					[soundNames addObject: [soundName stringByDeletingPathExtension]];
				}
			}
		}
		[soundNames sortUsingSelector: @selector(compare:)];
    }
    return self;
}

-(void)dealloc{
	[soundNames release];
	[super dealloc];
}

-(void)awakeFromNib{
    //KNDebug(@"Prefs awakeFromNib");
	NSMutableArray *			fonts;
	NSEnumerator *				enumerator;
	NSString *					font;
	
	[articleListFontPopup removeAllItems];
	[articleFontPopup removeAllItems];
	
	fonts = [[[NSFontManager sharedFontManager] availableFontFamilies] mutableCopy];
	[fonts sortUsingSelector: @selector(compare:)];
	enumerator = [fonts objectEnumerator];
	while( font = [enumerator nextObject] ){
		[articleListFontPopup addItemWithTitle: font];
		[articleFontPopup addItemWithTitle: font];
	}
	[fonts release];
	
	NSString *					soundName = nil;
	enumerator = [soundNames objectEnumerator];
	while( soundName = [enumerator nextObject] ){
		[notificationSoundNamePopup addItemWithTitle: soundName];
	}
}

-(void)windowDidLoad{
	[self setShouldCascadeWindows: NO];
    if( ! [[self window] setFrameAutosaveName: @"prefsWindow"] ){
        KNDebug(@"Unable to set autosave!");
    }
    [[self window] setFrameUsingName: @"prefsWindow"];
}

-(void)windowDidBecomeKey:(NSNotification *)notification{
    double                  units = [PREFS updateUnits];
    double                  length = [PREFS updateLength];
	NSTimeInterval			expireInterval = [PREFS articleExpireInterval];
	int						expireTag;
    
    [updateIntervalTextField setIntValue: length];
    [updateIntervalUnitPopup selectItemAtIndex: [updateIntervalUnitPopup indexOfItemWithTag:units]];
	[deleteArticleCheckbox setState: [PREFS warnWhenDeletingArticles]];
	[showUnreadCheckbox setState: [PREFS showUnreadInDock]];
	[openInBackgroundCheckbox setState: [PREFS launchExternalInBackground]];
	[useTorrentSchemeCheckbox setState: [PREFS useTorrentScheme]];
	
	if( expireInterval == UNIT_NEVER ){
		expireTag = EXPIRE_NEVER_TAG;
	}else if( expireInterval == UNIT_DAYS ){
		expireTag = EXPIRE_DAY_TAG;
	}else if( expireInterval == UNIT_WEEKS ){
		expireTag = EXPIRE_WEEK_TAG;
	}else if( expireInterval == UNIT_MONTHS ){
		expireTag = EXPIRE_MONTH_TAG;
	}else{
		expireTag = EXPIRE_WEEK_TAG;
	}
	[expireIntervalPopup selectItemAtIndex: [expireIntervalPopup indexOfItemWithTag:expireTag]];
	
	//KNDebug(@"PREFS: setting article list font to %@", [PREFS articleListFontName]);
	[articleListFontPopup selectItemWithTitle: [PREFS articleListFontName]];
	[articleFontPopup selectItemWithTitle: [PREFS articleFontName]];
	[articleListFontSizeComboBox setObjectValue: [NSNumber numberWithFloat:[PREFS articleListFontSize]]];
	[articleFontSizeComboBox setObjectValue: [NSNumber numberWithFloat: [PREFS articleFontSize]]];
	[articleExpiredColorWell setColor: [PREFS expiredArticleColor]];
	//[maxUpdateThreadsPopup selectItemAtIndex: [maxUpdateThreadsPopup indexOfItemWithTag: [PREFS maxUpdateThreads]] ];
	
	if( [[PREFS notificationSoundName] isEqualToString: @""] ){
		[notificationSoundNamePopup selectItemWithTitle: @"None"];
	}else{
		[notificationSoundNamePopup selectItemWithTitle: [PREFS notificationSoundName]];
	}
}

- (IBAction)savePrefs:(id)sender{
	NSTimeInterval			expireInterval;
	int						expireTag;
	
    KNDebug(@"PREFS: savePrefs");
	if( sender == updateIntervalUnitPopup ){
		[PREFS setUpdateUnits: [[updateIntervalUnitPopup selectedItem] tag]];
		
	}else if( sender == updateIntervalTextField ){
		[PREFS setUpdateLength: [updateIntervalTextField doubleValue]];
		
	}else if( sender == deleteArticleCheckbox ){
		[PREFS setWarnWhenDeletingArticles: [deleteArticleCheckbox state]];
		
	}else if( sender == showUnreadCheckbox ){
		[PREFS setShowUnreadInDock: [showUnreadCheckbox state]];
		
	}else if( sender == openInBackgroundCheckbox ){
		[PREFS setLaunchExternalInBackground: [openInBackgroundCheckbox state]];
		
	}else if( sender == expireIntervalPopup ){
		//KNDebug(@"PREFS: expireTag %d (%@ in %@)", expireTag, [expireIntervalPopup selectedItem], expireIntervalPopup);
		expireTag = [[expireIntervalPopup selectedItem] tag];
		if( expireTag == EXPIRE_NEVER_TAG ){
			expireInterval = (NSTimeInterval) UNIT_NEVER;
		}else if( expireTag == EXPIRE_DAY_TAG ){
			expireInterval = UNIT_DAYS;
		}else if( expireTag == EXPIRE_WEEK_TAG ){
			expireInterval = UNIT_WEEKS;
		}else if( expireTag == EXPIRE_MONTH_TAG ){
			expireInterval = UNIT_MONTHS;
		}else{
			expireInterval = UNIT_WEEKS;
		}
		[PREFS setArticleExpireInterval: expireInterval];
		
	}else if( sender == articleListFontPopup ){
		[PREFS setArticleListFontName: [articleListFontPopup titleOfSelectedItem]];
		
	}else if( sender == articleFontPopup ){
		[PREFS setArticleFontName: [articleFontPopup titleOfSelectedItem]];
	
	//}else if( sender == maxUpdateThreadsPopup ){
	//	[PREFS setMaxUpdateThreads: [[maxUpdateThreadsPopup selectedItem] tag]];
	
	}else if( sender == articleListFontSizeComboBox ){
		[PREFS setArticleListFontSize: [articleListFontSizeComboBox floatValue]];
		
	}else if( sender == articleFontSizeComboBox ){
		[PREFS setArticleFontSize: [articleFontSizeComboBox floatValue]];
	
	}else if( sender == articleExpiredColorWell ){
		[PREFS setExpiredArticleColor: [articleExpiredColorWell color]];
		
	}else if( sender == notificationSoundNamePopup ){
		if( ![[notificationSoundNamePopup titleOfSelectedItem] isEqualToString: @"None"] ){
			[PREFS setNotificationSoundName: [notificationSoundNamePopup titleOfSelectedItem]];
			[[NSSound soundNamed:[notificationSoundNamePopup titleOfSelectedItem]] play];
		}else{
			[PREFS setNotificationSoundName:@""];
		}
	}else if( sender == useTorrentSchemeCheckbox ){
		[PREFS setUseTorrentScheme: [useTorrentSchemeCheckbox state]];
	}
	
    //[[self window] orderOut: self];
}

@end
