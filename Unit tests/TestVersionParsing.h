//
//  TestVersionParsing.h
//  Growl
//
//  Created by Peter Hosey on 2009-10-13.
//  Copyright 2009 Peter Hosey. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface TestVersionParsing : SenTestCase {
}

- (void) testParseNil;
- (void) testParseTwoComponentSVNVersion;
- (void) testParseTwoComponentHgVersion;
- (void) testParseTwoComponentDevelopmentVersion;
- (void) testParseTwoComponentAlphaVersion;
- (void) testParseTwoComponentBetaVersion;
- (void) testParseTwoComponentReleaseVersion;
- (void) testParseThreeComponentSVNVersion;
- (void) testParseThreeComponentHgVersion;
- (void) testParseThreeComponentDevelopmentVersion;
- (void) testParseThreeComponentAlphaVersion;
- (void) testParseThreeComponentBetaVersion;
- (void) testParseThreeComponentReleaseVersion;
- (void) testParseWord;
- (void) testParseWordFollowedByReleaseVersion;
- (void) testParseReleaseVersionFollowedByWord;

- (void) testParseVersionStringPrefixedBySpaces;
- (void) testParseVersionStringPrefixedByLineFeed;
- (void) testParseVersionStringSuffixedBySpaces;
- (void) testParseVersionStringSuffixedByLineFeed;

- (void) testParseTwoComponentSVNVersionWithSpacesAroundReleaseType;
- (void) testParseTwoComponentSVNVersionWithSmallLetterRBeforeRevisionNumber;
- (void) testParseTwoComponentSVNVersionWithSpacesAroundReleaseTypeAndSmallLetterRBeforeRevisionNumber;

- (void) testParseSVNVersionWithNoRevisionNumber;
- (void) testParseDevelopmentVersionWithNoDevelopmentVersionNumber;
- (void) testParseAlphaVersionWithNoDevelopmentVersionNumber;
- (void) testParseBetaVersionWithNoDevelopmentVersionNumber;

@end
