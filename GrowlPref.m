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
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	[defs addSuiteNamed:@"loginwindow"];
	NSString *helperPath = [[[self bundle] resourcePath] stringByAppendingString:@"/GrowlHelperApp.app"];
	
	NSDictionary *growlEntry = [NSDictionary dictionaryWithObjectsAndKeys:  helperPath, [NSString stringWithString:@"Path"],
																			[NSNumber numberWithBool:NO], [NSString stringWithString:@"Hide"],
																			nil];
	
	if ( [[defs objectForKey:@"AutoLaunchedApplicationDictionary"] containsObject:growlEntry] ) 
		[_startGrowlLoginButton setState:NSOnState];
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
	NSUserDefaults *defs = [[[NSUserDefaults alloc] init] autorelease];
	[defs addSuiteNamed:@"loginwindow"];
	NSMutableDictionary *loginWindowPrefs = [[[defs persistentDomainForName:@"loginwindow"] mutableCopy] autorelease];
	NSMutableArray *loginItems = [[[loginWindowPrefs objectForKey:@"AutoLaunchedApplicationDictionary"] mutableCopy] autorelease]; //it lies, its an array
	NSString *helperPath = [[[self bundle] resourcePath] stringByAppendingString:@"/GrowlHelperApp.app"];
	
	NSDictionary *growlEntry = [NSDictionary dictionaryWithObjectsAndKeys:  helperPath, [NSString stringWithString:@"Path"],
																			[NSNumber numberWithBool:NO], [NSString stringWithString:@"Hide"],
																			nil];
	
	if ( [_startGrowlLoginButton state] == NSOnState ) {
		NSLog( @"start Growl At Login" );
		
		[loginItems addObject:growlEntry];
	} else {
		NSLog( @"Don't start Growl At Login" );
		[loginItems removeObject:growlEntry];
	}

	[loginWindowPrefs setObject:[NSArray arrayWithArray:loginItems] 
						 forKey:@"AutoLaunchedApplicationDictionary"];
	[defs setPersistentDomain:[NSDictionary dictionaryWithDictionary:loginWindowPrefs] 
					  forName:@"loginwindow"];
	[defs synchronize];	
}

@end
