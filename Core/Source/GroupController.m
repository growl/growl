//
//  GroupController.m
//  Growl
//
//  Created by Daniel Siemer on 8/13/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GroupController.h"

@implementation GroupController

@synthesize groupID;
@synthesize groupArray;
@synthesize showGroup;

- (id)initWithGroupID:(NSString*)newID
      arrayController:(NSArrayController*)controller
{
    self = [super init];
    if (self) {
        self.groupID = newID;
        self.groupArray = controller;
        showGroup = YES;
        // Initialization code here.
    }
    
    return self;
}

-(void)dealloc
{
    [groupID release];
    [groupArray release];
}

-(NSComparisonResult)compare:(id)obj2
{
    if([obj2 isKindOfClass:[self class]])
        return [groupID caseInsensitiveCompare:[obj2 groupID]];
    else
        return NSOrderedDescending;
}

@end
