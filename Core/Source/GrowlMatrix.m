//
//  GrowlMatrix.m
//  Growl
//
//  Created by Daniel Siemer on 2/14/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlMatrix.h"

@implementation GrowlMatrix

-(NSSize)intrinsicContentSize {
   __block NSSize newSize = [super intrinsicContentSize];
   [[self cells] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([obj cellSize].width > newSize.width)
         newSize.width = [obj cellSize].width;
   }];
   return newSize;
}

@end
