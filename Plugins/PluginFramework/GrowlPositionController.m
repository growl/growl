//
//  GrowlPositionController.m
//  PositionController
//
//  Created by Daniel Siemer on 3/26/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "GrowlPositionController.h"
#import "GrowlQuadTreeNode.h"
#import "GrowlPositionColumn.h"

/* Do the the nature of the beast of the Quadtree,
 * there is a need to pad the spacing on columns ever so slightly.
 * This makes up for the lost precision that comes by using a rectangular rather than square
 * quadtree
 */

#define GrowlRequiredColumnPadding 1.0f

@interface GrowlPositionController ()

@property (nonatomic, retain) GrowlQuadTreeNode *rootNode;
@property (nonatomic, retain) NSMutableArray *allColumns;
@property (nonatomic, retain) NSMutableArray *leftColumns;
@property (nonatomic, retain) NSMutableArray *rightColumns;
@property (nonatomic) CGFloat availableWidth;
@property (nonatomic) CGRect screenFrame;

@end

@implementation GrowlPositionController

@synthesize rootNode;
@synthesize allColumns;
@synthesize leftColumns;
@synthesize rightColumns;
@synthesize availableWidth;
@synthesize screenFrame;

-(id)initWithScreenFrame:(CGRect)frame {
	if((self = [super init])){
		self.screenFrame = frame;
		
		self.rootNode = [[[GrowlQuadTreeNode alloc] initWithState:GrowlQuadTreeEmptyState
																		 forRect:frame] autorelease];
		self.availableWidth = screenFrame.size.width;
		self.allColumns = [NSMutableArray array];
		self.leftColumns = [NSMutableArray array];
		self.rightColumns = [NSMutableArray array];
	}
	return self;
}

-(void)dealloc {
	[rootNode release];
	[allColumns release];
	[leftColumns release];
	[rightColumns release];
	[super dealloc];
}

-(GrowlPositionColumn*)columForRect:(CGRect)rect {
	NSUInteger result = [allColumns indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
		if([obj xOrigin] <= rect.origin.x &&
			[obj xOrigin] + [obj width] >= rect.origin.x + rect.size.width)
			return YES;
		return NO;
	}];
	if(result == NSNotFound)
		return nil;
	return [allColumns objectAtIndex:result];
}

-(NSUInteger)nextColumnIndexFromIndex:(NSUInteger)index
								  inDirection:(GrowlQuadTreeDirection)direction
									  forWidth:(CGFloat)width
{
	NSUInteger result = NSNotFound;
	if(index == NSNotFound){
		//Find our first column
		if(direction == QuadLeft){
			if([rightColumns count])
				result = [allColumns count] - 1;
			else{
				if([self addColumnOfWidth:width inDirection:direction])
					result = [leftColumns count];
				else if([leftColumns count])
					result = [leftColumns count] - 1;
			}
		}else if(direction == QuadRight){
			if([leftColumns count])
				result = 0;
			else{
				if([self addColumnOfWidth:width inDirection:direction])
					result = 0;
				else if([rightColumns count])
					result = 0;
			}
		}
	}else{
		GrowlPositionColumn *column = [allColumns objectAtIndex:index];
		if([rightColumns containsObject:column]){
			NSUInteger rightIndex = [rightColumns indexOfObject:column];
			if(direction == QuadRight){
				if(rightIndex + 1 < [rightColumns count])
					result = index + 1;
			}else if(direction == QuadLeft){
				if(rightIndex > 0)
					result = index - 1;
				else if(rightIndex == 0){
					if([self addColumnOfWidth:width inDirection:direction])
						result = [leftColumns count];
					else if([leftColumns count])
						result = [leftColumns count] - 1;
				}
			}
		}else if([leftColumns containsObject:column]){
			if(direction == QuadLeft){
				if(index > 0)
					result = index - 1;
			}else if(direction == QuadRight){
				if(index + 1 < [leftColumns count])
					result = index + 1;
				else if(index == [leftColumns count] - 1){
					if([self addColumnOfWidth:width inDirection:direction])
						result = [leftColumns count] - 1;
					else if([rightColumns count])
						result = [leftColumns count];
				}

			}
		}
	}
	//NSLog(@"return next column %ld for start column %@", result, (index == NSNotFound) ? @"(none)" : [NSString stringWithFormat:@"%lu", index]);
	return result;
}

-(CGRect)canFindSpotForSize:(CGSize)size 
			startingInPosition:(GrowlPositionOrigin)start
{
	CGFloat colWidth = size.width + GrowlRequiredColumnPadding;
	if(start == GrowlNoOrigin)
		start = GrowlTopRightCorner;
	GrowlQuadTreeDirection secondary = (start == GrowlTopLeftCorner || start == GrowlBottomLeftCorner) ? QuadRight : QuadLeft;
	GrowlQuadTreeDirection primary = (start == GrowlTopLeftCorner || start == GrowlTopRightCorner) ? QuadDown : QuadUp;
	
	NSUInteger nextColumn = NSNotFound;
	GrowlPositionColumn *column = nil;
	do {
		nextColumn = [self nextColumnIndexFromIndex:nextColumn
												  inDirection:secondary
													  forWidth:colWidth];
		if(nextColumn == NSNotFound){
			return CGRectZero;
		}
		column = [allColumns objectAtIndex:nextColumn];
	} while (column.width < colWidth && ![self canResizeColumn:nextColumn toWidth:colWidth]);

	BOOL willNeeedResizing = NO;
	if([column width] < colWidth){
		willNeeedResizing = YES;
	}
	
	CGPoint origin;
	switch (start) {
		case GrowlBottomLeftCorner:
			origin = CGPointMake(column.xOrigin, screenFrame.origin.y);
			break;
		case GrowlBottomRightCorner:
			origin = CGPointMake(column.xOrigin + (column.width - size.width), screenFrame.origin.y);
			break;
		case GrowlTopLeftCorner:
			origin = CGPointMake(column.xOrigin, screenFrame.origin.y + (screenFrame.size.height - size.height));
			break;
		case GrowlTopRightCorner:
		default:
			origin = CGPointMake(column.xOrigin + (column.width - size.width), screenFrame.origin.y + (screenFrame.size.height - size.height));
	}
	CGRect rect = CGRectMake(origin.x, origin.y, size.width, size.height);
	while (![rootNode isFrameFree:rect]) {
		switch (primary) {
			case QuadDown:
				rect.origin.y -= 1;
				break;
			case QuadUp:
				rect.origin.y += 1;
				break;
			default:
				return CGRectZero;
				break;
		}
		
		if(!CGRectContainsRect(screenFrame, rect)){
			do {
				nextColumn = [self nextColumnIndexFromIndex:nextColumn
														  inDirection:secondary
															  forWidth:colWidth];
				if(nextColumn == NSNotFound){
					//NSLog(@"Unable to find additional columns for width %lf", size.width);
					return CGRectZero;
				}
				column = [allColumns objectAtIndex:nextColumn];
			} while (column.width < colWidth && ![self canResizeColumn:nextColumn toWidth:colWidth]);
			
			if([column width] < colWidth){
				willNeeedResizing = YES;
			}else{
				willNeeedResizing = NO;
			}
			rect.origin.y = origin.y;
			if(secondary == QuadRight)
				rect.origin.x = column.xOrigin;
			else{
				rect.origin.x = column.xOrigin + (column.width - size.width);
			}
		}
	}
	if(willNeeedResizing){
		[self resizeColumn:nextColumn
					  toWidth:colWidth];
	}
	return rect;
}

-(void)occupyRect:(CGRect)rect
{
	GrowlPositionColumn *column = [self columForRect:rect];
	//NSLog(@"add to column %@ width %lf", column, rect.size.width);
	[column addWidth:rect.size.width + GrowlRequiredColumnPadding];
	[rootNode occupyFrame:rect];
	[rootNode consolidate];
}

-(void)vacateRect:(CGRect)rect
{
	GrowlPositionColumn *column = [self columForRect:rect];
	//NSLog(@"remove from column %@ width %lf", column, rect.size.width);
	[column removeWidth:rect.size.width + GrowlRequiredColumnPadding];
	[rootNode vacateFrame:rect];
	[rootNode consolidate];
	
	if([column minWidth] < [column width] && [column minWidth] > 0.0f) 
		[self resizeColumn:[allColumns indexOfObject:column]
					  toWidth:[column minWidth]];

	NSMutableArray *deadLeft = [NSMutableArray array];
	[leftColumns enumerateObjectsWithOptions:NSEnumerationReverse
											usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
												if([obj minWidth] == 0.0f)
													[deadLeft addObject:obj];
												else
													*stop = YES;
											}];
	[leftColumns removeObjectsInArray:deadLeft];
	[allColumns removeObjectsInArray:deadLeft];
	__block CGFloat removedWidth = 0.0f;
	[deadLeft enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		removedWidth += [obj width];
	}];
	
	NSMutableArray *deadRight = [NSMutableArray array];
	[rightColumns enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if([obj minWidth] == 0.0f)
			[deadRight addObject:obj];
		else
			*stop = YES;
	}];
	[rightColumns removeObjectsInArray:deadRight];
	[allColumns removeObjectsInArray:deadRight];
	[deadRight enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		removedWidth += [obj width];
	}];
	availableWidth += removedWidth;
	//if([deadLeft count] || [deadRight count]) NSLog(@"remove %lu columns", [deadLeft count] + [deadRight count]);
}

-(BOOL)canResizeColumn:(NSUInteger)index toWidth:(CGFloat)width {
	GrowlPositionColumn *column = [allColumns objectAtIndex:index];
	CGFloat diff = width - column.width;
	if(availableWidth - diff < 0.0f)
		return NO;
	
	BOOL result = NO;
	if([leftColumns containsObject:column]){
		if(index + 1 == [leftColumns count])
			result = YES;
	}else if([rightColumns containsObject:column]){
		NSUInteger rightIndex = [rightColumns indexOfObject:column];
		if(rightIndex == 0)
			result = YES;
	}
	return result;
}

-(BOOL)resizeColumn:(NSUInteger)index toWidth:(CGFloat)width {
	if([self canResizeColumn:index toWidth:width]){
		GrowlPositionColumn *column = [allColumns objectAtIndex:index];
		//NSLog(@"resize column %@ from %lf to %lf", column, column.width, width);
		CGFloat diff = width - column.width;
		availableWidth -= diff;
		column.width = width;
		if([leftColumns containsObject:column]){
			if(index + 1 < [leftColumns count]){
				GrowlPositionColumn *nextTo = [rightColumns objectAtIndex:index + 1];
				nextTo.width += diff;
				nextTo.xOrigin -= diff;
				availableWidth += diff;
			}
		}else if([rightColumns containsObject:column]){
			NSUInteger rightIndex = [rightColumns indexOfObject:column];
			if(rightIndex > 0){
				GrowlPositionColumn *nextTo = [rightColumns objectAtIndex:rightIndex - 1];
				nextTo.width += diff;
				availableWidth += diff;
			}
			column.xOrigin -= diff;
		}
		return YES;
	}
	return NO;
}

-(BOOL)canAddColumnOfWidth:(CGFloat)width 
{
	return availableWidth >= width;
}

-(BOOL)addColumnOfWidth:(CGFloat)width 
				inDirection:(GrowlQuadTreeDirection)direction
{
	if([self canAddColumnOfWidth:width])
	{
		GrowlPositionColumn *newColumn = [[[GrowlPositionColumn alloc] init] autorelease];
		GrowlPositionColumn *nextTo = nil;
		newColumn.width = width;
		availableWidth -= width;
		switch (direction) {
			case QuadLeft:
				if([rightColumns count])
					nextTo = [rightColumns objectAtIndex:0U];
				if(nextTo)
					newColumn.xOrigin = nextTo.xOrigin - width;
				else
					newColumn.xOrigin = screenFrame.origin.x + (screenFrame.size.width - width);
				[rightColumns insertObject:newColumn atIndex:0];
				[allColumns insertObject:newColumn atIndex:[leftColumns count]];
				break;
			case QuadRight:
				if([leftColumns count])
					nextTo = [leftColumns lastObject];
				if(nextTo)
					newColumn.xOrigin = nextTo.xOrigin + nextTo.width;
				else
					newColumn.xOrigin = screenFrame.origin.x;
				[leftColumns addObject:newColumn];
				[allColumns insertObject:newColumn atIndex:[leftColumns count] - 1];
				break;
			default:
				break;
		}
		return YES;
	}
	return NO;
}


@end
