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
#import "OPMLReader.h"

#define OPMLParserFailed @"OPMLParserFailed"
@implementation OPMLReader

-(id)init{
	self = [super init];
	if( self ){
		parser = nil;
		outlines = nil;
	}
	return self;
}

-(void)dealloc{
	if( parser ){ [parser release]; }
	if( outlines ){ [outlines release]; }
	[super dealloc];
}

-(BOOL)parse:(NSData *)data{
	KNDebug(@"OPML: parse");
	NS_DURING
		if( outlines ){ [outlines release]; }
		outlines = [[NSMutableArray alloc] init];
		if( parser ){ [parser release]; }

		parser = [[NSXMLParser alloc] initWithData: data];
		[parser setDelegate: self];
		[parser setShouldResolveExternalEntities: YES];
		[parser parse];
		
		[parser release];
		parser = nil;
		
	NS_HANDLER
		KNDebug(@"OPML: %@", [localException reason]);
		return NO;
	NS_ENDHANDLER
	
	return YES;
}

-(NSArray *)outlines{
	return outlines;
}

-(void)parser:(NSXMLParser *)aParser parseErrorOccurred:(NSError *)error{
#pragma unused(aParser,error)
	NSException *				exception = [NSException exceptionWithName: OPMLParserFailed reason: @"Invalid XML for OPML" userInfo: nil];
	[exception raise];
}

-(void)parser:(NSXMLParser *)aParser didStartElement:(NSString *)element 
	namespaceURI:(NSString *)nsURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)atts{
#pragma unused(aParser,nsURI,qName)
	
	if( [element isEqualToString: @"outline"] ){
		//KNDebug(@"OPML: found outline element with atts: %@",  atts);
		if( [atts objectForKey:@"xmlUrl"] != NULL ){
			//KNDebug(@"OPML: found source %@", [atts objectForKey:@"xmlUrl"]);
			[outlines addObject: [NSString stringWithString:[atts objectForKey:@"xmlUrl"]]];
		}
	}
}


@end
