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

#import "FeedWindowController+Status.h"
#import "FeedWindowController+Sources.h"

#define STATUS_CURRENT_SOURCES @"StatusCurrentSources"
#define STATUS_WEBKIT_MESSAGE @"StatusWebKitMessage"
#define STATUS_WEBKIT_RESOURCES @"StatusWebKitResources"

@implementation FeedWindowController (Status)

-(void)updateStatus{
	[statusTextField setStringValue: [self currentStatusText]];
}

-(NSString *)currentStatusText{
	NSString *				status = nil;
	
	if( [statusMessages objectForKey: STATUS_WEBKIT_MESSAGE] ){
		status = [statusMessages objectForKey: STATUS_WEBKIT_MESSAGE];
	}else if( [statusMessages objectForKey:STATUS_WEBKIT_RESOURCES] && [[statusMessages objectForKey:STATUS_WEBKIT_RESOURCES] count] ){
		status = [NSString stringWithFormat: @"Loading %@", [[statusMessages objectForKey:STATUS_WEBKIT_RESOURCES] lastObject]];
	}else if( [statusMessages objectForKey:STATUS_CURRENT_SOURCES] && [[statusMessages objectForKey:STATUS_CURRENT_SOURCES] count] ){
		status = [NSString stringWithFormat: @"Updating %@", [[statusMessages objectForKey:STATUS_CURRENT_SOURCES] lastObject]];
	}else{
		status = [NSMutableString stringWithFormat:@"Displaying %u articles in %u feeds", [articleCache count], [[self selectedFeeds] count] ];
	}
	return status;
}

-(void)addSourceUpdateStatus:(NSString *)updateName{
	NSMutableArray *				sources = [statusMessages objectForKey: STATUS_CURRENT_SOURCES];
	
	if( ! sources ){
		sources = [NSMutableArray array];
		[statusMessages setObject: sources forKey: STATUS_CURRENT_SOURCES];
	}
	[sources addObject: updateName];
	[self updateStatus];
}

-(void)sourceUpdateStatusFinished:(NSString *)updateName{
	NSMutableArray *				sources = [statusMessages objectForKey: STATUS_CURRENT_SOURCES];
	
	if( ! sources ){
		sources = [NSMutableArray array];
		[statusMessages setObject: sources forKey: STATUS_CURRENT_SOURCES];
	}
	[sources removeObject: updateName];
	[self updateStatus];
}

-(void)webKitStartLoading:(NSString *)resourceKey{
	NSMutableArray *				sources = [statusMessages objectForKey: STATUS_WEBKIT_RESOURCES];
	
	KNDebug(@"starting webkit load");
	if( ! sources ){
		sources = [NSMutableArray array];
		[statusMessages setObject: sources forKey: STATUS_WEBKIT_RESOURCES];
	}
	[sources addObject: resourceKey];
	[self updateStatus];
}

-(void)webKitEndLoading:(NSString *)resourceKey{
	NSMutableArray *				sources = [statusMessages objectForKey: STATUS_WEBKIT_RESOURCES];
	
	KNDebug(@"ending webkit load");
	if( ! sources ){
		sources = [NSMutableArray array];
		[statusMessages setObject: sources forKey: STATUS_WEBKIT_RESOURCES];
	}
	[sources removeObject: resourceKey];
	[self updateStatus];
}


-(void)webKitMouseover:(NSString *)statusString{
	if( statusString ){
		[statusMessages setObject: statusString forKey: STATUS_WEBKIT_MESSAGE];
	}else{
		if( [statusMessages objectForKey: STATUS_WEBKIT_MESSAGE] ){
			[statusMessages removeObjectForKey: STATUS_WEBKIT_MESSAGE];
		}
	}
	[self updateStatus];
}

@end
