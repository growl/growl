//
//  GrowlImageAdditions.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 20/09/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlImageAdditions.h"


@implementation NSImage (GrowlImageAdditions)

- (NSSize)adjustSizeToDrawAtSize:(NSSize)theSize{
    NSImageRep *bestRep=[self bestRepresentationForSize:theSize];
    [self setSize:[bestRep size]];
    return [bestRep size];
}
- (NSImageRep *)bestRepresentationForSize:(NSSize)theSize{
	NSImageRep *bestRep=[self representationOfSize:theSize];
	   //[self setCacheMode:NSImageCacheNever];
    if (bestRep){
		
		//	NSLog(@"getRep? %f", theSize.width);
		return bestRep;
		
	}else{
		//	NSLog(@"getRex? %f", theSize.width);
	}
    NSArray *reps=[self representations];
    // if (theSize.width==theSize.height){
	// ***warning   * handle other sizes
    float repDistance=65536.0;
	// ***warning   * this is totally not the highest, but hey...
    NSImageRep *thisRep;
    float thisDistance;
    int i;
    for (i=0;i<(int)[reps count];i++){
        thisRep=[reps objectAtIndex:i];
        thisDistance=theSize.width-[thisRep size].width;  if (repDistance<0 && thisDistance>0) continue;
        if (ABS(thisDistance)<ABS(repDistance)|| (thisDistance<0 && repDistance>0)){
            repDistance=thisDistance;
            bestRep=thisRep;
        }
    }
	///NSLog(@"   Rex? %@", bestRep);
	
    if (bestRep) return bestRep;
    bestRep=[self bestRepresentationForDevice:nil];
	//   NSLog(@"unable to find reps %@",reps);

    return bestRep;
    return nil;
    }
- (NSImageRep *)representationOfSize:(NSSize)theSize{
    NSArray *reps=[self representations];
    int i;
    for (i=0;i<(int)[reps count];i++)
        if (NSEqualSizes([[reps objectAtIndex:i]size],theSize))
            return [reps objectAtIndex:i];
    return nil;
}

@end