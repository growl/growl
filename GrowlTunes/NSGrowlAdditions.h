//
//  NSAdditions.h
//  Growl
//
//  Created by Karl Adam on Fri May 28 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSWorkspace (GrowlAdditions) 
- (NSImage *) iconForApplication:(NSString *) inName;
@end

