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
		error = nil;
		readingSource = NO;
		
		rootOutline = [[NSMutableDictionary dictionary] retain];
		[rootOutline setObject: OPML_OUTLINE_TYPE_FOLDER forKey: OPML_OUTLINE_TYPE];
		[rootOutline setObject: @"" forKey: OPML_OUTLINE_NAME];
		[rootOutline setObject: [NSMutableArray array] forKey: OPML_OUTLINE_CHILDREN];
		
		containerStack = [[NSMutableArray array] retain];
	}
	return self;
}

-(void)dealloc{
	if( parser ){ [parser release]; }
	if( error ){ [error release]; }
	
	[rootOutline release];
	[containerStack release];
	
	[super dealloc];
}

-(BOOL)parse:(NSData *)data{
	KNDebug(@"OPML: parse");
	NS_DURING
		[[rootOutline objectForKey: OPML_OUTLINE_CHILDREN] removeAllObjects];
		[containerStack removeAllObjects];
		[containerStack addObject: rootOutline];
		
		if( parser ){ [parser release]; }

		parser = [[NSXMLParser alloc] initWithData: data];
		[parser setDelegate: self];
		[parser setShouldResolveExternalEntities: YES];
		[parser parse];
		
		[parser release];
		parser = nil;
		KNDebug(@"OPML: parse finished");
		
	NS_HANDLER
		KNDebug(@"OPML: %@", [localException reason]);
		if( error ){ [error release]; }
		error = [[localException reason] retain];
		return NO;
	NS_ENDHANDLER
	
	return YES;
}

-(NSDictionary *)rootItem{
	return rootOutline;
}

-(NSString *)error{
	return error;
}

-(void)parser:(NSXMLParser *)aParser parseErrorOccurred:(NSError *)anError{
#pragma unused(aParser,anError)
	NSException *				exception = [NSException 
												exceptionWithName: OPMLParserFailed 
												reason: [NSString stringWithFormat:@"Invalid XML"]
												userInfo: nil
											];
	[exception raise];
}


-(void)parser:(NSXMLParser *)aParser didStartElement:(NSString *)element 
	namespaceURI:(NSString *)nsURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)atts{
#pragma unused(aParser,nsURI,qName)
	
	if( [element isEqualToString: @"outline"] ){
		NSMutableDictionary *				outlineRec = [NSMutableDictionary dictionary];
		
		//KNDebug(@"OPML: found outline element with atts: %@",  atts);
		if( [atts objectForKey:@"xmlUrl"] != nil ){
			[outlineRec setObject: OPML_OUTLINE_TYPE_SOURCE forKey: OPML_OUTLINE_TYPE];
			[outlineRec setObject: [atts objectForKey:@"xmlUrl"] forKey: OPML_OUTLINE_SOURCE];
			
			[[[containerStack lastObject] objectForKey: OPML_OUTLINE_CHILDREN] addObject: outlineRec];
			readingSource = YES;
			//KNDebug(@"OPML: added source %@ to container %@", outlineRec, [[containerStack lastObject] objectForKey: OPML_OUTLINE_CHILDREN]);
			
		}else{
			[outlineRec setObject: OPML_OUTLINE_TYPE_FOLDER forKey: OPML_OUTLINE_TYPE];
			[outlineRec setObject: [NSMutableArray array] forKey: OPML_OUTLINE_CHILDREN];
			
			if( [atts objectForKey:@"title"] ){
				[outlineRec setObject: [atts objectForKey:@"title"] forKey: OPML_OUTLINE_NAME];
			}
			
			[[[containerStack lastObject] objectForKey: OPML_OUTLINE_CHILDREN] addObject: outlineRec];
			//KNDebug(@"OPML: added folder: %@", [atts objectForKey:@"title"] );
			[containerStack addObject: outlineRec];
			readingSource = NO;
		}
	}
}

-(void)parser:(NSXMLParser *)aParser didEndElement:(NSString *)element
	namespaceURI:(NSString *)nsURI qualifiedName:(NSString *)qName{
#pragma unused(aParser,nsURI,qName)
	
	if( [element isEqualToString:@"outline"] ){
		if( readingSource ){
			readingSource =  NO;
		}else{
			if( ([containerStack count] > 1) && 
				[[[containerStack lastObject] objectForKey: OPML_OUTLINE_TYPE] isEqualToString: OPML_OUTLINE_TYPE_FOLDER] 
			){
				//KNDebug(@"Popping container %@", [[containerStack lastObject] objectForKey: OPML_OUTLINE_NAME]);
				[containerStack removeLastObject];
			}
		}
	}
}


@end
