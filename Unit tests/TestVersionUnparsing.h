//
//  TestVersionUnparsing.h
//  Growl
//
//  Created by Peter Hosey on 2009-10-15.
//  Copyright 2009 Peter Hosey. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface TestVersionUnparsing : SenTestCase {

}

- (void) testUnparsingTwoComponentHgVersion;
- (void) testUnparsingTwoComponentDevelopmentVersion;
- (void) testUnparsingTwoComponentAlphaVersion;
- (void) testUnparsingTwoComponentBetaVersion;
- (void) testUnparsingTwoComponentReleaseVersion;

- (void) testUnparsingThreeComponentHgVersion;
- (void) testUnparsingThreeComponentDevelopmentVersion;
- (void) testUnparsingThreeComponentAlphaVersion;
- (void) testUnparsingThreeComponentBetaVersion;
- (void) testUnparsingThreeComponentReleaseVersion;

- (void) testUnparsingVersionWithBogusReleaseType;

@end
