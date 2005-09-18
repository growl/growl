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


#import "FeedOutlineView.h"
#import "FeedWindowController.h"

@interface FeedOutlineView (Private)
-(NSString *)regionKeyForColumn:(int)columnIndex row:(int)rowIndex;
@end


@implementation FeedOutlineView

-(id)init{
	self = [super init];
	if( self ){
		toolTipRegions = [[NSMutableDictionary alloc] init];
	}
	return self;
}

-(void)dealloc{
	[toolTipRegions release];
	[super dealloc];
}



-(void)keyDown:(NSEvent *)event{
	if( ([[event characters] characterAtIndex:0] == NSNewlineCharacter) || 
		([[event characters] characterAtIndex:0] == NSEnterCharacter) ||
		([[event characters] characterAtIndex:0] == NSCarriageReturnCharacter) ){
		
		if( [self numberOfSelectedRows] > 0 ){
			if( [[self delegate] outlineView: self shouldEditTableColumn: nil item: [self itemAtRow: [self selectedRow]]] ){
				[self editColumn: 0 row: [self selectedRow] withEvent: event select: YES];
				return;
			}else{
				[[self delegate] openFeedsExternal: self];
				return;
			}
		}
	}
	[super keyDown: event];
}

-(void)textDidEndEditing:(NSNotification *)notification{
	if( [[[notification userInfo] objectForKey:@"NSTextMovement"] intValue] == NSReturnTextMovement){
		NSMutableDictionary *			newUserInfo;
		NSNotification *				newNotification;
		
		newUserInfo = [NSMutableDictionary dictionaryWithDictionary: [notification userInfo]];
		[newUserInfo setObject: [NSNumber numberWithInt: NSIllegalTextMovement] forKey: @"NSTextMovement"];
		newNotification = [NSNotification notificationWithName:[notification name] object: [notification object] userInfo: newUserInfo];
		[super textDidEndEditing: newNotification];
		[[self window] makeFirstResponder: self];
	}else{
		[super textDidEndEditing: notification];
	}
}

-(NSMenu *)menuForEvent:(NSEvent *)event{
	NSPoint			point;
	int				row;
	
	//KNDebug(@"menuForEvent");
	point = [self convertPoint: [event locationInWindow] fromView:NULL];
	row = [self rowAtPoint: point];
	
	if( ![[self selectedRowIndexes] containsIndex: row] ){
		[self selectRow: row byExtendingSelection: NO];
	}
	
	if( [[self delegate] respondsToSelector: @selector( menuForFeedRow:) ] ){
		[[self window] makeFirstResponder:self];
		return [[self delegate] menuForFeedRow: row];
	}
	return nil;
}

-(unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal{
	if( isLocal ){
		return NSDragOperationPrivate;
	}
	return NSDragOperationCopy;
}



#pragma mark -
#pragma mark ToolTip Support

-(void)reloadData{
	[toolTipRegions removeAllObjects];
	[self removeAllToolTips];
	[super reloadData];
}

-(NSRect)frameOfCellAtColumn:(int)columnIndex row:(int)rowIndex{
	NSNumber *				toolTipTag;
	NSRect					result = [super frameOfCellAtColumn: columnIndex row: rowIndex];
	NSString *				key = [self regionKeyForColumn: columnIndex row: rowIndex];
	
	if((toolTipTag = [toolTipRegions objectForKey: key])){
		[self removeToolTip: [toolTipTag intValue]];
	}
	
	[toolTipRegions setObject: [NSNumber numberWithInt:[self addToolTipRect: result owner: self userData: key]] forKey: key];
	return result;
}

-(NSString *)regionKeyForColumn:(int)columnIndex row:(int)rowIndex{
	return [NSString stringWithFormat:@"%d,%d", rowIndex, columnIndex];
}

-(NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)data{
#pragma unused(view,tag,data)
	//KNDebug(@"OUTLINE: looking for tooltip string");
	if( [[self dataSource] respondsToSelector:@selector(outlineView:toolTipForTableColumn:row:)] ){
		if( [self rowAtPoint: point] >= 0 ){
			//KNDebug(@"OUTLINE: Calling delegate for tooltip");
			return [[self delegate] outlineView: self 
							toolTipForTableColumn: [[self tableColumns] objectAtIndex:[self columnAtPoint:point]]
							row: [self rowAtPoint: point]
				];
		}
	}
	return nil;
}

@end
