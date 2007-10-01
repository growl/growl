//
//  NSString+FinderLikeSorting.h
//  Growl Registration Dictionary Editor
//
//  Created by Peter Hosey on 2007-10-01.
//  Copyright 2007 Peter Hosey. All rights reserved.
//

@interface NSString (FinderLikeSorting)

//Sort two strings (ostensibly, filenames) like the Finder would. Uses the QA1159 algorithm: http://developer.apple.com/qa/qa2004/qa1159.html
- (NSComparisonResult) finderCompare:(NSString *)other;

@end

/*Comparison function for use with -[NSArray sortedArrayUsingFunction:context:] and -[NSMutableArray sortUsingFunction:context:].
 *Should also work with CFArraySortValues, if you cast the function pointer (CF's comparator-function type doesn't use ids).
 *Uses the QA1159 algorithm.
 */
extern int sortFilenamesLikeFinder(id filenameA, id filenameB, void *context);
