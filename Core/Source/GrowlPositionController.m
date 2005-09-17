//
//  GrowlPositionController.m
//  Growl
//
//  Created by Ofri Wolfus on 31/08/05.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details
//

#import "GrowlPositionController.h"


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
+ (NSRect) rectForPosition:(GrowlPosition)position inScreen:(NSScreen *)screen {
	NSRect screenFrame = [screen visibleFrame];
	NSSize areaSize = NSMakeSize(screenFrame.size.width / 3.0f, screenFrame.size.height / 3.0f);	//We have 9 identical areas on each screen
	NSRect result = NSZeroRect;

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


//Reserve a rect in a specific screen.
- (BOOL) reserveRect:(NSRect)inRect inScreen:(NSScreen *)inScreen {
	BOOL			result = YES;

	if (NSContainsRect([inScreen visibleFrame], inRect)) {	//inRect must be inside our screen
		NSMutableSet	*reservedRectsOfScreen = (NSMutableSet *)CFDictionaryGetValue(reservedRects, inScreen);
		NSValue			*newRectValue = [NSValue valueWithRect:inRect];
		NSEnumerator	*rectValuesEnumerator;
		NSValue			*value;

		//Make sure the set exists. If not, create it.
		if (!reservedRectsOfScreen) {
			reservedRectsOfScreen = [[NSMutableSet alloc] init];
			CFDictionarySetValue(reservedRects, inScreen, reservedRectsOfScreen);
			[reservedRectsOfScreen release];
		}

		if ([reservedRectsOfScreen member:newRectValue]) {	//Make sure the rect is not already reserved
			result = NO;
		} else {
			rectValuesEnumerator = [reservedRectsOfScreen objectEnumerator];

			//Loop through all the values in reservedRects and make sure that the new rect does not
			//intersect with any of the already reserved rects.
			while ((value = [rectValuesEnumerator nextObject])) {
				if (NSIntersectsRect(inRect, [value rectValue])) {
					result = NO;
					break;
				}
			}
		}

		//Add the new rect if it passed the intersection test
		if (result)
			[reservedRectsOfScreen addObject:newRectValue];
	}

	return result;
}

//Clear a reserved rect from a specific screen.
- (void) clearReservedRect:(NSRect)inRect inScreen:(NSScreen *)inScreen {
	NSMutableSet *reservedRectsOfScreen = (NSMutableSet *)CFDictionaryGetValue(reservedRects, inScreen);
	NSValue		 *value;

	//Make sure the set exists. If not, create it.
	if (!reservedRectsOfScreen) {
		reservedRectsOfScreen = [[NSMutableSet alloc] init];
		CFDictionarySetValue(reservedRects, inScreen, reservedRectsOfScreen);
		[reservedRectsOfScreen release];
	}

	//Remove the rect
	if ((value = [reservedRectsOfScreen member:[NSValue valueWithRect:inRect]]))
		[reservedRectsOfScreen removeObject:value];
}

@end
