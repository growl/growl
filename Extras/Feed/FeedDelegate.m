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

#import "FeedDelegate.h"

#import "FeedWindowController.h"
#import "PrefsWindowController.h"
#import "Library.h"
#import "Library+UpgradeFrom0_6.h"
#import "Library+Update.h"
#import "Library+Items.h"
#import "Prefs.h"
#import "OPMLReader.h"
#import "KNFeed.h"
#import <Growl/GrowlApplicationBridge.h>

#import <Foundation/NSDebug.h>


#define FeedIconSourceImage @"FeedIconSource"

@implementation FeedDelegate


-(id)init{
    self = [super init];
    if( self ){
        updateTimer = nil;
		feedWindowController = nil;
		prefsWindowController = nil;
		growlNewArticles = [[NSMutableDictionary alloc] init];
		
		[[NSAppleEventManager sharedAppleEventManager] setEventHandler: self andSelector: @selector(getURL:withReplyEvent:)
			forEventClass: kInternetEventClass andEventID: kAEGetURL];
    }
    return self;
}


-(void)applicationDidFinishLaunching:(NSNotification *)notification{
#pragma unused(notification)
    KNDebug(@"appFinishedLaunch");
	NSZombieEnabled = [PREFS debugging];
	if( [PREFS showDebugMenu] ){
		[self addDebugMenu];
	}
	
	if( ! [LIB load] ){
		KNDebug(@"APP: Will load default feeds here");
		if( [LIB version0_6Exists] ){
			if( ! [LIB upgrade0_6] ){
				// Throw error
				KNDebug(@"APP: Unable to import old library");
			}
		}else{
			[self importOPMLFromPath: [[NSBundle mainBundle] pathForResource:@"DefaultSources" ofType:@"opml"] ];
			[LIB startUpdate];
		}
	}

	[[NSNotificationCenter defaultCenter] addObserver: self
		selector: @selector(feedUpdateFinished:)
		name:FeedUpdateFinishedNotification object: nil
	];
	[[NSNotificationCenter defaultCenter] addObserver: self
		selector: @selector(feedUpdateStarted:)
		name:FeedUpdateStartedNotification object: nil
	];
	[[NSNotificationCenter defaultCenter] addObserver: self
		selector: @selector(feedCreatedArticle:)
		name:FeedDidCreateArticleNotification object: nil
	];
	
	[GrowlApplicationBridge setGrowlDelegate: self];
	
	
	[self updateDockIcon];
    feedWindowController = [[FeedWindowController alloc] init];
    [feedWindowController showWindow: self];
	
	[LIB refreshPending];
	updateTimer = [NSTimer scheduledTimerWithTimeInterval: 60.0 target: self selector:@selector(updateTickle:) userInfo: nil repeats: YES];
}

-(BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender{
#pragma unused(sender)
	return NO;
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender{
#pragma unused(sender)
	return NO;
}

-(BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag{
#pragma unused( theApplication )
	if( ! flag ){
		[feedWindowController showWindow: self];
	}
	return NO;
}

-(void)addDebugMenu{
	NSMenu *			mainMenu = [NSApp mainMenu];
	NSMenuItem *		debugItem = [[NSMenuItem alloc] initWithTitle:@"Debug" action:nil keyEquivalent:@""];
	
	if( mainMenu ){
		[debugMenu setTitle: @"Debug"];
		[debugItem setSubmenu: debugMenu];
		//KNDebug(@"APP: adding debug menu %@", debugItem);
		[mainMenu addItem: debugItem];
	}
	[debugItem release];
}

-(void)applicationWillTerminate:(NSNotification *)notification{
#pragma unused(notification)
    NSImage *               appImage;
    
    //KNDebug(@"appWillTerminate");
	[updateTimer invalidate];
    [LIB save];
	
    appImage = [[NSWorkspace sharedWorkspace] iconForFile:[[NSBundle mainBundle] bundlePath]];
    [NSApp setApplicationIconImage: appImage];
}

-(BOOL)application:(NSApplication *)application openFile:(NSString *)filename{
#pragma unused(application,filename)
	KNDebug(@"APP: got an openFile request");
	return NO;
}

-(BOOL)validateMenuItem:(NSMenuItem *)item{
	
	if( [item action] == @selector(toggleDebug:) ){
		if( [PREFS debugging] ){
			[item setTitle: @"Disable Debugging"];
		}else{
			[item setTitle: @"Enable Debugging"];
		}
	}else if( [item action] == @selector(showMainWindow:) ){
		return( ! [[feedWindowController window] isVisible] );
	}
	return YES;
}

-(IBAction)showMainWindow:(id)sender{
#pragma unused(sender)
	[feedWindowController showWindow: self];
}

-(IBAction)toggleDebug:(id)sender{
#pragma unused(sender)
	if( [PREFS debugging] ){
		[PREFS setDebugging: NO];
	}else{
		[PREFS setDebugging: YES];
	}
	NSZombieEnabled = [PREFS debugging];
}

/*
-(FeedLibrary *)feedLibrary{
    return feedLibrary;
}
*/

-(IBAction)showPrefs:(id)sender{
#pragma unused(sender)
    //KNDebug(@"APP: showPrefs");
	if( ! prefsWindowController ){
		prefsWindowController = [[PrefsWindowController alloc] init];
	}
    [prefsWindowController showWindow: self];
}

-(void)updateTimer:(NSTimer *)aTimer{
#pragma unused(aTimer)
    NSTimeInterval              delay = [PREFS retryInterval];
    
    if( [LIB refreshAll] ){
        delay = [PREFS updateInterval];
    }
    
    updateTimer = [NSTimer scheduledTimerWithTimeInterval: delay target: self selector:@selector(updateTimer:) userInfo: nil repeats: NO];
}

-(void)updateTickle:(NSTimer *)aTimer{
#pragma unused(aTimer)
	[LIB refreshPending];
}

-(void)updateDockIcon{
	[self updateDockIcon: [LIB unreadCountForItem:nil]];
}

-(void)updateDockIcon:(int)unreadCount{
    NSImage *               appImage;
    NSImage *               newImage;
    NSSize                  newImageSize;
    NSRect                  badgeRect;
    NSString *              unreadString = [NSString stringWithFormat: @" %d ", unreadCount];
    NSDictionary *          unreadAtts = nil;
	NSSize					countSize;
    
    //KNDebug(@"APP: updateDockIcon with %d (%@)", unreadCount, unreadString);	
	appImage = [NSImage imageNamed: @"NSApplicationIcon"];
    newImageSize = NSMakeSize(128,128);
    newImage = [[NSImage alloc] initWithSize: newImageSize];

    [newImage lockFocus];
    [appImage drawInRect: NSMakeRect(0,0,newImageSize.width,newImageSize.height)
        fromRect: NSMakeRect(0,0,[appImage size].width,[appImage size].height)
        operation: NSCompositeCopy
        fraction: 1.0
    ];
    
    if( [PREFS showUnreadInDock] && (unreadCount > 0) ){
        unreadAtts = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSFont boldSystemFontOfSize:32], NSFontAttributeName, 
                            [NSColor whiteColor], NSForegroundColorAttributeName,
                            [NSColor redColor], NSBackgroundColorAttributeName,
                    nil];
        
		countSize = [unreadString sizeWithAttributes: unreadAtts];
		
        //badgeRect.size = NSMakeSize(countSize.width + 10, countSize.height + 10);		
		badgeRect.origin = NSMakePoint(newImageSize.width - (countSize.width + 16), newImageSize.height - (countSize.height + 6));
		
		
		
        [unreadString drawAtPoint: badgeRect.origin withAttributes: unreadAtts];
    }
    
    [newImage unlockFocus];
    
    [NSApp setApplicationIconImage: newImage];
    [newImage release];
}

-(void)getURL:(NSAppleEventDescriptor *) event withReplyEvent:(NSAppleEventDescriptor *)replyevent{
#pragma unused(replyevent)
	[self openURL: [NSURL URLWithString: [[event paramDescriptorForKeyword: keyDirectObject] stringValue] ]];
}

-(void)openURL:(NSURL *)url{
	KNDebug(@"APP: openURL %@", url);
	KNFeed *			feed = nil;
	
	if( url ){
		NSMutableString *			cleanSource = [NSMutableString stringWithString: [url absoluteString]];

		[cleanSource replaceOccurrencesOfString:@"feed:" withString:@"http:" options:NSCaseInsensitiveSearch range:NSMakeRange(0,5)];
		feed = [[KNFeed alloc] init];
		[feed setSourceURL: cleanSource];
		[feed setName: cleanSource];
		[LIB newFeed: feed inItem: nil atIndex: [LIB childCountOfItem: nil]];
		[feedWindowController reloadData];
		[LIB refreshFeed: feed];
		[LIB startUpdate];
		[feed release];
	}
}

-(void)importOPML:(id)sender{
#pragma unused(sender)
	int					openResult;
	NSArray *			fileTypes = [NSArray arrayWithObjects:@"opml",@"xml",nil];
	NSOpenPanel *		openPanel = [NSOpenPanel openPanel];
	
	//KNDebug(@"APP: importOPML");
	
	[openPanel setAllowsMultipleSelection: YES];
	openResult = [openPanel runModalForDirectory:nil file: nil types: fileTypes];
	if( openResult == NSOKButton ){
		NSArray *			filesToOpen = [openPanel filenames];
		int					i, count = [filesToOpen count];
		for( i=0; i<count; i++ ){
			[self importOPMLFromPath: [filesToOpen objectAtIndex:i]];
		}
		[LIB startUpdate];
	}
}

-(void)importOPMLFromPath:(NSString *)file{
	OPMLReader *				opml = [[OPMLReader alloc] init];
	
	if( [opml parse: [[NSFileManager defaultManager] contentsAtPath: file]] ){
		//[self importOPMLRecord: [opml rootItem] intoItem: [LIB rootItem]];
		unsigned						childCount;
		
		for(childCount=0;childCount<[[[opml rootItem] objectForKey:OPML_OUTLINE_CHILDREN] count];childCount++){
			[self importOPMLRecord: [[[opml rootItem] objectForKey:OPML_OUTLINE_CHILDREN] objectAtIndex:childCount] intoItem: [LIB rootItem]];
		}

	}else{
		NSAlert *			alert = [[NSAlert alloc] init];
		NSButton *			okButton = nil;
		
		[alert setMessageText: @"OPML Import Failed"];
		[alert setInformativeText: [NSString stringWithFormat: 
			@"Unable to import the OPML file %@: %@", 
			[file lastPathComponent], 
			[opml error]]
		];
		[alert setAlertStyle: NSInformationalAlertStyle];
		okButton = [alert addButtonWithTitle:@"OK"];
		[okButton setTarget: self];
		[okButton setAction:@selector(cancelDialog:)];
		
		[alert runModal];
		[alert release];
	}
	[opml release];
}

-(void)importOPMLRecord:(NSDictionary *)itemRecord intoItem:(id)anItem{
	
	//KNDebug(@"importOPMLRecord: %@ intoItem: %@", itemRecord, anItem);
	if( [[itemRecord objectForKey: OPML_OUTLINE_TYPE] isEqualToString: OPML_OUTLINE_TYPE_FOLDER] ){
		id						newItem;
		unsigned				i;
		
		//KNDebug(@"Importing Folder %@ into %@", [itemRecord objectForKey: OPML_OUTLINE_NAME], anItem);
		newItem = [LIB newFolderNamed: [itemRecord objectForKey: OPML_OUTLINE_NAME]
									inItem: anItem 
									atIndex: [LIB childCountOfItem: anItem]
								];
								
		for(i=0;i<[[itemRecord objectForKey:OPML_OUTLINE_CHILDREN] count];i++){
			[self importOPMLRecord: [[itemRecord objectForKey:OPML_OUTLINE_CHILDREN] objectAtIndex:i] intoItem: newItem];
		}

	}else if( [[itemRecord objectForKey: OPML_OUTLINE_TYPE] isEqualToString: OPML_OUTLINE_TYPE_SOURCE] ){
		NSString *				source = [itemRecord objectForKey: OPML_OUTLINE_SOURCE];
		KNFeed *				feed = [[KNFeed alloc] init];
		
		//KNDebug(@"Importing Feed %@ into %@", source, anItem);
		if( feed ){
			[feed setSourceURL: source];
			[feed setName: source];
			[LIB newFeed: feed inItem: anItem atIndex: [LIB childCountOfItem: anItem]];
			[LIB refreshFeed: feed];
			[feed release];
		}
	}
	
}

-(void)exportOPML:(id)sender{
#pragma unused(sender)
	NSSavePanel *			savePanel = [NSSavePanel savePanel];
	int						saveResult;
	
	KNDebug(@"APP: exportOPML");
	[savePanel setRequiredFileType:@"opml"];
	
	saveResult = [savePanel runModalForDirectory: nil file: nil];
	if( saveResult == NSOKButton ){
		NSMutableString *			buffer = [NSMutableString string];
		
		[buffer appendString:@"<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n"];
		[buffer appendString:@"<opml version=\"1.1\">\n"];
		[buffer appendString:@"\t<head>\n\t\t<title>Exported Feeds</title>\n\t</head>\n\t<body>\n"];
		
		unsigned					i;
		
		for(i=0; i<[[LIB rootItem] childCount]; i++){
			[self writeItem: [[LIB rootItem] childAtIndex: i] toOPML: buffer];
		}

		[buffer appendString:@"\t</body>\n</opml>"];
		
		if( ! [buffer writeToFile:[savePanel filename] atomically:YES] ){
			NSBeep();
		}
	}
}

-(void)writeItem:(id)anItem toOPML:(NSMutableString *)aBuffer{
	unsigned				i = 0;
	NSMutableString *		escapedString = nil;
	
	if( [[anItem type] isEqualToString: FeedItemTypeItem] ){
	
		// encode any 'illegal' XML characters that could (nay, WILL) end up in our URLs
		escapedString = [NSMutableString stringWithString: [anItem name]];
		[escapedString replaceOccurrencesOfString:@"&" withString:@"&amp;" options:NSLiteralSearch range:NSMakeRange(0,[escapedString length])];
		[escapedString replaceOccurrencesOfString:@"<" withString:@"&lt;" options:NSLiteralSearch range:NSMakeRange(0,[escapedString length])];
		
		[aBuffer appendFormat:@"\t<outline text=\"%@\" title=\"%@\">\n", escapedString, escapedString];
		
		for(i=0;i<[anItem childCount];i++){
			[self writeItem: [anItem childAtIndex: i] toOPML: aBuffer];
		}
		
		[aBuffer appendFormat:@"\t</outline>\n"];
		
	}else if( [[anItem type] isEqualToString: FeedItemTypeFeed] ){
			
		// encode any 'illegal' XML characters that could (nay, WILL) end up in our URLs
		escapedString = [NSMutableString stringWithString: [anItem sourceURL]];
		[escapedString replaceOccurrencesOfString:@"&" withString:@"&amp;" options:NSLiteralSearch range:NSMakeRange(0,[escapedString length])];
		[escapedString replaceOccurrencesOfString:@"<" withString:@"&lt;" options:NSLiteralSearch range:NSMakeRange(0,[escapedString length])];
		
		[aBuffer appendFormat:@"\t\t<outline type=\"rss\" xmlUrl=\"%@\" />\n", escapedString];
	}
}


-(NSString *)appName{
	return [[NSFileManager defaultManager] displayNameAtPath: [[NSBundle mainBundle] bundlePath]];
}

-(IBAction)cancelDialog:(id)sender{
#pragma unused(sender)
	[NSApp stopModal];
}

-(IBAction)toggleShouldCheckProtocol:(id)sender{
	[PREFS setShouldCheckProtocolRegistration:! [sender state]];
}

-(IBAction)openHomePage:(id)sender{
#pragma unused(sender)
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://keeto.net/feed/"]];
}

-(IBAction)openBugPage:(id)sender{
#pragma unused(sender)
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://keeto.net/feed/index.html?section=bugs"]];
}

#pragma mark -
#pragma mark Growl Support

-(void)feedUpdateStarted:(NSNotification *)notification{
#pragma unused( notification )
	[growlNewArticles removeAllObjects];
}

-(void)feedCreatedArticle:(NSNotification *)notification{
	KNFeed *					feed = [notification object];
	NSNumber *					count = [growlNewArticles objectForKey: [feed name]];
	
	if( ! count ){
		[growlNewArticles setObject: [NSNumber numberWithUnsignedInt: 1] forKey: [feed name]];
	}else{
		[growlNewArticles setObject: [NSNumber numberWithUnsignedInt: [count unsignedIntValue] + 1] forKey: [feed name]];
	}
}

-(void)feedUpdateFinished:(NSNotification *)notification{
#pragma unused( notification )
	NSMutableString *				updateData  = [NSMutableString string];
	NSMutableArray *				sortedNames = [NSMutableArray arrayWithArray: [growlNewArticles allKeys]];
	unsigned						totalNew = 0;
	BOOL							detailedView = NO;
	
	if( [sortedNames count] < 5 ){
		detailedView = YES;
	}
	
	NSEnumerator *					enumerator = [sortedNames objectEnumerator];
	NSString *						feedName = nil;
	while( (feedName = [enumerator nextObject]) ){
		if( detailedView ){
			[updateData appendFormat:@"%@ in %@\n", [growlNewArticles objectForKey: feedName], feedName];
		}
		totalNew += [[growlNewArticles objectForKey: feedName] unsignedIntValue];
	}
		
	if( totalNew ){
		[GrowlApplicationBridge notifyWithTitle: [NSString stringWithFormat:@"%u New Articles", totalNew]
			description: (detailedView ? updateData : [NSString stringWithFormat: @"%u new articles in %d sources", totalNew, [growlNewArticles count]])
			notificationName: @"New Articles"
			iconData: nil
			priority: 0.0
			isSticky: NO
			clickContext: nil
		];
	}
	
	[growlNewArticles removeAllObjects];
}

- (NSDictionary *) registrationDictionaryForGrowl{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSArray arrayWithObjects:
			@"New Articles",
		nil], GROWL_NOTIFICATIONS_ALL,
		
		[NSArray arrayWithObjects:
			@"New Articles",
		nil], GROWL_NOTIFICATIONS_DEFAULT,
	nil];
}

-(NSString *)applicationNameForGrowl{
	return [self appName];
}


@end
