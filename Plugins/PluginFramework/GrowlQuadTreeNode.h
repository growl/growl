//
//  GrowlQuadTreeNode.h
//  PositionController
//
//  Created by Daniel Siemer on 3/26/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

//#define GROWL_OBJC_QUADTREE

#define GrowlQuadTreeDividedState -1
#define GrowlQuadTreeEmptyState 0
#define GrowlQuadTreeOccupiedState 1
typedef struct QuadTreeNode {
	struct QuadTreeNode *topLeft;
	struct QuadTreeNode *topRight;
	struct QuadTreeNode *bottomLeft;
	struct QuadTreeNode *bottomRight;
	int state;
	CGRect frame;
} QuadTreeNode;

BOOL create_children(QuadTreeNode *node);
BOOL c_consolidate(QuadTreeNode *node);
void occupy_frame(QuadTreeNode *node, CGRect aRect);
void vacate_frame(QuadTreeNode *node, CGRect aRect);
BOOL is_frame_free(QuadTreeNode *node, CGRect aRect);

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
