//
//  GrowlPositionController.m
//  Growl
//
//  Created by Ofri Wolfus on 31/08/05.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details
//

#import "GrowlPositionController.h"
#import "GrowlDisplayWindowController.h"
#import "NSMutableStringAdditions.h"

@interface GrowlPositionController (private)
- (NSMutableSet *)reservedRectsForScreen:(NSScreen *)inScreen;
@end

@implementation GrowlPositionController

//Initialize
- (id) initSingleton {
	if ((self = [super initSingleton])) {
		reservedRects = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	}

	return self;
}

//Deallocate
- (void) destroy {
	CFRelease(reservedRects);
}

//Return a rect suitable for the position and screen.
+ (NSRect) rectForPosition:(enum GrowlPosition)position inScreen:(NSScreen *)screen {
	NSRect screenFrame;
	NSSize areaSize;
	NSRect result = NSZeroRect;

	//Treat nil as the main screen
	if (!screen)
		screen = [NSScreen mainScreen];

	screenFrame = [screen visibleFrame];
	areaSize = NSMakeSize(screenFrame.size.width / 3.0f, screenFrame.size.height / 3.0f);	//We have 9 identical areas on each screen

	switch (position) {
			//Top left
		case GrowlTopLeftPosition:
			result = NSMakeRect(screenFrame.origin.x,
								screenFrame.origin.y + areaSize.height + areaSize.height,
								areaSize.width,
								areaSize.height);
			break;

			//Top middle
		case GrowlTopMiddlePosition:
			result = NSMakeRect(screenFrame.origin.x + areaSize.width,
								screenFrame.origin.y + areaSize.height + areaSize.height,
								areaSize.width,
								areaSize.height);
			break;

			//Top right
		case GrowlTopRightPosition:
			result = NSMakeRect(screenFrame.origin.x + areaSize.width + areaSize.width,
								screenFrame.origin.y + areaSize.height + areaSize.height,
								areaSize.width,
								areaSize.height);
			break;

			//Center left
		case GrowlCenterLeftPosition:
			result = NSMakeRect(screenFrame.origin.x,
								screenFrame.origin.y + areaSize.height,
								areaSize.width,
								areaSize.height);
			break;

			//Center middle
		case GrowlCenterMiddlePosition:
			result = NSMakeRect(screenFrame.origin.x + areaSize.width,
								screenFrame.origin.y + areaSize.height,
								areaSize.width,
								areaSize.height);
			break;

			//Center right
		case GrowlCenterRightPosition:
			result = NSMakeRect(screenFrame.origin.x + areaSize.width + areaSize.width,
								screenFrame.origin.y + areaSize.height,
								areaSize.width,
								areaSize.height);
			break;

			//Bottom left
		case GrowlBottomLeftPosition:
			result = NSMakeRect(screenFrame.origin.x,
								screenFrame.origin.y,
								areaSize.width,
								areaSize.height);
			break;

			//Bottom middle
		case GrowlBottomMiddlePosition:
			result = NSMakeRect(screenFrame.origin.x + areaSize.width,
								screenFrame.origin.y,
								areaSize.width,
								areaSize.height);
			break;

			//Bottom right
		case GrowlBottomRightPosition:
			result = NSMakeRect(screenFrame.origin.x + areaSize.width + areaSize.width,
								screenFrame.origin.y,
								areaSize.width,
								areaSize.height);
			break;

			//Top row
		case GrowlTopRowPosition:
			result = NSMakeRect(screenFrame.origin.x,
								screenFrame.origin.y + areaSize.height + areaSize.height,
								screenFrame.size.width,
								areaSize.height);
			break;

			//Center row
		case GrowlCenterRowPosition:
			result = NSMakeRect(screenFrame.origin.x,
								screenFrame.origin.y + areaSize.height,
								screenFrame.size.width,
								areaSize.height);
			break;

			//Bottom row
		case GrowlBottomRowPosition:
			result = NSMakeRect(screenFrame.origin.x,
								screenFrame.origin.y,
								screenFrame.size.width,
								areaSize.height);
			break;

			//Left column
		case GrowlLeftColumnPosition:
			result = NSMakeRect(screenFrame.origin.x,
								screenFrame.origin.y,
								areaSize.width,
								screenFrame.size.height);
			break;

			//Middle column
		case GrowlMiddleColumnPosition:
			result = NSMakeRect(screenFrame.origin.x + areaSize.width,
								screenFrame.origin.y,
								areaSize.width,
								screenFrame.size.height);
			break;

			//Right column
		case GrowlRightColumnPosition:
			result = NSMakeRect(screenFrame.origin.x + areaSize.width + areaSize.width,
								screenFrame.origin.y,
								areaSize.width,
								screenFrame.size.height);
			break;
	}

	return result;
}

- (BOOL) positionDisplay:(GrowlDisplayWindowController *)displayController {
	NSScreen *preferredScreen = [displayController screen];
	NSRect screenFrame = [preferredScreen visibleFrame];
	NSSize displaySize = [[displayController window] frame].size;
	float padding = [displayController requiredDistanceFromExistingDisplays];

	// Ask the display where it wants to be displayed in the first instance....
	NSPoint idealOrigin = [displayController idealOriginInRect:screenFrame];
	NSRect idealFrame = NSMakeRect(idealOrigin.x,idealOrigin.y,displaySize.width,displaySize.height);

	// Try and reserve the rect
	NSRect displayFrame = idealFrame;
	if ([self reserveRect:displayFrame inScreen:preferredScreen]) {
		[[displayController window] setFrameOrigin:displayFrame.origin];
		return YES;
	}

	// Something was blocking the display...try and find the next position for the display...
	enum GrowlExpansionDirection directionToTry = [displayController primaryExpansionDirection];
	BOOL isOnScreen = YES;
	unsigned secondaryCount = 0U;
	BOOL usingSecondaryDirection = NO;
	NSMutableSet *reservedRectsOfScreen = [self reservedRectsForScreen:preferredScreen];
	enum GrowlExpansionDirection secondaryDirection = [displayController secondaryExpansionDirection];
	NSValue *rectValue;
	while (directionToTry) {
		// adjust the rect...
		NSEnumerator *rectEnum = [reservedRectsOfScreen objectEnumerator];
		NSRect unionRect = NSZeroRect;
		switch (directionToTry) {
			case GrowlDownExpansionDirection:
				if (secondaryDirection == GrowlLeftExpansionDirection) {
					while ((rectValue = [rectEnum nextObject])) {
						NSRect rect = [rectValue rectValue];
						if (NSMaxX(rect) <= NSMaxX(displayFrame))
							unionRect = NSUnionRect(unionRect, rect);
					}
				} else if (secondaryDirection == GrowlRightExpansionDirection) {
					while ((rectValue = [rectEnum nextObject])) {
						NSRect rect = [rectValue rectValue];
						if (NSMinX(rect) >= NSMinX(displayFrame))
							unionRect = NSUnionRect(unionRect, rect);
					}
				} else {
					unionRect = displayFrame;
				}
				displayFrame.origin.y = NSMinY(unionRect) - padding - displayFrame.size.height;
				break;
			case GrowlUpExpansionDirection:
				if (secondaryDirection == GrowlLeftExpansionDirection) {
					while ((rectValue = [rectEnum nextObject])) {
						NSRect rect = [rectValue rectValue];
						if (NSMaxX(rect) <= NSMaxX(displayFrame))
							unionRect = NSUnionRect(unionRect, rect);
					}
				} else if (secondaryDirection == GrowlRightExpansionDirection) {
					while ((rectValue = [rectEnum nextObject])) {
						NSRect rect = [rectValue rectValue];
						if (NSMinX(rect) >= NSMinX(displayFrame))
							unionRect = NSUnionRect(unionRect, rect);
					}
				} else {
					unionRect = displayFrame;
				}
				displayFrame.origin.y = NSMaxY(unionRect) + padding;
				break;
			case GrowlLeftExpansionDirection:
				if (secondaryDirection == GrowlUpExpansionDirection) {
					while ((rectValue = [rectEnum nextObject])) {
						NSRect rect = [rectValue rectValue];
						if (NSMinY(rect) >= NSMinY(displayFrame))
							unionRect = NSUnionRect(unionRect, rect);
					}
				} else if (secondaryDirection == GrowlDownExpansionDirection) {
					while ((rectValue = [rectEnum nextObject])) {
						NSRect rect = [rectValue rectValue];
						if (NSMaxY(rect) <= NSMaxY(displayFrame))
							unionRect = NSUnionRect(unionRect, rect);
					}
				} else {
					unionRect = displayFrame;
				}
				displayFrame.origin.x = NSMinX(unionRect) - padding - displayFrame.size.width;
				break;
			case GrowlRightExpansionDirection:
				if (secondaryDirection == GrowlUpExpansionDirection) {
					while ((rectValue = [rectEnum nextObject])) {
						NSRect rect = [rectValue rectValue];
						if (NSMinY(rect) >= NSMinY(displayFrame))
							unionRect = NSUnionRect(unionRect, rect);
					}
				} else if (secondaryDirection == GrowlDownExpansionDirection) {
					while ((rectValue = [rectEnum nextObject])) {
						NSRect rect = [rectValue rectValue];
						if (NSMaxY(rect) <= NSMaxY(displayFrame))
							unionRect = NSUnionRect(unionRect, rect);
					}
				} else {
					unionRect = displayFrame;
				}
				displayFrame.origin.x = NSMaxX(unionRect) + padding;
				break;
			default:
				break;
		}

		// make sure the new rect still fits on screen...
		BOOL lastAttemptWasOnScreen = isOnScreen;
		isOnScreen = (NSContainsRect(screenFrame,displayFrame) ? YES : NO);

		// If the last two attempts were offscreen we've exausted all possibilities
		if (!isOnScreen && !lastAttemptWasOnScreen)
			break;

		// If we were using the secondary direction, switch back to the primary now...
		if (usingSecondaryDirection) {
			directionToTry = [displayController primaryExpansionDirection];
			usingSecondaryDirection = NO;
		}

		// If we've run offscreen see if we have a secondary direction...
		if (!isOnScreen) {
			switch (directionToTry) {
				case GrowlDownExpansionDirection:
				case GrowlUpExpansionDirection:
					displayFrame.origin.y = idealFrame.origin.y;
					break;
				case GrowlLeftExpansionDirection:
				case GrowlRightExpansionDirection:
					displayFrame.origin.x = idealFrame.origin.x;
					break;
				default:
					break;
			}
			directionToTry = secondaryDirection;
			secondaryCount++;
			usingSecondaryDirection = YES;
			continue;
		}

		// otherwise try and reserve the rect...
		if ([self reserveRect:displayFrame inScreen:preferredScreen]) {
			[[displayController window] setFrameOrigin:displayFrame.origin];
			return YES;
		}
	}
	return NO;
}

//Reserve a rect in a specific screen.
- (BOOL) reserveRect:(NSRect)inRect inScreen:(NSScreen *)inScreen {
	BOOL result = YES;

	if (NSContainsRect([inScreen visibleFrame], inRect)) {	//inRect must be inside our screen
		NSMutableSet	*reservedRectsOfScreen = [self reservedRectsForScreen:inScreen];
		NSValue			*newRectValue = [NSValue valueWithRect:inRect];
		NSEnumerator	*rectValuesEnumerator;
		NSValue			*value;

		@synchronized(reservedRectsOfScreen) {
			//Make sure the rect is not already reserved
			if ([reservedRectsOfScreen member:newRectValue]) {
				result = NO;
			} else {
				rectValuesEnumerator = [reservedRectsOfScreen objectEnumerator];

				// Loop through all the values in reservedRects and make sure
				// that the new rect does not intersect with any of the already
				// reserved rects.
				while ((value = [rectValuesEnumerator nextObject])) {
					if (NSIntersectsRect(inRect, [value rectValue])) {
						result = NO;
						break;
					}
				}
			}

			// Add the new rect if it passed the intersection test
			if (result)
				[reservedRectsOfScreen addObject:newRectValue];
		}
	}

	return result;
}

//Clear a reserved rect from a specific screen.
- (void) clearReservedRect:(NSRect)inRect inScreen:(NSScreen *)inScreen {
	NSMutableSet *reservedRectsOfScreen = [self reservedRectsForScreen:inScreen];
	NSValue		 *value;

	@synchronized(reservedRectsOfScreen) {
		//Remove the rect
		if ((value = [reservedRectsOfScreen member:[NSValue valueWithRect:inRect]]))
			[reservedRectsOfScreen removeObject:value];
	}
}

//Returns the set of reserved rect for a specific screen
- (NSMutableSet *)reservedRectsForScreen:(NSScreen *)screen {
	NSMutableSet *result = nil;

	//Treat nil as the main screen
	if (!screen)
		screen = [NSScreen mainScreen];

	//Get the set of reserved rects for our screen
	result = (NSMutableSet *)CFDictionaryGetValue(reservedRects, screen);

	//Make sure the set exists. If not, create it.
	if (!result) {
		@synchronized((NSMutableDictionary *)reservedRects) {
			result = [[NSMutableSet alloc] init];
			CFDictionarySetValue(reservedRects, screen, result);
			[result release];
		}
	}

	return result;
}

@end

NSString *NSStringFromGrowlPosition(enum GrowlPosition pos) {
	NSString *str = nil;

	NSString *first;
	switch (pos) {
		case GrowlTopLeftPosition:
		case GrowlTopMiddlePosition:
		case GrowlTopRightPosition:
		case GrowlTopRowPosition:
			first = @"top";
			break;

		case GrowlCenterLeftPosition:
		case GrowlCenterMiddlePosition:
		case GrowlCenterRightPosition:
		case GrowlCenterRowPosition:
			first = @"center";
			break;

		case GrowlBottomLeftPosition:
		case GrowlBottomMiddlePosition:
		case GrowlBottomRightPosition:
		case GrowlBottomRowPosition:
			first = @"bottom";
			break;

		case GrowlLeftColumnPosition:
			first = @"left";
			break;

		case GrowlMiddleColumnPosition:
			first = @"middle";
			break;

		case GrowlRightColumnPosition:
			first = @"right";
			break;

		default:
			first = nil;
	};

	NSString *second;
	switch (pos) {
		case GrowlTopLeftPosition:
		case GrowlCenterLeftPosition:
		case GrowlBottomLeftPosition:
			second = @"left";
			break;

		case GrowlTopMiddlePosition:
		case GrowlBottomMiddlePosition:
			second = @"center";
			break;

		case GrowlCenterMiddlePosition:
			//just say 'center'
			second = @"";
			break;

		case GrowlTopRightPosition:
		case GrowlCenterRightPosition:
		case GrowlBottomRightPosition:
			second = @"right";
			break;

		case GrowlTopRowPosition:
		case GrowlCenterRowPosition:
		case GrowlBottomRowPosition:
			second = @"row";
			break;

		case GrowlLeftColumnPosition:
		case GrowlMiddleColumnPosition:
		case GrowlRightColumnPosition:
			second = @"column";

		default:
			second = nil;
	};

	if (first && second) {
		unsigned  firstLength = [first  length];
		unsigned secondLength = [second length];

		if (firstLength && secondLength) {
			unsigned capacity = firstLength + secondLength + 1U;
			NSMutableString *mutable = [[NSMutableString alloc] initWithCapacity:capacity];

			[mutable appendString:first];
			[mutable appendCharacter:'-'];
			[mutable appendString:second];

			str = [mutable autorelease];
		} else if (firstLength || secondLength) {
			str = firstLength ? first : second;
		}
	}

	return str;
}	
NSString *NSStringFromGrowlExpansionDirection(enum GrowlExpansionDirection dir) {
	switch (dir) {
		case GrowlNoExpansionDirection:
			return @"nowhere";
		case GrowlDownExpansionDirection:
			return @"down";
		case GrowlUpExpansionDirection:
			return @"up";
		case GrowlLeftExpansionDirection:
			return @"left";
		case GrowlRightExpansionDirection:
			return @"right";
		default:
			return nil;
	};
}
