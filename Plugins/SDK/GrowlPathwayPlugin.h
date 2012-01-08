//
//  GrowlPathPlugin.h
//  Growl
//
//  Created by Zac Bowling on 1/7/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GrowlPlugin.h"

@protocol GrowlPathwayPlugin <GrowlPlugin>

- (NSArray *) pathways;

@end
