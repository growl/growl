//
//  NSObject+XPCHelpers.h
//  Growl
//
//  Created by Daniel Siemer on 9/15/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <xpc/xpc.h>


@interface NSObject (NSObject_XPCHelpers)

+(id)xpcObjectToNSObject:(xpc_object_t)object;
-(xpc_object_t)newXPCObject;

@end
