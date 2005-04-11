#import "PrefpaneTester.h" 
@implementation PrefpaneTester 

- (void) awakeFromNib 
{ 
	NSRect aRect; 
	NSString *pathToPrefPaneBundle; 
	NSBundle *prefBundle; 
	Class prefPaneClass; 
	NSPreferencePane *prefPaneObject; 
	NSView *prefView; 
	
#warning	This path should of course be dynamic - but I am not sure how / too lazy --Diggory
	pathToPrefPaneBundle = [NSString stringWithString: 
		@"/Users/Diggory/Code/OpenSource/Growl/build/Growl.prefPane"]; 
	
	prefBundle = [NSBundle bundleWithPath: pathToPrefPaneBundle]; 
	
	prefPaneClass = [prefBundle principalClass]; 
	prefPaneObject = [[prefPaneClass alloc] initWithBundle: prefBundle]; 
	
	if([prefPaneObject loadMainView] ) 
	{ 
		[prefPaneObject willSelect]; 
		prefView = [prefPaneObject mainView]; 
		/* Add view to window */ 
		aRect = [prefView frame]; 
		
		// Okay, I know this is not so goood... 
		aRect.size.height = aRect.size.height + 22; 
		[theWindow setFrame: aRect display: YES]; 
		[[theWindow contentView] addSubview: prefView]; 
		[prefPaneObject didSelect]; 
	} 
	else 
	{ 
		/* loadMainView failed -- handle error */ 
		NSLog(@"PrefpaneTester -  Error in loadMainView:"); 
	} 
} 
@end 
