/*

BSD License

Copyright (c) 2005, Keith Anderson
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


#import "InspectorController.h"
#import "FeedDelegate.h"
#import "FeedLibrary.h"
#import "KNFeed.h"
#import "KNArticle.h"
#import "Prefs.h"

#define EXPIRE_NEVER_TAG 1024
#define EXPIRE_DAY_TAG 1025
#define EXPIRE_WEEK_TAG 1026
#define EXPIRE_MONTH_TAG 1027


@implementation InspectorController

-(id)init{
	self = [super initWithWindowNibName:@"Inspector"];
	if( self ){
		item = nil;
	}
	return self;
}

-(void)awakeFromNib{
	item = nil;
	[self setItem: item];
}

-(void)windowDidLoad{
	[self setShouldCascadeWindows: NO];
	[[self window] setFrameAutosaveName:@"feedInspectorWindow"];
	[[self window] setFrameUsingName: @"feedInspectorWindow"];
}

-(void)setItem:(KNItem *)anItem{
	NSMutableString *			windowTitle = [NSMutableString string];
	NSRect						oldWindowFrame = [[self window] frame];
	NSRect						newWindowFrame = oldWindowFrame;
	NSView *					targetView = nil;
	NSView *					oldView = nil;
	float						verticalChange = 0;
	float						horizontalChange = 0;
	
	//KNDebug(@"setItem called in inspector");
	if( anItem ){
		if( [[anItem type] isEqualToString: FeedItemTypeFeed] ){
			targetView = feedDetailsView;
			//KNDebug(@"Checking item for userSetName: %@", [anItem valueForKeyPath:@"prefs.userSetName"]);
			if( [anItem valueForKeyPath:@"prefs.userSetName"] && ![[anItem valueForKeyPath:@"prefs.userSetName"] isEqualToString:@""] ){
				[feedDetailTitleField setStringValue: [anItem valueForKeyPath:@"prefs.userSetName"]];
			}else{
				[feedDetailTitleField setStringValue: [anItem name]];
			}
			[feedDetailSourceField setStringValue: [(KNFeed *)anItem sourceURL]];
			
			[feedDetailUpdateIntervalField setObjectValue: [anItem valueForKeyPath:@"prefs.updateLength"]];
			[feedDetailUpdateUnitPopup selectItemAtIndex: 
				[feedDetailUpdateUnitPopup indexOfItemWithTag: 
					[[anItem valueForKeyPath:@"prefs.updateUnits"] intValue]
				]
			];
			
			NSTimeInterval				expireInterval = [[anItem valueForKeyPath:@"prefs.expireInterval"] doubleValue];
			int							expireTag;
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
			[feedDetailExpirePopup selectItemAtIndex: [feedDetailExpirePopup indexOfItemWithTag: expireTag]];
			
			[windowTitle appendFormat: @"Feed Details: %@", [anItem name]];
			
		}else if( [[anItem type] isEqualToString: FeedItemTypeItem] ){
			targetView = folderDetailsView;
			[folderDetailNameField setStringValue: [anItem name]];
			[windowTitle appendFormat: @"Folder Details: %@", [anItem name]];
			
		}else if( [[anItem type] isEqualToString: FeedItemTypeArticle] ){
			targetView = articleDetailsView;
			[articleDetailFeedTitleField setStringValue: [anItem name]];
			[articleDetailDateField setObjectValue: [(KNArticle *)anItem date]];
			[articleDetailAuthorField setStringValue: [(KNArticle *)anItem author]];
			[articleDetailTitleField setStringValue: [(KNArticle *)anItem sourceURL]];
			[windowTitle appendFormat: @"Article Details: %@", [anItem name]];
		}else{
			targetView = invalidDetailsView;
			[windowTitle appendFormat: @"No Details Available"];
			
		}
	}else{
		targetView = invalidDetailsView;
		[windowTitle appendFormat: @"No Details Available"];
	}
	
	if( item ){
		if( [[item type] isEqualToString: FeedItemTypeFeed] ){
			oldView = feedDetailsView;
		}else if( [[item type] isEqualToString: FeedItemTypeItem] ){
			oldView = folderDetailsView;
		}else if( [[item type] isEqualToString: FeedItemTypeArticle] ){
			oldView = articleDetailsView;
		}else{
			oldView = invalidDetailsView;
		}
	}else{
		oldView = invalidDetailsView;
	}
	
	if( oldView != targetView ){
		horizontalChange = [targetView frame].size.width - [oldView frame].size.width;
		verticalChange = [targetView frame].size.height - [oldView frame].size.height;
		
		newWindowFrame = NSMakeRect(
			oldWindowFrame.origin.x,
			oldWindowFrame.origin.y - verticalChange,
			[targetView frame].size.width + horizontalChange,
			[targetView frame].size.height + 11
		);
		
		[oldView removeFromSuperview];
		[[self window] setFrame: newWindowFrame display: YES animate: YES];
		[[[self window] contentView] addSubview: targetView];
		[[self window] saveFrameUsingName: @"feedInspectorWindow"];
	}
	
	item = anItem;
	[[self window] setTitle: windowTitle];
}

-(IBAction)feedDataChanged:(id)sender;{
	if( ! item ){
		KNDebug(@"feedDataChanged in inspector with nil item");
		return;
	}
	
	if( sender == feedDetailSourceField ){
		[(KNFeed *)item setSourceURL: [sender objectValue]];
	}else if( sender == feedDetailTitleField ){
		[item setValue: [sender objectValue] forKeyPath:@"prefs.userSetName"];
	}else if( sender == feedDetailUpdateIntervalField ){
		[item setValue:[sender objectValue] forKeyPath:@"prefs.updateLength"];
	}else if( sender == feedDetailUpdateUnitPopup ){
		[item setValue:[NSNumber numberWithInt:[[sender selectedItem] tag]] forKeyPath:@"prefs.updateUnits"];
	}else if( sender == feedDetailExpirePopup ){
		int						expireTag = [[sender selectedItem] tag];
		NSTimeInterval			expireInterval;
		
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

		[item setValue:[NSNumber numberWithDouble:expireInterval] forKeyPath:@"prefs.expireInterval"];
		
	}else if( sender == folderDetailNameField ){
		[item setName: [sender stringValue]];
	}
}

-(void)textDidChange:(NSNotification *)aNotification{
#pragma unused( aControl, aNotification )
	
	KNDebug(@"textChanged");
}

@end
