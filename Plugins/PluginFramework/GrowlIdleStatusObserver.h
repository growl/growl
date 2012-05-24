//
//  GrowlIdleStatusObserver.h
//  Growl
//
//  Created by Daniel Siemer on 3/14/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GrowlIdleStatusObserver : NSObject

@property (nonatomic, readonly) BOOL isIdle;

+ (GrowlIdleStatusObserver*)sharedObserver;

-(NSDate*)lastActive;

@end
