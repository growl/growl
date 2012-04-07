//
//  NSScreen+GrowlScreenAdditions.h
//  Growl
//
//  Created by Daniel Siemer on 4/6/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSScreen (GrowlScreenAdditions)

-(NSUInteger)screenID;
-(NSString*)screenIDString;

@end
