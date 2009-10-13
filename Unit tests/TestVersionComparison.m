//
//  TestVersionComparison.m
//  Growl
//
//  Created by Peter Hosey on 2009-10-13.
//  Copyright 2009 Peter Hosey. All rights reserved.
//

#import "TestVersionComparison.h"

#import "GrowlVersionUtilities.h"

@implementation TestVersionComparison

- (void) testSVNVersionNewerThanSVNVersion {
	struct Version older, newer;
	NSString *olderString = @"1.0svn1000", *newerString = @"1.0svn1009";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"Older (%@) must be less than newer (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Newer (%@) must be greater than older (%@)", newerString, olderString);

	olderString = @"1.0svn1000";
	newerString = @"2.5.1svn1009";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"Older (%@) must be less than newer (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Newer (%@) must be greater than older (%@)", newerString, olderString);
}
- (void) testSVNVersionEqualToSVNVersion {
	struct Version versionA, versionB;
	NSString *string = @"1.0svn1000";
	STAssertTrue(parseVersionString(string, &versionA), @"Could not parse version string (prerequisite for equality test)");
	STAssertTrue(parseVersionString(string, &versionB), @"Could not parse version string (prerequisite for equality test)");

	STAssertEquals(compareVersions(versionA, versionB), (CFComparisonResult)kCFCompareEqualTo, @"Version string (%@) must be equal to itself", string);

	//Version-equal, but not string-equal.
	NSString *stringA = @"01.00svn01000";
	NSString *stringB =   @"1.0svn1000";
	STAssertTrue(parseVersionString(stringA, &versionA), @"Could not parse first version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(stringB, &versionB), @"Could not parse second version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(versionA, versionB), (CFComparisonResult)kCFCompareEqualTo, @"Version from string %@ must be equal to version from string %@", stringA, stringB);
}

- (void) testDevelopmentVersionNewerThanDevelopmentVersion {
	struct Version older, newer;
	NSString *olderString = @"1.0d10", *newerString = @"1.0d19";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"Older (%@) must be less than newer (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Newer (%@) must be greater than older (%@)", newerString, olderString);

	//Note that in this case, the development field is *lower*. Earlier development versions of newer releases should always compare newer.
	olderString = @"1.0d10";
	newerString = @"2.5.1d5";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"Older (%@) must be less than newer (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Newer (%@) must be greater than older (%@)", newerString, olderString);
}
- (void) testDevelopmentVersionEqualToDevelopmentVersion {
	struct Version versionA, versionB;
	NSString *string = @"1.0d10";
	STAssertTrue(parseVersionString(string, &versionA), @"Could not parse version string (prerequisite for equality test)");
	STAssertTrue(parseVersionString(string, &versionB), @"Could not parse version string (prerequisite for equality test)");

	STAssertEquals(compareVersions(versionA, versionB), (CFComparisonResult)kCFCompareEqualTo, @"Version string (%@) must be equal to itself", string);

	//Version-equal, but not string-equal.
	NSString *stringA = @"01.00d010";
	NSString *stringB =   @"1.0d10";
	STAssertTrue(parseVersionString(stringA, &versionA), @"Could not parse first version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(stringB, &versionB), @"Could not parse second version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(versionA, versionB), (CFComparisonResult)kCFCompareEqualTo, @"Version from string %@ must be equal to version from string %@", stringA, stringB);
}

- (void) testAlphaNewerThanAlpha {
	struct Version older, newer;
	NSString *olderString = @"1.0a10", *newerString = @"1.0a19";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"Older (%@) must be less than newer (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Newer (%@) must be greater than older (%@)", newerString, olderString);

	//Note that in this case, the development field is *lower*. Earlier development versions of newer releases should always compare newer.
	olderString = @"1.0a10";
	newerString = @"2.5.1a5";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"Older (%@) must be less than newer (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Newer (%@) must be greater than older (%@)", newerString, olderString);
}
- (void) testAlphaEqualToAlpha {
	struct Version versionA, versionB;
	NSString *string = @"1.0a10";
	STAssertTrue(parseVersionString(string, &versionA), @"Could not parse version string (prerequisite for equality test)");
	STAssertTrue(parseVersionString(string, &versionB), @"Could not parse version string (prerequisite for equality test)");

	STAssertEquals(compareVersions(versionA, versionB), (CFComparisonResult)kCFCompareEqualTo, @"Version string (%@) must be equal to itself", string);

	//Version-equal, but not string-equal.
	NSString *stringA = @"01.00a010";
	NSString *stringB =   @"1.0a10";
	STAssertTrue(parseVersionString(stringA, &versionA), @"Could not parse first version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(stringB, &versionB), @"Could not parse second version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(versionA, versionB), (CFComparisonResult)kCFCompareEqualTo, @"Version from string %@ must be equal to version from string %@", stringA, stringB);
}

- (void) testBetaNewerThanBeta {
	struct Version older, newer;
	NSString *olderString = @"1.0b10", *newerString = @"1.0b19";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"Older (%@) must be less than newer (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Newer (%@) must be greater than older (%@)", newerString, olderString);

	//Note that in this case, the development field is *lower*. Earlier development versions of newer releases should always compare newer.
	olderString = @"1.0b10";
	newerString = @"2.5.1b5";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"Older (%@) must be less than newer (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Newer (%@) must be greater than older (%@)", newerString, olderString);
}
- (void) testBetaEqualToBeta {
	struct Version versionA, versionB;
	NSString *string = @"1.0b10";
	STAssertTrue(parseVersionString(string, &versionA), @"Could not parse version string (prerequisite for equality test)");
	STAssertTrue(parseVersionString(string, &versionB), @"Could not parse version string (prerequisite for equality test)");

	STAssertEquals(compareVersions(versionA, versionB), (CFComparisonResult)kCFCompareEqualTo, @"Version string (%@) must be equal to itself", string);

	//Version-equal, but not string-equal.
	NSString *stringA = @"01.00b010";
	NSString *stringB =   @"1.0b10";
	STAssertTrue(parseVersionString(stringA, &versionA), @"Could not parse first version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(stringB, &versionB), @"Could not parse second version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(versionA, versionB), (CFComparisonResult)kCFCompareEqualTo, @"Version from string %@ must be equal to version from string %@", stringA, stringB);
}

- (void) testReleaseNewerThanRelease {
	struct Version older, newer;
	NSString *olderString = @"1.0", *newerString = @"1.0.1";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"Older (%@) must be less than newer (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Newer (%@) must be greater than older (%@)", newerString, olderString);

	olderString = @"1.0";
	newerString = @"2.5.1";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"Older (%@) must be less than newer (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Newer (%@) must be greater than older (%@)", newerString, olderString);
}
- (void) testReleaseEqualToRelease {
	struct Version versionA, versionB;
	NSString *string = @"1.0";
	STAssertTrue(parseVersionString(string, &versionA), @"Could not parse version string (prerequisite for equality test)");
	STAssertTrue(parseVersionString(string, &versionB), @"Could not parse version string (prerequisite for equality test)");

	STAssertEquals(compareVersions(versionA, versionB), (CFComparisonResult)kCFCompareEqualTo, @"Version string (%@) must be equal to itself", string);

	//Version-equal, but not string-equal.
	NSString *stringA = @"01.00.0";
	NSString *stringB =  @"1.0";
	STAssertTrue(parseVersionString(stringA, &versionA), @"Could not parse first version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(stringB, &versionB), @"Could not parse second version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(versionA, versionB), (CFComparisonResult)kCFCompareEqualTo, @"Version from string %@ must be equal to version from string %@", stringA, stringB);
}

#pragma mark -

- (void) testReleaseNewerThanBeta {
	struct Version older, newer;
	NSString *olderString = @"1.0b5", *newerString = @"1.0";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"Beta (%@) must be less than release (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Release (%@) must be greater than beta (%@)", newerString, olderString);

	//Inverse: Make sure an earlier beta of a later release compares as newer.
	olderString = newerString;
	newerString = @"2.0b2";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"Beta (%@) must be less than release (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Release (%@) must be greater than beta (%@)", newerString, olderString);
}
- (void) testReleaseNewerThanAlpha {
	struct Version older, newer;
	NSString *olderString = @"1.0a5", *newerString = @"1.0";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"Alpha (%@) must be less than release (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Release (%@) must be greater than alpha (%@)", newerString, olderString);

	//Inverse: Make sure an earlier alpha of a later release compares as newer.
	olderString = newerString;
	newerString = @"2.0a2";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"Beta (%@) must be less than release (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Release (%@) must be greater than beta (%@)", newerString, olderString);
}
- (void) testReleaseNewerThanDevelopmentVersion {
	struct Version older, newer;
	NSString *olderString = @"1.0d5", *newerString = @"1.0";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"Development version (%@) must be less than release (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Release (%@) must be greater than development version (%@)", newerString, olderString);

	//Inverse: Make sure an earlier development version of a later release compares as newer.
	olderString = newerString;
	newerString = @"2.0d2";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"Development version (%@) must be less than release (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Release (%@) must be greater than development version (%@)", newerString, olderString);
}
- (void) testReleaseNewerThanSVNVersion {
	struct Version older, newer;
	NSString *olderString = @"1.0svn500", *newerString = @"1.0";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"SVN version (%@) must be less than release (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Release (%@) must be greater than SVN version (%@)", newerString, olderString);

	//Inverse: Make sure an earlier SVN version of a later release compares as newer.
	//(This can happen in the case of reviving a maintenance branch for an emergency fix.)
	olderString = newerString;
	newerString = @"2.0svn200";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"SVN version (%@) must be less than release (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Release (%@) must be greater than SVN version (%@)", newerString, olderString);
}

- (void) testBetaNewerThanAlpha {
	struct Version older, newer;
	NSString *olderString = @"1.0a5", *newerString = @"1.0b4";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"Alpha (%@) must be less than beta (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Beta (%@) must be greater than alpha (%@)", newerString, olderString);

	//Inverse: Make sure an earlier alpha of a later release compares as newer.
	olderString = newerString;
	newerString = @"2.0a2";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"Alpha (%@) must be less than beta (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Beta (%@) must be greater than alpha (%@)", newerString, olderString);
}
- (void) testBetaNewerThanDevelopmentVersion {
	struct Version older, newer;
	NSString *olderString = @"1.0d5", *newerString = @"1.0b4";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"Development version (%@) must be less than beta (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Beta (%@) must be greater than development version (%@)", newerString, olderString);

	//Inverse: Make sure an earlier development version of a later release compares as newer.
	olderString = newerString;
	newerString = @"2.0d2";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"Development version (%@) must be less than beta (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Beta (%@) must be greater than development version (%@)", newerString, olderString);
}
- (void) testBetaNewerThanSVNVersion {
	struct Version older, newer;
	NSString *olderString = @"1.0svn500", *newerString = @"1.0b4";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"SVN version (%@) must be less than beta (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Beta (%@) must be greater than SVN version (%@)", newerString, olderString);

	//Inverse: Make sure an earlier SVN version of a later release compares as newer.
	//(This can happen in the case of reviving a maintenance branch for an emergency fix.)
	olderString = newerString;
	newerString = @"2.0svn200";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"SVN version (%@) must be less than beta (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Beta (%@) must be greater than SVN version (%@)", newerString, olderString);
}

- (void) testAlphaNewerThanDevelopmentVersion {
	struct Version older, newer;
	NSString *olderString = @"1.0d5", *newerString = @"1.0a4";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"Development version (%@) must be less than alpha (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Alpha (%@) must be greater than development version (%@)", newerString, olderString);

	//Inverse: Make sure an earlier development version of a later release compares as newer.
	olderString = newerString;
	newerString = @"2.0d2";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"Development version (%@) must be less than alpha (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Alpha (%@) must be greater than development version (%@)", newerString, olderString);
}
- (void) testAlphaNewerThanSVNVersion {
	struct Version older, newer;
	NSString *olderString = @"1.0svn500", *newerString = @"1.0a4";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"SVN version (%@) must be less than alpha (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Alpha (%@) must be greater than SVN version (%@)", newerString, olderString);

	//Inverse: Make sure an earlier SVN version of a later release compares as newer.
	//(This can happen in the case of reviving a maintenance branch for an emergency fix.)
	olderString = newerString;
	newerString = @"2.0svn200";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"SVN version (%@) must be less than alpha (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Alpha (%@) must be greater than SVN version (%@)", newerString, olderString);
}

- (void) testDevelopmentVersionNewerThanSVNVersion {
	struct Version older, newer;
	NSString *olderString = @"1.0svn500", *newerString = @"1.0d4";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"SVN version (%@) must be less than development version (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Development version (%@) must be greater than SVN version (%@)", newerString, olderString);

	//Inverse: Make sure an earlier SVN version of a later release compares as newer.
	//(This can happen in the case of reviving a maintenance branch for an emergency fix.)
	olderString = newerString;
	newerString = @"2.0svn200";
	STAssertTrue(parseVersionString(olderString, &older), @"Could not parse older version string (prerequisite for comparison test)");
	STAssertTrue(parseVersionString(newerString, &newer), @"Could not parse newer version string (prerequisite for comparison test)");

	STAssertEquals(compareVersions(older, newer), (CFComparisonResult)kCFCompareLessThan, @"SVN version (%@) must be less than Development version (%@)", olderString, newerString);
	STAssertEquals(compareVersions(newer, older), (CFComparisonResult)kCFCompareGreaterThan, @"Release (%@) must be greater than SVN version (%@)", newerString, olderString);
}

@end
