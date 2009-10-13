//
//  TestVersionUtilities.h
//  Growl
//
//  Created by Peter Hosey on 2009-10-13.
//  Copyright 2009 Peter Hosey. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface TestVersionUtilities : SenTestCase {
}

- (void) testParseNil;
- (void) testParseTwoComponentSVNVersion;
- (void) testParseTwoComponentDevelopmentVersion;
- (void) testParseTwoComponentAlphaVersion;
- (void) testParseTwoComponentBetaVersion;
- (void) testParseTwoComponentReleaseVersion;
- (void) testParseThreeComponentSVNVersion;
- (void) testParseThreeComponentDevelopmentVersion;
- (void) testParseThreeComponentAlphaVersion;
- (void) testParseThreeComponentBetaVersion;
- (void) testParseThreeComponentReleaseVersion;
- (void) testParseWord;
- (void) testParseWordFollowedByReleaseVersion;
- (void) testParseReleaseVersionFollowedByWord;

@end
