//
//  GrowlNotifyScriptCommand.h
//  Growl
//
//  Created by Patrick Linskey on Tue Aug 10 2004.
//  Copyright (c) 2004-2011 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GrowlNotifyScriptCommand : NSScriptCommand {
}

- (NSURL *) fileUrlForLocationReference:(NSString *)imageReference;

- (void) setError:(int)errorCode;
- (void) setError:(int)errorCode failure:(id)failure;

@end
