//
//  GrowlUserScriptTaskUtilities.h
//  Growl
//
//  Created by Daniel Siemer on 10/24/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GrowlUserScriptTaskUtilities : NSObject

+(BOOL)hasScriptTaskClass;
+(NSURL*)baseScriptDirectoryURL;
+(NSArray*)contentsOfScriptDirectory;
+(BOOL)hasRulesScript;
+(NSUserScriptTask*)scriptTaskForFile:(NSString*)fileName;
+(NSUserAppleScriptTask*)rulesScriptTask;
+(NSAppleEventDescriptor*)appleEventDescriptorForNotification:(NSDictionary*)dict;
+(BOOL)isAppleEventDescriptorBoolean:(NSAppleEventDescriptor*)event;

@end
