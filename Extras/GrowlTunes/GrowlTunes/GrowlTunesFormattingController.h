//
//  GrowlTunesFormattingController.h
//  GrowlTunes
//
//  Created by Daniel Siemer on 11/18/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "macros.h"

@interface GrowlTunesFormattingController : NSObject

-(NSArray*)tokenCloud;
-(NSArray*)allTokenDicts;
-(NSArray*)tokensForType:(NSString*)type andAttribute:(NSString*)attribute;
-(void)saveTokens;

@end
