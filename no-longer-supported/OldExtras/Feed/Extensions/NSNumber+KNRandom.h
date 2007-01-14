//
//  NSNumber+KNRandom.h
//  Hurricane
//
//  Created by Keith on 1/22/05.
//  Copyright 2005 Keith Anderson. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSNumber (KNRandom)
+(void)initRandom;
+(float)randomFloat;
//+(NSNumber)randomNumber;
+(int)randomIntInRange:(NSRange)range;
@end
