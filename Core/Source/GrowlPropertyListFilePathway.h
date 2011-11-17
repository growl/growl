//
//  GrowlPropertyListFilePathway.h
//  Growl
//
//  Created by Peter Hosey on 2008-02-07.
//  Copyright 2008 Peter Hosey. All rights reserved.
//

#import "GrowlPathway.h"

@interface GrowlPropertyListFilePathway : GrowlPathway
{

}

+ (GrowlPropertyListFilePathway *) standardPathway;

- (BOOL) application:(NSApplication *)theApplication openFile:(NSString *)filename;

@end
