//
//  NSNumber+KNRandom.m
//  Hurricane
//
//  Created by Keith on 1/22/05.
//  Copyright 2005 Keith Anderson. All rights reserved.
//

#import "NSNumber+KNRandom.h"
#include <time.h>
#include <math.h>

@implementation NSNumber (KNRandom)

+(void)initRandom{
	srandom( time(NULL) );
}

+(float)randomFloat{
	return((float) random() / (float)RAND_MAX);
}

/*
+(NSNumber *)randomNumber{
	return [NSNumber numberWithFloat: ((float) random() / (float)RANDOM_MAX)];
}
*/

+(int)randomIntInRange:(NSRange)range{
	return( range.location + (random() % range.length) );
}

@end
