//
//  GrowlPref.m
//  Growl
//
//  Created by Karl Adam on Wed Apr 21 2004.
//

#import "GrowlPref.h"


@implementation GrowlPref

- (void) mainViewDidLoad {
	//load prefs and set IBOutlets accordingly
}

- (IBAction) startGrowl:(id) sender {
	NSLog( @"start Growl" );	
	NSString *helperPath = [[[self bundle] resourcePath] stringByAppendingString:@"/GrowlHelperApp.app"];
	NSLog( @"tried to run %@", helperPath);
	
	if ( [_startGrowlButton state] == NSOnState ) {
		if ( ! [[NSWorkspace sharedWorkspace] launchApplication:helperPath] ) {
			[_startGrowlButton setState:NSOffState];
		}		
	} else {
		NSLog( @"stop GrowlHelperApp somehow" );
		//insert code here
	}
	
}

- (IBAction) startGrowlAtLogin:(id) sender {
	NSLog( @"start Growl At Login" );
	//insert code here
}

@end
