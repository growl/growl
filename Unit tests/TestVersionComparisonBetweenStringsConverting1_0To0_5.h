//
//  TestVersionComparisonBetweenStringsConverting1_0To0_5.h
//  Growl
//
//  Created by Peter Hosey on 2009-10-13.
//  Copyright 2009 Peter Hosey. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface TestVersionComparisonBetweenStringsConverting1_0To0_5 : SenTestCase
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

#pragma mark Testing 1.0-to-0.5 conversion

- (void) test1_0EqualTo0_5;
- (void) test1_0NewerThan0_6;
- (void) test1_0OlderThan0_4;

@end
