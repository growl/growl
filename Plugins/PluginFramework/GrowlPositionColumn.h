//
//  GrowlPositionColumn.h
//  PositionController
//
//  Created by Daniel Siemer on 3/26/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GrowlPositionColumn : NSObject {
	CGFloat xOrigin;
	CGFloat width;
	NSMutableArray *rects;
}

@property (nonatomic) CGFloat xOrigin;
@property (nonatomic) CGFloat width;
@property (nonatomic, retain) NSMutableArray *rects;

-(void)addWidth:(CGFloat)newWidth;
-(void)removeWidth:(CGFloat)oldWidth;
-(CGFloat)minWidth;

@end
