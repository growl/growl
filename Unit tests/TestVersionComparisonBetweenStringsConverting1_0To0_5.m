//
//  TestVersionComparisonBetweenStringsConverting1_0To0_5.m
//  Growl
//
//  Created by Peter Hosey on 2009-10-13.
//  Copyright 2009 Peter Hosey. All rights reserved.
//

#import "TestVersionComparisonBetweenStringsConverting1_0To0_5.h"

#import "GrowlVersionUtilities.h"

@implementation TestVersionComparisonBetweenStringsConverting1_0To0_5

- (void) testSVNVersionNewerThanSVNVersion {
	NSString *olderString = @"1.0svn1000", *newerString = @"1.0svn1009";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"Older (%@) must be less than newer (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Newer (%@) must be greater than older (%@)", newerString, olderString);

	olderString = @"1.0svn1000";
	newerString = @"2.5.1svn1009";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"Older (%@) must be less than newer (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Newer (%@) must be greater than older (%@)", newerString, olderString);
}
- (void) testSVNVersionEqualToSVNVersion {
	NSString *string = @"1.0svn1000";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(string, string), (CFComparisonResult)kCFCompareEqualTo, @"Version string (%@) must be equal to itself", string);

	//Version-equal, but not string-equal.
	NSString *stringA = @"01.00svn01000";
	NSString *stringB =   @"1.0svn1000";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(stringA, stringB), (CFComparisonResult)kCFCompareEqualTo, @"Version from string %@ must be equal to version from string %@", stringA, stringB);
}

- (void) testDevelopmentVersionNewerThanDevelopmentVersion {
	NSString *olderString = @"1.0d10", *newerString = @"1.0d19";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"Older (%@) must be less than newer (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Newer (%@) must be greater than older (%@)", newerString, olderString);

	//Note that in this case, the development field is *lower*. Earlier development versions of newer releases should always compare newer.
	olderString = @"1.0d10";
	newerString = @"2.5.1d5";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"Older (%@) must be less than newer (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Newer (%@) must be greater than older (%@)", newerString, olderString);
}
- (void) testDevelopmentVersionEqualToDevelopmentVersion {
	NSString *string = @"1.0d10";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(string, string), (CFComparisonResult)kCFCompareEqualTo, @"Version string (%@) must be equal to itself", string);

	//Version-equal, but not string-equal.
	NSString *stringA = @"01.00d010";
	NSString *stringB =   @"1.0d10";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(stringA, stringB), (CFComparisonResult)kCFCompareEqualTo, @"Version from string %@ must be equal to version from string %@", stringA, stringB);
}

- (void) testAlphaNewerThanAlpha {
	NSString *olderString = @"1.0a10", *newerString = @"1.0a19";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"Older (%@) must be less than newer (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Newer (%@) must be greater than older (%@)", newerString, olderString);

	//Note that in this case, the development field is *lower*. Earlier development versions of newer releases should always compare newer.
	olderString = @"1.0a10";
	newerString = @"2.5.1a5";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"Older (%@) must be less than newer (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Newer (%@) must be greater than older (%@)", newerString, olderString);
}
- (void) testAlphaEqualToAlpha {
	NSString *string = @"1.0a10";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(string, string), (CFComparisonResult)kCFCompareEqualTo, @"Version string (%@) must be equal to itself", string);

	//Version-equal, but not string-equal.
	NSString *stringA = @"01.00a010";
	NSString *stringB =   @"1.0a10";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(stringA, stringB), (CFComparisonResult)kCFCompareEqualTo, @"Version from string %@ must be equal to version from string %@", stringA, stringB);
}

- (void) testBetaNewerThanBeta {
	NSString *olderString = @"1.0b10", *newerString = @"1.0b19";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"Older (%@) must be less than newer (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Newer (%@) must be greater than older (%@)", newerString, olderString);

	//Note that in this case, the development field is *lower*. Earlier development versions of newer releases should always compare newer.
	olderString = @"1.0b10";
	newerString = @"2.5.1b5";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"Older (%@) must be less than newer (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Newer (%@) must be greater than older (%@)", newerString, olderString);
}
- (void) testBetaEqualToBeta {
	NSString *string = @"1.0b10";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(string, string), (CFComparisonResult)kCFCompareEqualTo, @"Version string (%@) must be equal to itself", string);

	//Version-equal, but not string-equal.
	NSString *stringA = @"01.00b010";
	NSString *stringB =   @"1.0b10";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(stringA, stringB), (CFComparisonResult)kCFCompareEqualTo, @"Version from string %@ must be equal to version from string %@", stringA, stringB);
}

- (void) testReleaseNewerThanRelease {
	NSString *olderString = @"1.0", *newerString = @"1.0.1";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"Older (%@) must be less than newer (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Newer (%@) must be greater than older (%@)", newerString, olderString);

	olderString = @"1.0";
	newerString = @"2.5.1";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"Older (%@) must be less than newer (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Newer (%@) must be greater than older (%@)", newerString, olderString);
}
- (void) testReleaseEqualToRelease {
	NSString *string = @"1.0";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(string, string), (CFComparisonResult)kCFCompareEqualTo, @"Version string (%@) must be equal to itself", string);

	//Version-equal, but not string-equal.
	//Only "1.0" gets translated to 0.5. Other ways of expressing 1.0 remain verbatim.
	NSString *stringA = @"01.00.0";
	NSString *stringB =  @"1.0";
	STAssertFalse(compareVersionStringsTranslating1_0To0_5(stringA, stringB) == kCFCompareEqualTo, @"Version from string %@ must be in equal to (translated 0.5) version from string %@", stringA, stringB);
}

#pragma mark -

- (void) testReleaseNewerThanBeta {
	NSString *olderString = @"2.0b5", *newerString = @"2.0";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"Beta (%@) must be less than release (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Release (%@) must be greater than beta (%@)", newerString, olderString);

	//Inverse: Make sure an earlier beta of a later release compares as newer.
	olderString = newerString;
	newerString = @"3.0b2";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"Beta (%@) must be less than release (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Release (%@) must be greater than beta (%@)", newerString, olderString);
}
- (void) testReleaseNewerThanAlpha {
	NSString *olderString = @"2.0a5", *newerString = @"2.0";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"Alpha (%@) must be less than release (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Release (%@) must be greater than alpha (%@)", newerString, olderString);

	//Inverse: Make sure an earlier alpha of a later release compares as newer.
	olderString = newerString;
	newerString = @"3.0a2";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"Beta (%@) must be less than release (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Release (%@) must be greater than beta (%@)", newerString, olderString);
}
- (void) testReleaseNewerThanDevelopmentVersion {
	NSString *olderString = @"2.0d5", *newerString = @"2.0";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"Development version (%@) must be less than release (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Release (%@) must be greater than development version (%@)", newerString, olderString);

	//Inverse: Make sure an earlier development version of a later release compares as newer.
	olderString = newerString;
	newerString = @"3.0d2";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"Development version (%@) must be less than release (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Release (%@) must be greater than development version (%@)", newerString, olderString);
}
- (void) testReleaseNewerThanSVNVersion {
	NSString *olderString = @"2.0svn500", *newerString = @"2.0";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"SVN version (%@) must be less than release (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Release (%@) must be greater than SVN version (%@)", newerString, olderString);

	//Inverse: Make sure an earlier SVN version of a later release compares as newer.
	//(This can happen in the case of reviving a maintenance branch for an emergency fix.)
	olderString = newerString;
	newerString = @"3.0svn200";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"SVN version (%@) must be less than release (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Release (%@) must be greater than SVN version (%@)", newerString, olderString);
}

- (void) testBetaNewerThanAlpha {
	NSString *olderString = @"1.0a5", *newerString = @"1.0b4";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"Alpha (%@) must be less than beta (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Beta (%@) must be greater than alpha (%@)", newerString, olderString);

	//Inverse: Make sure an earlier alpha of a later release compares as newer.
	olderString = newerString;
	newerString = @"2.0a2";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"Alpha (%@) must be less than beta (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Beta (%@) must be greater than alpha (%@)", newerString, olderString);
}
- (void) testBetaNewerThanDevelopmentVersion {
	NSString *olderString = @"1.0d5", *newerString = @"1.0b4";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"Development version (%@) must be less than beta (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Beta (%@) must be greater than development version (%@)", newerString, olderString);

	//Inverse: Make sure an earlier development version of a later release compares as newer.
	olderString = newerString;
	newerString = @"2.0d2";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"Development version (%@) must be less than beta (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Beta (%@) must be greater than development version (%@)", newerString, olderString);
}
- (void) testBetaNewerThanSVNVersion {
	NSString *olderString = @"1.0svn500", *newerString = @"1.0b4";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"SVN version (%@) must be less than beta (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Beta (%@) must be greater than SVN version (%@)", newerString, olderString);

	//Inverse: Make sure an earlier SVN version of a later release compares as newer.
	//(This can happen in the case of reviving a maintenance branch for an emergency fix.)
	olderString = newerString;
	newerString = @"2.0svn200";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"SVN version (%@) must be less than beta (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Beta (%@) must be greater than SVN version (%@)", newerString, olderString);
}

- (void) testAlphaNewerThanDevelopmentVersion {
	NSString *olderString = @"1.0d5", *newerString = @"1.0a4";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"Development version (%@) must be less than alpha (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Alpha (%@) must be greater than development version (%@)", newerString, olderString);

	//Inverse: Make sure an earlier development version of a later release compares as newer.
	olderString = newerString;
	newerString = @"2.0d2";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"Development version (%@) must be less than alpha (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Alpha (%@) must be greater than development version (%@)", newerString, olderString);
}
- (void) testAlphaNewerThanSVNVersion {
	NSString *olderString = @"1.0svn500", *newerString = @"1.0a4";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"SVN version (%@) must be less than alpha (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Alpha (%@) must be greater than SVN version (%@)", newerString, olderString);

	//Inverse: Make sure an earlier SVN version of a later release compares as newer.
	//(This can happen in the case of reviving a maintenance branch for an emergency fix.)
	olderString = newerString;
	newerString = @"2.0svn200";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"SVN version (%@) must be less than alpha (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Alpha (%@) must be greater than SVN version (%@)", newerString, olderString);
}

- (void) testDevelopmentVersionNewerThanSVNVersion {
	NSString *olderString = @"1.0svn500", *newerString = @"1.0d4";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"SVN version (%@) must be less than development version (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Development version (%@) must be greater than SVN version (%@)", newerString, olderString);

	//Inverse: Make sure an earlier SVN version of a later release compares as newer.
	//(This can happen in the case of reviving a maintenance branch for an emergency fix.)
	olderString = newerString;
	newerString = @"2.0svn200";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"SVN version (%@) must be less than Development version (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Release (%@) must be greater than SVN version (%@)", newerString, olderString);
}

#pragma mark Testing 1.0-to-0.5 conversion

- (void) test1_0EqualTo0_5 {
	NSString *stringA = @"1.0", *stringB = @"0.5";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(stringA, stringB), (CFComparisonResult)kCFCompareEqualTo, @"Untranslated version number (%@) must be equal to translated 0.5 (%@)", stringA, stringB);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(stringB, stringA), (CFComparisonResult)kCFCompareEqualTo, @"Translated 0.5 (%@) must be equal to untranslated version number (%@)", stringB, stringA);
}
- (void) test1_0NewerThan0_6 {
	NSString *olderString = @"1.0", *newerString = @"0.6";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"Translated 0.5 (%@) must be greater than untranslated version number (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Untranslated version number (%@) must be less than translated 0.5 (%@)", newerString, olderString);
}
- (void) test1_0OlderThan0_4 {
	NSString *olderString = @"0.4", *newerString = @"1.0";
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(olderString, newerString), (CFComparisonResult)kCFCompareLessThan, @"Untranslated version number (%@) must be less than translated 0.5 (%@)", olderString, newerString);
	STAssertEquals(compareVersionStringsTranslating1_0To0_5(newerString, olderString), (CFComparisonResult)kCFCompareGreaterThan, @"Translated 0.5 (%@) must be greater than untranslated version number (%@)", newerString, olderString);
}

@end
