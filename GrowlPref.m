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
}

- (IBAction) startGrowlAtLogin:(id) sender {
	NSLog( @"start Growl At Login" );
}

@end
