//
//  GrowlPositionController.h
//  Growl
//
//  Created by Ofri Wolfus on 31/08/05.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details
//

#import "GrowlAbstractSingletonObject.h"
#import "GrowlDisplayProtocol.h"

/*!
 * @typedef GrowlPosition
 * @abstract Represents a general position on the screen for display plugins.
 *
 * @constant GrowlTopLeftPosition The top left square of the screen.
 * @constant GrowlTopMiddlePosition The top middle square of the screen.
 * @constant GrowlTopRightPosition The top right square of the screen.
 * @constant GrowlCenterLeftPosition The center left square of the screen.
 * @constant GrowlCenterMiddlePosition The center middle square of the screen.
 * @constant GrowlCenterRightPosition The center right square of the screen.
 * @constant GrowlBottomLeftPosition The bottom left square of the screen.
 * @constant GrowlBottomMiddlePosition The bottom left middle of the screen.
 * @constant GrowlBottomRightPosition The bottom right square of the screen.
 * @constant GrowlTopRowPosition The top oblong (row) of the screen.
 * @constant GrowlCenterRowPosition The center oblong (row) of the screen.
 * @constant GrowlBottomRowPosition The bottom oblong (row) of the screen.
 * @constant GrowlLeftColumnPosition The bottom oblong (column) of the screen.
 * @constant GrowlMiddleColumnPosition The middle oblong (column) of the screen.
 * @constant GrowlRightColumnPosition The right oblong (column) of the screen.
 */
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

/*!
 * @class GrowlPositionController
 * @abstract GrowlPositionController provides a mechanism for display plugins to display without disturbing each other.
 */
@interface GrowlPositionController : GrowlAbstractSingletonObject {
	CFMutableDictionaryRef	reservedRects;
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
