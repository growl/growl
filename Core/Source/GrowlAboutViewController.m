//
//  GrowlAboutViewController.m
//  Growl
//
//  Created by Daniel Siemer on 11/9/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlAboutViewController.h"
#import "GrowlVersionUtilities.h"

@implementation GrowlAboutViewController

@synthesize aboutVersionString;
@synthesize aboutBoxTextView;

@synthesize bugSubmissionLabel;
@synthesize growlWebsiteLabel;

- (void)dealloc {
   [bugSubmissionLabel release];
   [growlWebsiteLabel release];
   [super dealloc];
}

- (void) awakeFromNib {
   self.bugSubmissionLabel = NSLocalizedString(@"Growl Bug Submission", @"Button to open http://growl.info/reportabug.php");
   self.growlWebsiteLabel = NSLocalizedString(@"Growl Web Site", @"button to open http://growl.info");
   [self setupAboutTab];
   
}

+ (NSString*)nibName {
   return @"About";
}

- (void) setupAboutTab {
	NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	if (versionString) {
		NSString *versionStringWithHgVersion = nil;
		struct Version version;
		if (parseVersionString(versionString, &version) && (version.releaseType == releaseType_development)) {
			const char *hgRevisionUTF8 = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"GrowlHgRevision"] UTF8String];
			if (hgRevisionUTF8) {
				version.development = (u_int32_t)strtoul(hgRevisionUTF8, /*next*/ NULL, 10);
            
				versionStringWithHgVersion = [NSMakeCollectable(createVersionDescription(version)) autorelease];
			}
		}
		if (versionStringWithHgVersion)
			versionString = versionStringWithHgVersion;
	}
   
	[aboutVersionString setStringValue:[NSString stringWithFormat:@"%@ %@", 
                                       [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"], 
                                       versionString]];
	[aboutBoxTextView readRTFDFromFile:[[NSBundle mainBundle] pathForResource:@"About" ofType:@"rtf"]];
}

- (IBAction) openGrowlWebSite:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://growl.info"]];
}

- (IBAction) openGrowlBugSubmissionPage:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://growl.info/reportabug.php"]];
}

@end
