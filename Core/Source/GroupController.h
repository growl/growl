//
//  GroupController.h
//  Growl
//
//  Created by Daniel Siemer on 8/13/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GroupController : NSObject

@property (nonatomic, retain) NSString *groupID;
@property (nonatomic, retain) NSArrayController *groupArray;
@property (nonatomic) BOOL showGroup;

-(id)initWithGroupID:(NSString*)newID arrayController:(NSArrayController*)controller;

@end
