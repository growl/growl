//
//  GrowlPositionController.h
//  Growl
//
//  Created by Ofri Wolfus on 31/08/05.
//  Copyright 2005 Ofri Wolfus. All rights reserved.
//

#import "GrowlAbstractSingletonObject.h"
#import "GrowlDisplayProtocol.h"

typedef enum {
	GrowlTopLeftPosition,
	GrowlTopMiddlePosition,
	GrowlTopRightPosition,
	GrowlCenterLeftPosition,
	GrowlCenterMiddlePosition,
	GrowlCenterRightPosition,
	GrowlBottomLeftPosition,
	GrowlBottomMiddlePosition,
	GrowlBottomRightPosition,
	GrowlTopRowPosition,
	GrowlCenterRowPosition,
	GrowlBottomRowPosition,
	GrowlLeftColumnPosition,
	GrowlMiddleColumnPosition,
	GrowlRightColumnPosition
} GrowlPosition;

@interface GrowlPositionController : GrowlAbstractSingletonObject {
	NSMutableDictionary	*reservedRects;
}

/*!
 * @method rectForPosition:inScreen:
 * @abstract Returns a rect for a specific position in a specific screen.
 */
+ (NSRect) rectForPosition:(GrowlPosition)position inScreen:(NSScreen *)screen;

/*!
 * @method reserveRect:inScreen:
 * @abstract Reserves a rect for a notification in a specific screen.
 * @discussion Reserves a rect for a notification.
 * Before a notification is displayed, it should reserve the rect of screen it's going to use.
 * When a rect is reserved, no other notification can use it so you must clear it when you're done with it.
 * @param inRect The rect that should be reserved.
 * @param inScreen The screen which contains inRect.
 * @result YES or NO. If the result is NO, you should display your notification in a different rect/screen.
 */
- (BOOL) reserveRect:(NSRect)inRect inScreen:(NSScreen *)inScreen;

/*!
 * @method clearReservedRect:inScreen:
 * @abstract Clear a reserved notification rect.
 * @param inRect The reserved rect that should be cleared.
 * @param inScreen The screen which contains inRect.
 */
- (void) clearReservedRect:(NSRect)inRect inScreen:(NSScreen *)inScreen;

@end
