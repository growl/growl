//
//  CapsterAppDelegate.m
//  Capster
//
//  Created by Vasileios Georgitzikis on 3/3/11.
//  Copyright 2011 Tzikis. All rights reserved.
//
// This source code is release under the BSD License.

#import "CapsterAppDelegate.h"

//This is the callback function that gets called when the
//caps lock is pressed. All we need to care about is the
//refcon pointer, which is the buffer we use to send
//data to the callback function
CGEventRef myCallback (
					   CGEventTapProxy proxy,
					   CGEventType type,
					   CGEventRef event,
					   void *refcon
					   )
{
	//change the buffer to a char buffer
	char *buffer = (char*) refcon;
	//get the state, and save it for comparison
	NSUInteger** tempInt;
	tempInt = (NSUInteger**) buffer;
 	NSUInteger *currentState = *tempInt;
	NSUInteger oldState = (NSUInteger) *currentState;	

	//get the flags
	CGEventFlags flags = CGEventGetFlags (event);
	//is caps lock on or off?
	if ((flags & kCGEventFlagMaskAlphaShift) != 0)
		*currentState = 1;
	else
		*currentState = 0;
	
	//increase the offset, since we've read the first NSUInteger
	NSUInteger offset = sizeof(NSUInteger);
	
	//copy the object we'll be using
	id* tmpID2 = (id*) (buffer+offset);
	id tmpID = *tmpID2;
	offset += (NSUInteger) sizeof(id*);
	

	//if it's our first event, then do nothing.
	//it's the fake event we're sending to ourselves
	if(oldState == 4)
	{
		[tmpID performSelectorOnMainThread:@selector(fetchedCapsState) 
								withObject:nil 
							 waitUntilDone:YES];
		return event;
	}
	
	//if the caps lock state has changed, do some work
	if(oldState != *currentState)
		[tmpID capsLockChanged: (NSUInteger) *currentState];
	
//		printf("flag changed\n");
	return event;
}

@implementation Growl_Caps_NotifierAppDelegate

@synthesize preferencePanel;

//this function is called on startup
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	//register the user's preferences
	[self registerDefaults];
		

	//this makes a new thread, and makes it block listening for a
	//change of state in the caps lock flag
	[self listenForCapsInNewThread];

	statusbar = malloc(sizeof(NSInteger*));	
	*statusbar = [preferences integerForKey:@"statusMenu"];
	
	//select the apropriate radio button, based on which icon status is active
	[statusbarMatrix selectCellAtRow:*statusbar column:0];
	
	//needed, because statusbar is supposed to always store the current value
	//and we check wether it's changed when updating the status bar.
	//since, at the beginning, we have 0, we save it. in the next line, we will
	//get the correct value from the statusbarMatrix, which we've just saved
	*statusbar = 0;

	myGrowlController = [[GrowlController alloc] init];
	myStatusbarController = [[StatusbarController alloc] initWithStatusbar:statusbar 
														   statusbarMatrix:statusbarMatrix 
															   preferences:preferences
																	 state:currentState
																statusMenu:statusMenu];

	//make everything in the preferences white. necessary for the text to be viewable
	[self makeEverythingWhite];
	
	//if the user want the menu to be shown, then do so
	[myStatusbarController setStatusMenuTo:statusbarMatrix];
	
	//send a notification to the user to let him know we're on
	[myGrowlController sendStartupGrowlNotification];
}

//This function takes care of listening creating the new thread and setting the listener
-(void) listenForCapsInNewThread
{
	//run the listener to the new thread
	[NSThread detachNewThreadSelector:@selector(listen)
							 toTarget:self
						   withObject:nil];
	
	//because of the way our code behaves, the first event will not be shown.
	//therefore, we wait for 2 seconds to make sure we have started listening,
	//and then we send a fake event, which will be captured and not shown
	sleep(2);
	CGEventRef event1 = CGEventCreateKeyboardEvent (NULL,(CGKeyCode)56,true);
	CGEventRef event2 = CGEventCreateKeyboardEvent (NULL,(CGKeyCode)56,false);
	CGEventPost(kCGAnnotatedSessionEventTap, event1);
	CGEventPost(kCGAnnotatedSessionEventTap, event2);

}

//starts the listener and blocks the current thread, waiting for events
-(void) listen
{
	//the new thread needs to have its own autorelease pool
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		
	//We hold the length of each image because we need to send it to the callback, in order
	//to know its size, and reconstruct the NSData from the buffer
//	NSUInteger len_on = [on length];
//	NSUInteger len_off = [off length];
//	NSLog(@"len_on: %i len_off %i", len_on, len_off);
	
	//calculate the size of the buffer
	int size = (int) sizeof(NSUInteger*) + (int) sizeof(id) + (int) sizeof(NSUInteger*);
	//allocate the buffer
	char *byteData = (char*)malloc(sizeof(char) * size);
	
	//offset is the offset, tmpChar is a temporary variable
	NSUInteger offset = 0;
	NSUInteger** tempInt;
	
	//The state is 0 if Caps Lock is not pressed, and 1 when pressed. However,
	//we initialize it as 4 because we don't know the state on startup. After
	//the first event, we'll know. Then we copy the state to the buffer
	currentState = malloc(sizeof(NSUInteger*));
	*currentState = 4;
	tempInt = (NSUInteger**) byteData;
	*tempInt = currentState;

//	byteData[offset] = currentState;
	offset+=(NSUInteger) sizeof(NSUInteger*);
//	printf("offset: %d\n", offset);
		
	//then, we save a pointer to ourselves, since we'll need to call
	//one of our methods to show or hide the preference panel
	id* tmpID2 = (id*) (byteData+offset);
	*tmpID2 = (id) self;
	offset+=(NSUInteger) sizeof(id*);
		
//	NSLog(@"len_on: %i len_off %i", *tempInt1, *tempInt2);
//	NSLog(@"size of my object: %lu", sizeof(self));
	
	//this produces invalid warnings for the analyzer, so we silence them
#ifndef __clang_analyzer__
	//We create the Event Tap
	CFMachPortRef bla = CGEventTapCreate (
										  kCGAnnotatedSessionEventTap,
										  kCGHeadInsertEventTap,
										  kCGEventTapOptionListenOnly,
										  CGEventMaskBit(kCGEventFlagsChanged),
										  myCallback,
										  (void*) byteData
										  );
	//make sure the event variable isn't NULL
	assert(bla != NULL);
	
	//Create the loop source
	CFRunLoopSourceRef bla2 = CFMachPortCreateRunLoopSource(NULL, bla, 0);
	//again, make sure it's not NULL
	assert(bla2 != NULL);
	//add the loop source to the current loop
	CFRunLoopAddSource(CFRunLoopGetCurrent(), bla2, kCFRunLoopDefaultMode);
	// Run the loop.
//	printf("Listening using Core Foundation:\n");
	CFRunLoopRun();
#endif
	//if we reach this, something has gone wrong
	[pool release];
	fprintf(stderr, "CFRunLoopRun returned\n");
//    return EXIT_FAILURE;
}

//initializes the user preferences, and loads the defaults from the defaults file
-(void) registerDefaults
{
	//Save a reference to the user's preferences
	preferences = [[NSUserDefaults standardUserDefaults] retain];
	//get the default preferences file
	NSString *file = [[NSBundle mainBundle]
					  pathForResource:@"defaults" ofType:@"plist"];
	//make a dictionary of that file
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:file];
	//register the defaults
	[preferences registerDefaults:dict];
}

//makes everything in the preference panel white
-(void) makeEverythingWhite
{
	//get all the cells in the matrix
	NSArray * cells = [statusbarMatrix cells];
	
	//for each cell
	for(int i = 0 ; i < [cells count] ; i ++)
	{
		//create a reference to the cell 
		NSButtonCell* cell = [cells objectAtIndex:i];
		[self setButtonTitleFor:cell
					   toString:[cell title]
					  withColor:[NSColor whiteColor]];
	}

}

//Set the button's title using nsattributedtitle, which lets us change the color of a button or cell's text
- (void)setButtonTitleFor:(id)button toString:(NSString*)title withColor:(NSColor*)color 
{
	if([button respondsToSelector:@selector(setAttributedTitle:)] == NO) return;
			
	NSMutableDictionary *attrsDictionary = [NSMutableDictionary dictionaryWithDictionary:
											   [[button attributedTitle] attributesAtIndex:0 effectiveRange:NULL]];
	[attrsDictionary setObject:color forKey:NSForegroundColorAttributeName];
	
	NSAttributedString* attrString = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
	NSLog(@"%@", attrsDictionary);
	
	[button setAttributedTitle: attrString];
	[attrString release];		
}

- (void) fetchedCapsState
{
//	if( *currentState == 0)
//	{
//		NSLog(@"caps is off");
//	}
//	else
//	{
//		NSLog(@"caps is on");		
//	}
	
	[myStatusbarController setIconState:(BOOL) *currentState];
}

- (void) capsLockChanged: (NSUInteger) newState
{
	[myGrowlController sendCapsLockNotification:newState];
	[myStatusbarController setIconState:newState];
}

//set the status menu to the value of the checkbox sender
-(IBAction) setStatusMenuTo:(id) sender
{
	[myStatusbarController setStatusMenuTo:sender];
}

- (BOOL) applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
	#pragma unused(theApplication, flag)
    [self showPreferences:nil];
    return YES;
}

-(IBAction) showPreferences:(id) sender
{
	#pragma unused(sender)
	[preferencePanel setIsVisible:YES];
	[preferencePanel center];
	[preferencePanel makeKeyAndOrderFront:nil];
}

@end
