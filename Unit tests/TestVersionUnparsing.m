//
//  TestVersionUnparsing.m
//  Growl
//
//  Created by Peter Hosey on 2009-10-15.
//  Copyright 2009 Peter Hosey. All rights reserved.
//

#import "TestVersionUnparsing.h"

#import "GrowlVersionUtilities.h"

@implementation TestVersionUnparsing

- (void) testUnparsingTwoComponentHgVersion {
	struct Version version = {
		1U,
		3U,
		0U,
		releaseType_svn,
		4000U
	};
	NSString *versionString = [NSMakeCollectable(createVersionDescription(version)) autorelease];

	STAssertNotNil(versionString, @"createVersionDescription((struct Version){ %hu, %hu, %hhu, %hhu, %hhu }) returned nil", version.major, version.minor, version.incremental, version.releaseType, version.development);

	NSString *correctVersionString = @"1.3hg4000";
	STAssertEqualObjects(versionString, correctVersionString, @"Version string for %@ was %@", correctVersionString, versionString);
}
- (void) testUnparsingTwoComponentDevelopmentVersion {
	struct Version version = {
		1U,
		3U,
		0U,
		releaseType_development,
		7U
	};
	NSString *versionString = [NSMakeCollectable(createVersionDescription(version)) autorelease];

	STAssertNotNil(versionString, @"createVersionDescription((struct Version){ %hu, %hu, %hhu, %hhu, %hhu }) returned nil", version.major, version.minor, version.incremental, version.releaseType, version.development);

	NSString *correctVersionString = @"1.3d7";
	STAssertEqualObjects(versionString, correctVersionString, @"Version string for %@ was %@", correctVersionString, versionString);
}
- (void) testUnparsingTwoComponentAlphaVersion {
	struct Version version = {
		1U,
		3U,
		0U,
		releaseType_alpha,
		7U
	};
	NSString *versionString = [NSMakeCollectable(createVersionDescription(version)) autorelease];

	STAssertNotNil(versionString, @"createVersionDescription((struct Version){ %hu, %hu, %hhu, %hhu, %hhu }) returned nil", version.major, version.minor, version.incremental, version.releaseType, version.development);

	NSString *correctVersionString = @"1.3a7";
	STAssertEqualObjects(versionString, correctVersionString, @"Version string for %@ was %@", correctVersionString, versionString);
}
- (void) testUnparsingTwoComponentBetaVersion {
	struct Version version = {
		1U,
		3U,
		0U,
		releaseType_beta,
		7U
	};
	NSString *versionString = [NSMakeCollectable(createVersionDescription(version)) autorelease];

	STAssertNotNil(versionString, @"createVersionDescription((struct Version){ %hu, %hu, %hhu, %hhu, %hhu }) returned nil", version.major, version.minor, version.incremental, version.releaseType, version.development);

	NSString *correctVersionString = @"1.3b7";
	STAssertEqualObjects(versionString, correctVersionString, @"Version string for %@ was %@", correctVersionString, versionString);
}
- (void) testUnparsingTwoComponentReleaseVersion {
	struct Version version = {
		1U,
		3U,
		0U,
		releaseType_release,
		0U
	};
	NSString *versionString = [NSMakeCollectable(createVersionDescription(version)) autorelease];

	STAssertNotNil(versionString, @"createVersionDescription((struct Version){ %hu, %hu, %hhu, %hhu, %hhu }) returned nil", version.major, version.minor, version.incremental, version.releaseType, version.development);

	NSString *correctVersionString = @"1.3";
	STAssertEqualObjects(versionString, correctVersionString, @"Version string for %@ was %@", correctVersionString, versionString);
}

- (void) testUnparsingThreeComponentHgVersion {
	struct Version version = {
		1U,
		3U,
		5U,
		releaseType_svn,
		4000U
	};
	NSString *versionString = [NSMakeCollectable(createVersionDescription(version)) autorelease];

	STAssertNotNil(versionString, @"createVersionDescription((struct Version){ %hu, %hu, %hhu, %hhu, %hhu }) returned nil", version.major, version.minor, version.incremental, version.releaseType, version.development);

	NSString *correctVersionString = @"1.3.5hg4000";
	STAssertEqualObjects(versionString, correctVersionString, @"Version string for %@ was %@", correctVersionString, versionString);
}
- (void) testUnparsingThreeComponentDevelopmentVersion {
	struct Version version = {
		1U,
		3U,
		5U,
		releaseType_development,
		7U
	};
	NSString *versionString = [NSMakeCollectable(createVersionDescription(version)) autorelease];

	STAssertNotNil(versionString, @"createVersionDescription((struct Version){ %hu, %hu, %hhu, %hhu, %hhu }) returned nil", version.major, version.minor, version.incremental, version.releaseType, version.development);

	NSString *correctVersionString = @"1.3.5d7";
	STAssertEqualObjects(versionString, correctVersionString, @"Version string for %@ was %@", correctVersionString, versionString);
}
- (void) testUnparsingThreeComponentAlphaVersion {
	struct Version version = {
		1U,
		3U,
		5U,
		releaseType_alpha,
		7U
	};
	NSString *versionString = [NSMakeCollectable(createVersionDescription(version)) autorelease];

	STAssertNotNil(versionString, @"createVersionDescription((struct Version){ %hu, %hu, %hhu, %hhu, %hhu }) returned nil", version.major, version.minor, version.incremental, version.releaseType, version.development);

	NSString *correctVersionString = @"1.3.5a7";
	STAssertEqualObjects(versionString, correctVersionString, @"Version string for %@ was %@", correctVersionString, versionString);
}
- (void) testUnparsingThreeComponentBetaVersion {
	struct Version version = {
		1U,
		3U,
		5U,
		releaseType_beta,
		7U
	};
	NSString *versionString = [NSMakeCollectable(createVersionDescription(version)) autorelease];

	STAssertNotNil(versionString, @"createVersionDescription((struct Version){ %hu, %hu, %hhu, %hhu, %hhu }) returned nil", version.major, version.minor, version.incremental, version.releaseType, version.development);

	NSString *correctVersionString = @"1.3.5b7";
	STAssertEqualObjects(versionString, correctVersionString, @"Version string for %@ was %@", correctVersionString, versionString);
}
- (void) testUnparsingThreeComponentReleaseVersion {
	struct Version version = {
		1U,
		3U,
		5U,
		releaseType_release,
		0U
	};
	NSString *versionString = [NSMakeCollectable(createVersionDescription(version)) autorelease];

	STAssertNotNil(versionString, @"createVersionDescription((struct Version){ %hu, %hu, %hhu, %hhu, %hhu }) returned nil", version.major, version.minor, version.incremental, version.releaseType, version.development);

	NSString *correctVersionString = @"1.3.5";
	STAssertEqualObjects(versionString, correctVersionString, @"Version string for %@ was %@", correctVersionString, versionString);
}

- (void) testUnparsingVersionWithBogusReleaseType {
	struct Version version = {
		1U,
		3U,
		5U,
		numberOfReleaseTypes,
		0U
	};
	NSString *versionString = [NSMakeCollectable(createVersionDescription(version)) autorelease];

	STAssertNil(versionString, @"createVersionDescription((struct Version){ %hu, %hu, %hhu, %hhu, %hhu }) returned %@", version.major, version.minor, version.incremental, version.releaseType, version.development, versionString);
}

@end
