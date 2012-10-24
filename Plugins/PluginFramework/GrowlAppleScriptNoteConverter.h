//
//  GrowlAppleScriptNoteConverter.h
//  Growl
//
//  Created by Daniel Siemer on 10/24/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GrowlAppleScriptNoteConverter : NSObject

+(NSAppleEventDescriptor*)appleEventDescriptorForNotification:(NSDictionary*)dict;

@end
