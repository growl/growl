//
//  GrowlScriptCommand.h
//  Growl
//
//  Created by Patrick Linskey on Tue Aug 10 2004.
//  Copyright (c) 2004 Patrick Linskey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/NSScriptCommand.h>

@interface GrowlScriptCommand : NSScriptCommand {

}

- (void) setError:(int) errorCode;
- (void) setError:(int) errorCode failure:(id) failure;
	
@end
