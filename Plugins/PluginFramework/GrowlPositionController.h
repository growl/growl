//
//  GrowlPositionController.h
//  PositionController
//
//  Created by Daniel Siemer on 3/26/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GrowlPositioningDefines.h"

#import "GrowlQuadTreeNode.h"

@interface GrowlPositionController : NSObject {
	QuadTreeNode *c_rootNode;
	GrowlQuadTreeNode *rootNode;
	NSMutableArray *allColumns;
	NSMutableArray *leftColumns;
	NSMutableArray *rightColumns;
	CGFloat availableWidth;
	
	CGRect screenFrame;
	BOOL updateFrame;
	CGRect newFrame;
	NSUInteger deviceID;
}

@property (nonatomic) CGRect screenFrame;
@property (nonatomic) BOOL updateFrame;
@property (nonatomic) CGRect newFrame;
@property (nonatomic) NSUInteger deviceID;

-(id)initWithScreenFrame:(CGRect)frame;
-(BOOL)isFrameFree:(CGRect)frame;
-(CGRect)canFindSpotForSize:(CGSize)size 
			startingInPosition:(GrowlPositionOrigin)start;
-(void)occupyRect:(CGRect)rect;
-(void)vacateRect:(CGRect)rect;

@end
