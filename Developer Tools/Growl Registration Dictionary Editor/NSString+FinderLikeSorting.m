//
//  NSString+FinderLikeSorting.m
//  Growl Registration Dictionary Editor
//
//  Created by Peter Hosey on 2007-10-01.
//  Copyright 2007 Peter Hosey. All rights reserved.
//

#import "NSString+FinderLikeSorting.h"

#include <sys/param.h>

@implementation NSString (FinderLikeSorting)

- (NSComparisonResult) finderCompare:(NSString *)other {
	return sortFilenamesLikeFinder(self, other, /*context*/ NULL);
}

@end

//Based on sample code from QA1159: http://developer.apple.com/qa/qa2004/qa1159.html
int sortFilenamesLikeFinder(id filenameA, id filenameB, void *context) {
	static UTF16Char filenameA_UTF16[MAXPATHLEN];
	[filenameA getCharacters:filenameA_UTF16];
	static UTF16Char filenameB_UTF16[MAXPATHLEN];
	[filenameB getCharacters:filenameB_UTF16];

	SInt32 comparisonResult;
	OSStatus err = UCCompareTextDefault(  kUCCollateComposeInsensitiveMask
	                                    | kUCCollateWidthInsensitiveMask
	                                    | kUCCollateCaseInsensitiveMask
	                                    | kUCCollateDigitsOverrideMask
	                                    | kUCCollateDigitsAsNumberMask
	                                    | kUCCollatePunctuationSignificantMask,
	                                    filenameA_UTF16,
	                                    [filenameA length],
	                                    filenameB_UTF16,
	                                    [filenameB length],
	                                    /*equivalent?*/ NULL,
	                                    &comparisonResult);

	/*Quoth the technote:
	 *
	 *Return the result.  Conveniently, UCCompareTextDefault
	 *returns -1, 0, or +1, which matches the values for
	 *~~CF~~NSComparisonResult exactly.
	 */
    return (NSComparisonResult)comparisonResult;
}
