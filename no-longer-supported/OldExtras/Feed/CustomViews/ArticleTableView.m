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


#import "ArticleTableView.h"
#import "FeedWindowController.h"


@implementation ArticleTableView

-(void)keyDown:(NSEvent *)event{	
	if( ([[event characters] characterAtIndex:0] == NSNewlineCharacter) || 
		([[event characters] characterAtIndex:0] == NSEnterCharacter) ||
		([[event characters] characterAtIndex:0] == NSCarriageReturnCharacter) ){
		
		//KNDebug(@"keyDown in article view will open article");
		[[self delegate] openArticlesExternal: self];
	}else{
		[super keyDown: event];
	}
}


-(NSMenu *)menuForEvent:(NSEvent *)event{
	NSPoint			point;
	int				row;
	
	//KNDebug(@"menuForEvent");
	point = [self convertPoint: [event locationInWindow] fromView:NULL];
	row = [self rowAtPoint: point];
	
	// if outside current selection, change the selection
	if( ! [[self selectedRowIndexes] containsIndex: row] ){
		[self selectRow: row byExtendingSelection: NO];
	}

	if( (row >= 0) && [[self delegate] respondsToSelector:@selector(menuForFeedRow:)] ){
		[[self window] makeFirstResponder:self];
		return [[self delegate] menuForArticleRow: row];
	}
	return nil;
}

-(unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal{
	if( isLocal ){
		return NSDragOperationPrivate;
	}
	return NSDragOperationCopy;
}
@end
