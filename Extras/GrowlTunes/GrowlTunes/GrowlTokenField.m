//
//  GrowlTokenField.m
//  GrowlTunes
//
//  Created by Daniel Siemer on 6/25/13.
//  Copyright (c) 2013 The Growl Project. All rights reserved.
//

#import "GrowlTokenField.h"
#import "FormattingToken.h"

@implementation GrowlTokenField

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)setFrame:(NSRect)frameRect {
	[super setFrame:frameRect];
	[self invalidateIntrinsicContentSize];
}

- (NSSize)intrinsicContentSize {
	CGSize size = [super intrinsicContentSize];
	CGFloat width = [self frame].size.width;
	__block CGFloat currentHeight = 0.0f;
	__block CGFloat currentWidth = 0.0f;
	__block CGFloat height = 16.0f;
	NSArray *array = [self objectValue];
	[array enumerateObjectsUsingBlock:^(FormattingToken *obj, NSUInteger idx, BOOL *stop) {
		NSTokenFieldCell *cell = [[NSTokenFieldCell alloc] init];
		[cell setObjectValue:[obj displayString]];
		[cell setTokenStyle:[obj tokenStyle]];
		
		CGSize cellSize = [cell cellSize];
		CGFloat cellHeight = cellSize.height;
		CGFloat cellWidth = cellSize.width;
		
		if(currentHeight == 0.0f)
			currentHeight = cellHeight;
		
		if(cellWidth > width){
			if(currentWidth > 0.0f){
				height += currentHeight;
				height += cellHeight;
				currentHeight = 0.0f;
				currentWidth = 0.0f;
			}else{
				height += currentHeight;
			}
		}else{
			if(currentWidth > 0.0f){
				if(currentWidth + cellWidth > width){
					height += currentHeight;
					currentWidth = cellWidth;
					currentHeight = cellHeight;
				}else if([[obj displayString] rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location != NSNotFound){
					height += currentHeight;
					currentWidth = 0.0f;
					currentHeight = cellHeight;
				}else{
					currentWidth += cellWidth;
				}
			}else{
				currentWidth = cellWidth;
			}
		}
		RELEASE(cell);
	}];
	if(self.tag > 0)
		height += 8.0f;
	size.height = height;
	return size;
}

@end
