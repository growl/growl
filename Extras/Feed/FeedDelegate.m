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
#import "FeedLibrary.h"
#import "Prefs.h"
#import "OPMLReader.h"
#import "Feed.h"
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
		feedLibrary = [[FeedLibrary alloc] init];
		[[NSAppleEventManager sharedAppleEventManager] setEventHandler: self andSelector: @selector(getURL:withReplyEvent:)
			forEventClass: kInternetEventClass andEventID: kAEGetURL];
    }
    return self;
}


-(void)applicationDidFinishLaunching:(NSNotification *)notification{
#pragma unused(notification)
    //KNDebug(@"appFinishedLaunch");
	NSZombieEnabled = [PREFS debugging];
	if( [PREFS showDebugMenu] ){
		[self addDebugMenu];
	}
	
	[self updateDockIcon];
	
    feedWindowController = [[FeedWindowController alloc] init];
    [feedWindowController showWindow: self];
	[feedLibrary refreshPending];
    
    // set our timer
	/*
    updateTimer = [NSTimer scheduledTimerWithTimeInterval: [PREFS updateInterval]
            target: self selector:@selector(updateTimer:) 
            userInfo: nil repeats: NO
    ];
	*/
	updateTimer = [NSTimer scheduledTimerWithTimeInterval: 60.0 target: self selector:@selector(updateTickle:) userInfo: nil repeats: YES];
	
	
	[[NSNotificationCenter defaultCenter] addObserver: self
		selector: @selector(feedUpdateFinished:)
		name:FeedUpdateFinishedNotification object: nil
	];
	
	[GrowlApplicationBridge setGrowlDelegate: self];
	
}

-(BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender{
#pragma unused(sender)
	return NO;
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender{
#pragma unused(sender)
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
    //[feedLibrary shutdown];
    [feedLibrary save];
    [updateTimer invalidate];
	
    appImage = [[NSWorkspace sharedWorkspace] iconForFile:[[NSBundle mainBundle] bundlePath]];
    [NSApp setApplicationIconImage: appImage];
	//[appImage release];
    //KNDebug(@"appWillTerminate Done");
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

-(FeedLibrary *)feedLibrary{
    return feedLibrary;
}

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
    
    if( [feedLibrary refreshAll] ){
        delay = [PREFS updateInterval];
    }
    
    updateTimer = [NSTimer scheduledTimerWithTimeInterval: delay target: self selector:@selector(updateTimer:) userInfo: nil repeats: NO];
}

-(void)updateTickle:(NSTimer *)aTimer{
#pragma unused(aTimer)
	[feedLibrary refreshPending];
}

-(void)updateDockIcon{
	[self updateDockIcon: [feedLibrary unreadCount]];
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
	Feed *			feed = nil;
	
	if( url ){
		NSMutableString *			cleanSource = [NSMutableString stringWithString: [url absoluteString]];

		[cleanSource replaceOccurrencesOfString:@"feed:" withString:@"http:" options:NSCaseInsensitiveSearch range:NSMakeRange(0,5)];
		feed = [[Feed alloc] initWithSource: cleanSource];
		[feedLibrary newFeed: feed inItem: nil atIndex: [feedLibrary childCountOfItem: nil]];
		[feedWindowController reloadData];
		[feedLibrary refreshFeed: feed];
		[feedLibrary startUpdate];
		[feed release];
	}
}

-(void)importOPML:(id)sender{
#pragma unused(sender)
	OPMLReader *		opml;
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
			NSString *			file = [filesToOpen objectAtIndex:i];
			NSEnumerator *		enumerator;
			//NSDictionary *		subscription;
			NSString *			source;
			
			opml = [[OPMLReader alloc] init];
			if( [opml parse: [[NSFileManager defaultManager] contentsAtPath: file]] ){
				enumerator = [[opml outlines] objectEnumerator];
				while((source = [enumerator nextObject])){
					Feed *				feed = [[Feed alloc] initWithSource: source];

					KNDebug(@"APP: Importing source %@", source);
					[feedLibrary newFeed: feed inItem: nil atIndex: [feedLibrary childCountOfItem: nil]];
					[feedLibrary refreshFeed: feed];
					[feed release];
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
		[feedWindowController reloadData];
		[feedLibrary startUpdate];
		if( ! [[feedWindowController window] isVisible] ){
			[feedWindowController showWindow: self];
		}
		//KNDebug(@"APP: Started update");
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
		NSEnumerator *				enumerator = [[feedLibrary allFeeds] objectEnumerator];
		Feed *						feed;
		
		[buffer appendString:@"<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n"];
		[buffer appendString:@"<opml version=\"1.1\">\n"];
		[buffer appendString:@"\t<head>\n\t\t<title>Exported Feeds</title>\n\t</head>\n\t<body>\n"];
		while((feed = [enumerator nextObject])){
			NSMutableString *			escapedString = [NSMutableString stringWithString: [feed source]];
			
			// encode any 'illegal' XML characters that could (nay, WILL) end up in our URLs
			[escapedString replaceOccurrencesOfString:@"&" withString:@"&amp;" options:NSLiteralSearch range:NSMakeRange(0,[escapedString length])];
			[escapedString replaceOccurrencesOfString:@"<" withString:@"&lt;" options:NSLiteralSearch range:NSMakeRange(0,[escapedString length])];
			
			KNDebug(@"APP: encoded source: %@", escapedString);
			[buffer appendFormat:@"\t\t<outline type=\"rss\" xmlUrl=\"%@\" />\n", escapedString];
		}
		[buffer appendString:@"\t</body>\n</opml>"];
		
		if( ! [buffer writeToFile:[savePanel filename] atomically:YES] ){
			NSBeep();
		}
	}
}

/*
-(void)checkProtocolRegistration{
	NSString *				currentHandlerPath = [PREFS registeredProtocolHandlerAppPath];
	
	if( [PREFS shouldCheckProtocolRegistration] && ![currentHandlerPath isEqualToString: [[NSBundle mainBundle] bundlePath]] ){
		KNDebug(@"APP: current registered app is %@", currentHandlerPath);
		// Throw dialog asking to register as default
		[NSApp beginSheet: registerProtocolPanel modalForWindow: nil modalDelegate: nil didEndSelector: nil contextInfo: nil];
		[NSApp runModalForWindow: registerProtocolPanel];
		[NSApp endSheet: registerProtocolPanel];
		[registerProtocolPanel orderOut: self];
	}
}
*/

-(NSString *)appName{
	return [[NSFileManager defaultManager] displayNameAtPath: [[NSBundle mainBundle] bundlePath]];
}

/*
-(IBAction)setFeedAsProtocolHandler:(id)sender{	
	[PREFS setRegisteredProtocolHandlerAppPath: [[NSBundle mainBundle] bundlePath]];
	[NSApp stopModal];
}
*/

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
- (NSDictionary *) registrationDictionaryForGrowl{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSArray arrayWithObjects:
			@"FeedNewArticles",
		nil], GROWL_NOTIFICATIONS_ALL,
		
		[NSArray arrayWithObjects:
			@"FeedNewArticles",
		nil], GROWL_NOTIFICATIONS_DEFAULT,
	nil];
}

-(NSString *)applicationNameForGrowl{
	return @"Feed";
}

-(void)feedUpdateFinished:(NSNotification *)notification{
	NSDictionary *					userInfo = [notification userInfo];
	
	if( [userInfo objectForKey:@"NewArticleCount"] && [[userInfo objectForKey:@"NewArticleCount"] intValue]){
		[GrowlApplicationBridge notifyWithTitle: @"New Articles"
			description: [NSString stringWithFormat: @"You have %@ new articles", 
				[userInfo objectForKey:@"NewArticleCount"]
			]
			notificationName: @"FeedNewArticles"
			iconData: nil
			priority: 0.0
			isSticky: NO
			clickContext: nil
		];
	}
}

@end
