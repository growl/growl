//
//  GrowlProcessTransofmation.h
//  GrowlTunes
//
//  Created by Daniel Siemer on 11/20/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GrowlProcessTransofmation : NSObject

+(BOOL)makeForgroundApp;
+(BOOL)makeBackgroundApp;

@end
