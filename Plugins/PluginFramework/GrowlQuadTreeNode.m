//
//  GrowlQuadTreeNode.m
//  PositionController
//
//  Created by Daniel Siemer on 3/26/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "GrowlQuadTreeNode.h"

@interface GrowlQuadTreeNode ()

@property (nonatomic) NSInteger state;
@property (nonatomic) CGRect frame;

@property (nonatomic, retain) GrowlQuadTreeNode *topLeft;
@property (nonatomic, retain) GrowlQuadTreeNode *topRight;
@property (nonatomic, retain) GrowlQuadTreeNode *bottomLeft;
@property (nonatomic, retain) GrowlQuadTreeNode *bottomRight;

@end

@implementation GrowlQuadTreeNode

@synthesize state;
@synthesize frame;

@synthesize topLeft;
@synthesize topRight;
@synthesize bottomLeft;
@synthesize bottomRight;

-(id)initWithState:(NSInteger)newState forRect:(CGRect)aRect {
	if((self = [super init])){
		self.state = newState;
		self.frame = aRect;
	}
	return self;
}

-(void)dealloc {
	[topLeft release];
	[topRight release];
	[bottomLeft release];
	[bottomRight release];
	[super dealloc];
}

-(BOOL)createChildren{
	if(topLeft){
		NSLog(@"Error! we shouldn't be creating children when we already have children");
		return NO;
	}
	if(frame.size.width <= 1.0 && frame.size.height <= 1.0f){
		//NSLog(@"Error! we shouldn't be subdividing smaller than 1x1 wide/one high");
		return NO;
	}
	
	CGFloat childWidth = frame.size.width / 2.0f;
	CGFloat childHeight = frame.size.height / 2.0f;
	CGRect bottomLeftRect = CGRectMake(frame.origin.x, frame.origin.y, childWidth, childHeight);
	CGRect bottomRightRect = CGRectMake(frame.origin.x + childWidth, frame.origin.y, childWidth, childHeight);
	CGRect topLeftRect = CGRectMake(frame.origin.x, frame.origin.y + childHeight, childWidth, childHeight);
	CGRect topRightRect = CGRectMake(frame.origin.x + childWidth, frame.origin.y + childHeight, childWidth, childHeight);
	self.topLeft = [[[GrowlQuadTreeNode alloc] initWithState:state 
																	 forRect:topLeftRect] autorelease];
	self.topRight = [[[GrowlQuadTreeNode alloc] initWithState:state 
																	  forRect:topRightRect] autorelease];
	self.bottomLeft = [[[GrowlQuadTreeNode alloc] initWithState:state 
																		 forRect:bottomLeftRect] autorelease];
	self.bottomRight = [[[GrowlQuadTreeNode alloc] initWithState:state 
																		  forRect:bottomRightRect] autorelease];	
	self.state = GrowlQuadTreeDividedState;
	return YES;
}

/* Consolidate is a recursive call.
 * If we have no children, return YES, we are consolidated
 * If all our children return that they are consolidated and they are all the same state
 * than we can consolidate
 * Other situations, return no, we cant be consolidated
 */
-(BOOL)consolidate {
	if(!topLeft){
		return YES;
	}
	if([topLeft consolidate] && 
		[topRight consolidate] &&
		[bottomLeft consolidate] &&
		[bottomRight consolidate])
	{
		
		if(topLeft.state == topRight.state && 
			topRight.state == bottomLeft.state && 
			bottomLeft.state == bottomRight.state) 
		{
			self.state = topLeft.state;
			self.topLeft = nil;
			self.topRight = nil;
			self.bottomLeft = nil;
			self.bottomRight = nil;
			return YES;
		} else {
			return NO;
		}
	}else{
		return NO;
	}
}

/* Union operation, makes the entire frame occupied
 */
-(void)occupyFrame:(CGRect)aRect {
	/*if(![self isFrameFree:aRect]){
		NSLog(@"Woah, occupying rect that isn't free");
	}*/
	CGRect intersection = CGRectIntersection(aRect, frame);
	if(CGRectEqualToRect(intersection, frame)){
		//Occupy the whole thing, if we are divided, tell them to occupy, then use the consolidate chain mechanism
		if(state == GrowlQuadTreeDividedState){
			if(CGRectIntersectsRect(aRect, topLeft.frame))
				[topLeft occupyFrame:aRect];
			if(CGRectIntersectsRect(aRect, topRight.frame))
				[topRight occupyFrame:aRect];
			if(CGRectIntersectsRect(aRect, bottomLeft.frame))
				[bottomLeft occupyFrame:aRect];
			if(CGRectIntersectsRect(aRect, bottomRight.frame))
				[bottomRight occupyFrame:aRect];
			//[self consolidate];
		}else{
			self.state = GrowlQuadTreeOccupiedState;
		}
	}else{
		if(state != GrowlQuadTreeDividedState){
			//if we cant create children, than we have subdivided as far as we can (size cant be < 1x1)
			//set our state as occupied
			if(![self createChildren])
				self.state = GrowlQuadTreeOccupiedState;
		}
		//If we have children, update them
		if(topLeft){
			//No need to call down in to a child unless the rects intersect
			if(CGRectIntersectsRect(aRect, topLeft.frame))
				[topLeft occupyFrame:aRect];
			if(CGRectIntersectsRect(aRect, topRight.frame))
				[topRight occupyFrame:aRect];
			if(CGRectIntersectsRect(aRect, bottomLeft.frame))
				[bottomLeft occupyFrame:aRect];
			if(CGRectIntersectsRect(aRect, bottomRight.frame))
				[bottomRight occupyFrame:aRect];
		}
	}
}

/* Subtract operation, leaves just the frame requested in empty state
 * If all is full, or all is empty
 */
-(void)vacateFrame:(CGRect)aRect {
	if(state == GrowlQuadTreeDividedState){
		if(CGRectIntersectsRect(aRect, topLeft.frame))
			[topLeft vacateFrame:aRect];
		if(CGRectIntersectsRect(aRect, topRight.frame))
			[topRight vacateFrame:aRect];
		if(CGRectIntersectsRect(aRect, bottomLeft.frame))
			[bottomLeft vacateFrame:aRect];
		if(CGRectIntersectsRect(aRect, bottomRight.frame))
			[bottomRight vacateFrame:aRect];
		//[self consolidate];
	}else{
		if(CGRectIntersectsRect(aRect, frame))
			self.state = GrowlQuadTreeEmptyState;
	}
}

-(BOOL)isFrameFree:(CGRect)aRect {
	if(state == GrowlQuadTreeEmptyState){
		return YES;
	}
	if(state == GrowlQuadTreeOccupiedState){
		return NO;
	}
	BOOL result = YES;
	if(CGRectIntersectsRect(aRect, topLeft.frame)){
		result = [topLeft isFrameFree:aRect];
	}
	if(result && CGRectIntersectsRect(aRect, topRight.frame)){
		result = [topRight isFrameFree:aRect];
	}
	if(result && CGRectIntersectsRect(aRect, bottomLeft.frame)){
		result = [bottomLeft isFrameFree:aRect];
	}
	if(result && CGRectIntersectsRect(aRect, bottomRight.frame)){
		result = [bottomRight isFrameFree:aRect];
	}
	return result;
}

-(BOOL)isPointFree:(CGPoint)point {
	if(state == GrowlQuadTreeEmptyState)
		return YES;
	if(state == GrowlQuadTreeOccupiedState)
		return NO;
	if(state == GrowlQuadTreeDividedState){
		if(CGRectContainsPoint(topLeft.frame, point))
			return [topLeft isPointFree:point];
		if(CGRectContainsPoint(topRight.frame, point))
			return [topRight isPointFree:point];
		if(CGRectContainsPoint(bottomLeft.frame, point))
			return [bottomLeft isPointFree:point];
		if(CGRectContainsPoint(bottomRight.frame, point))
			return [bottomRight isPointFree:point];
	}
	//Should be unreachable
	return NO;
}

-(NSString*)description {
	return [NSString stringWithFormat:@"%@ rect: %@ state %ld", [super description], NSStringFromRect(frame), state];
}

@end

BOOL create_children(QuadTreeNode *node){
	CGRect frame = node->frame;
	if(node->topLeft != NULL){
		//NSLog(@"Error! we shouldn't be creating children when we already have children");
		return NO;
	}
	if(frame.size.width <= 1.0 && frame.size.height <= 1.0f){
		//NSLog(@"Error! we shouldn't be subdividing smaller than 1x1 wide/one high");
		return NO;
	}
	
	CGFloat childWidth = frame.size.width / 2.0f;
	CGFloat childHeight = frame.size.height / 2.0f;
	CGRect bottomLeftRect = CGRectMake(frame.origin.x, frame.origin.y, childWidth, childHeight);
	CGRect bottomRightRect = CGRectMake(frame.origin.x + childWidth, frame.origin.y, childWidth, childHeight);
	CGRect topLeftRect = CGRectMake(frame.origin.x, frame.origin.y + childHeight, childWidth, childHeight);
	CGRect topRightRect = CGRectMake(frame.origin.x + childWidth, frame.origin.y + childHeight, childWidth, childHeight);
	node->topLeft = (QuadTreeNode*)malloc(sizeof(QuadTreeNode));
	node->topRight = (QuadTreeNode*)malloc(sizeof(QuadTreeNode));
	node->bottomLeft = (QuadTreeNode*)malloc(sizeof(QuadTreeNode));
	node->bottomRight = (QuadTreeNode*)malloc(sizeof(QuadTreeNode));
	
	if(node->topLeft != NULL && node->topRight != NULL && node->bottomLeft != NULL && node->bottomRight != NULL)
	{
		node->topLeft->frame = topLeftRect;
		node->topLeft->state = node->state;
		node->topLeft->topLeft = NULL;
		node->topLeft->topRight = NULL;
		node->topLeft->bottomLeft = NULL;
		node->topLeft->bottomRight = NULL;

		node->topRight->frame = topRightRect;
		node->topRight->state = node->state;
		node->topRight->topLeft = NULL;
		node->topRight->topRight = NULL;
		node->topRight->bottomLeft = NULL;
		node->topRight->bottomRight = NULL;

		node->bottomLeft->frame = bottomLeftRect;
		node->bottomLeft->state = node->state;
		node->bottomLeft->topLeft = NULL;
		node->bottomLeft->topRight = NULL;
		node->bottomLeft->bottomLeft = NULL;
		node->bottomLeft->bottomRight = NULL;

		node->bottomRight->frame = bottomRightRect;
		node->bottomRight->state = node->state;
		node->bottomRight->topLeft = NULL;
		node->bottomRight->topRight = NULL;
		node->bottomRight->bottomLeft = NULL;
		node->bottomRight->bottomRight = NULL;

		node->state = GrowlQuadTreeDividedState;
		return YES;
	}
	NSLog(@"Malloc failed on at least one of the nodes");
	if(node->topLeft != NULL)
		free(node->topLeft);
	if(node->topRight != NULL)
		free(node->topRight);
	if(node->bottomLeft != NULL)
		free(node->bottomLeft);
	if(node->bottomRight != NULL)
		free(node->bottomRight);
	return NO;
}

BOOL c_consolidate(QuadTreeNode *node) {
	if(node == NULL || node->topLeft == NULL){
		return YES;
	}
	if(c_consolidate(node->topLeft) && 
		c_consolidate(node->topRight) &&
		c_consolidate(node->bottomLeft) &&
		c_consolidate(node->bottomRight))
	{
		
		if(node->topLeft->state == node->topRight->state && 
			node->topRight->state == node->bottomLeft->state && 
			node->bottomLeft->state == node->bottomRight->state) 
		{
			node->state = node->topLeft->state;
			free(node->topLeft);
			node->topLeft = NULL;
			free(node->topRight);
			node->topRight = NULL;
			free(node->bottomLeft);
			node->bottomLeft = NULL;
			free(node->bottomRight);
			node->bottomRight = NULL;
			return YES;
		} else {
			return NO;
		}
	}else{
		return NO;
	}

}
void occupy_frame(QuadTreeNode *node, CGRect aRect) {
	CGRect intersection = CGRectIntersection(aRect, node->frame);
	if(CGRectEqualToRect(intersection, node->frame)){
		//Occupy the whole thing, if we are divided, tell them to occupy, then use the consolidate chain mechanism
		if(node->state == GrowlQuadTreeDividedState){
			if(CGRectIntersectsRect(aRect, node->topLeft->frame))
				occupy_frame(node->topLeft, aRect);
			if(CGRectIntersectsRect(aRect, node->topRight->frame))
				occupy_frame(node->topRight, aRect);
			if(CGRectIntersectsRect(aRect, node->bottomLeft->frame))
				occupy_frame(node->bottomLeft, aRect);
			if(CGRectIntersectsRect(aRect, node->bottomRight->frame))
				occupy_frame(node->bottomRight, aRect);
		}else{
			node->state = GrowlQuadTreeOccupiedState;
		}
	}else{
		if(node->state != GrowlQuadTreeDividedState){
			//if we cant create children, than we have subdivided as far as we can (size cant be < 1x1)
			//set our state as occupied
			if(!create_children(node))
				node->state = GrowlQuadTreeOccupiedState;
		}
		//If we have children, update them
		if(node->topLeft != NULL){
			//No need to call down in to a child unless the rects intersect
			if(CGRectIntersectsRect(aRect, node->topLeft->frame))
				occupy_frame(node->topLeft, aRect);
			if(CGRectIntersectsRect(aRect, node->topRight->frame))
				occupy_frame(node->topRight, aRect);
			if(CGRectIntersectsRect(aRect, node->bottomLeft->frame))
				occupy_frame(node->bottomLeft, aRect);
			if(CGRectIntersectsRect(aRect, node->bottomRight->frame))
				occupy_frame(node->bottomRight, aRect);
		}
	}
}
void vacate_frame(QuadTreeNode *node, CGRect aRect) {
	if(node->state == GrowlQuadTreeDividedState){
		if(CGRectIntersectsRect(aRect, node->topLeft->frame))
			vacate_frame(node->topLeft, aRect);
		if(CGRectIntersectsRect(aRect, node->topRight->frame))
			vacate_frame(node->topRight, aRect);
		if(CGRectIntersectsRect(aRect, node->bottomLeft->frame))
			vacate_frame(node->bottomLeft, aRect);
		if(CGRectIntersectsRect(aRect, node->bottomRight->frame))
			vacate_frame(node->bottomRight, aRect);
	}else{
		if(CGRectIntersectsRect(aRect, node->frame))
			node->state = GrowlQuadTreeEmptyState;
	}
}
BOOL is_frame_free(QuadTreeNode *node, CGRect aRect) {
	if(node->state == GrowlQuadTreeEmptyState){
		return YES;
	}
	if(node->state == GrowlQuadTreeOccupiedState){
		return NO;
	}
	BOOL result = YES;
	if(CGRectIntersectsRect(aRect, node->topLeft->frame)){
		result = is_frame_free(node->topLeft, aRect);
	}
	if(result && CGRectIntersectsRect(aRect, node->topRight->frame)){
		result = is_frame_free(node->topRight, aRect);
	}
	if(result && CGRectIntersectsRect(aRect, node->bottomLeft->frame)){
		result = is_frame_free(node->bottomLeft, aRect);
	}
	if(result && CGRectIntersectsRect(aRect, node->bottomRight->frame)){
		result = is_frame_free(node->bottomRight, aRect);
	}
	return result;

}
