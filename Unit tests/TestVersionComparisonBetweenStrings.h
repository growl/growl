//
//  TestVersionComparisonBetweenStrings.h
//  Growl
//
//  Created by Peter Hosey on 2009-10-13.
//  Copyright 2009 Peter Hosey. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface TestVersionComparisonBetweenStrings : SenTestCase
{}

- (void) testSVNVersionNewerThanSVNVersion;
- (void) testSVNVersionEqualToSVNVersion;

- (void) testDevelopmentVersionNewerThanDevelopmentVersion;
- (void) testDevelopmentVersionEqualToDevelopmentVersion;

- (void) testAlphaNewerThanAlpha;
- (void) testAlphaEqualToAlpha;

- (void) testBetaNewerThanBeta;
- (void) testBetaEqualToBeta;

- (void) testReleaseNewerThanRelease;
- (void) testReleaseEqualToRelease;

#pragma mark -

- (void) testReleaseNewerThanBeta;
- (void) testReleaseNewerThanAlpha;
- (void) testReleaseNewerThanDevelopmentVersion;
- (void) testReleaseNewerThanSVNVersion;

- (void) testBetaNewerThanAlpha;
- (void) testBetaNewerThanDevelopmentVersion;
- (void) testBetaNewerThanSVNVersion;

- (void) testAlphaNewerThanDevelopmentVersion;
- (void) testAlphaNewerThanSVNVersion;

- (void) testDevelopmentVersionNewerThanSVNVersion;

@end
