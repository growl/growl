//
//  GrowlQuadTreeNode.h
//  PositionController
//
//  Created by Daniel Siemer on 3/26/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define GrowlQuadTreeDividedState -1
#define GrowlQuadTreeEmptyState 0
#define GrowlQuadTreeOccupiedState 1

typedef enum {
	QuadLeft,
	QuadRight,
	QuadUp,
	QuadDown
} GrowlQuadTreeDirection;

@interface GrowlQuadTreeNode : NSObject

-(id)initWithState:(NSInteger)newState forRect:(CGRect)aRect;

-(BOOL)consolidate;
-(void)occupyFrame:(CGRect)aRect;
-(void)vacateFrame:(CGRect)aRect;
-(BOOL)isFrameFree:(CGRect)aRect;

@end
