//
//  GrowlProcessTransformation.h
//  GrowlTunes
//
//  Created by Daniel Siemer on 11/20/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GrowlProcessTransformation : NSObject

+(BOOL)makeForgroundApp;
+(BOOL)makeUIElementApp;

@end
