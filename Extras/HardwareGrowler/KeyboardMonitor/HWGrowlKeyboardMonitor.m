//
//  HWGrowlKeyboardMonitor.m
//  HardwareGrowler
//
//  Created by Daniel Siemer on 5/29/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "HWGrowlKeyboardMonitor.h"

@interface HWGrowlKeyboardMonitor ()

@property (nonatomic, assign) id<HWGrowlPluginControllerProtocol> delegate;
@property (nonatomic, assign) IBOutlet NSView *prefsView;

@property (nonatomic, retain) NSString *notifyForLabel;
@property (nonatomic, retain) NSString *capsLockLabel;
@property (nonatomic, retain) NSString *fnKeyLabel;
@property (nonatomic, retain) NSString *shifyKeyLabel;

@property (nonatomic) BOOL capsFlag;
@property (nonatomic) BOOL fnFlag;
@property (nonatomic) BOOL shiftFlag;

@end

@implementation HWGrowlKeyboardMonitor

@synthesize delegate;
@synthesize prefsView;

@synthesize notifyForLabel;
@synthesize capsLockLabel;
@synthesize fnKeyLabel;
@synthesize shifyKeyLabel;

@synthesize capsFlag;
@synthesize fnFlag;
@synthesize shiftFlag;

-(id)init {
	if((self = [super init])){
        
		//Bleh, not happy with this really, but eh
		NSDictionary *enabledDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"hwgkeyboardkeysenabled"];
		if(!enabledDict){
			//Our default keys are caps, with fn and shift being disabled by default
			NSDictionary *defaultKeys = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"capslock",
												  [NSNumber numberWithBool:NO], @"fnkey",
												  [NSNumber numberWithBool:NO], @"shiftkey", nil];
			[[NSUserDefaults standardUserDefaults] setObject:defaultKeys 
																	forKey:@"hwgkeyboardkeysenabled"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
		
		self.notifyForLabel = NSLocalizedString(@"Notify For:", @"Label over list of checkboxes for notifying for certain keys");
		self.capsLockLabel = NSLocalizedString(@"Caps Lock", @"");
		self.fnKeyLabel = NSLocalizedString(@"FN Key", @"");
		self.shifyKeyLabel = NSLocalizedString(@"Shift Key", @"");
	}
	return self;
}

-(void)dealloc {
    [notifyForLabel release];
    notifyForLabel = nil;
    
    [capsLockLabel release];
    capsLockLabel = nil;

    [fnKeyLabel release];
    fnKeyLabel = nil;

    [shifyKeyLabel release];
    shifyKeyLabel = nil;

	[super dealloc];
}

-(void)postRegistrationInit {
	[self initFlags];
	[self listen];
}

-(void) listen
{
	
	NSEvent* (^myHandler)(NSEvent*) = ^(NSEvent* event)
	{
		//		NSLog(@"flags changed");
#define CHECK_FLAG(NAME)	if(self.NAME ## Flag != NAME)\
[self sendNotification:NAME forFlag:@"" #NAME];\
self.NAME ## Flag = NAME;
		
		NSUInteger flags = [NSEvent modifierFlags];
		BOOL caps = flags & NSAlphaShiftKeyMask ? YES : NO;
		BOOL fn = flags & NSFunctionKeyMask ? YES : NO;
		BOOL shift = flags & NSShiftKeyMask ? YES : NO;
		
		CHECK_FLAG(caps);
		CHECK_FLAG(fn);
		CHECK_FLAG(shift)
		
		return event;
	};
	
	[NSEvent addLocalMonitorForEventsMatchingMask:NSFlagsChangedMask 
													  handler:myHandler];
	[NSEvent addGlobalMonitorForEventsMatchingMask:NSFlagsChangedMask 
														handler: ^(NSEvent* event)
	 {
		 myHandler(event);
	 }];
	
}

- (void)sendNotification:(BOOL)newState forFlag:(NSString*)type
{
	NSString *name = nil;
	NSString *title = nil;
	NSString *identifier = nil;
	NSString *imageName = nil;
	
	NSString *enabledKey = nil;

	if([type isEqualToString:@"caps"]){
		enabledKey = @"capslock";
		name = newState ? @"CapsLockOn" : @"CapsLockOff";
		title = newState ? NSLocalizedString(@"Caps Lock On", @"") : NSLocalizedString(@"Caps Lock Off", @"");
		identifier = @"HWGrowlCaps";
		imageName = newState ? @"Capster-CapsLock-On" : @"Capster-CapsLock-Off";
	}else if ([type isEqualToString:@"fn"]){
		enabledKey = @"fnkey";
		name = newState ? @"FNPressed" : @"FNReleased";
		title = newState ? NSLocalizedString(@"FN Key Pressed", @"") : NSLocalizedString(@"FN Key Released", @"");
		identifier = @"HWGrowlFNKey";
		imageName = newState ? @"Capster-FnKey-On" : @"Capster-FnKey-Off";
	}else if ([type isEqualToString:@"shift"]){
		enabledKey = @"shiftkey";
		name = newState ? @"ShiftPressed" : @"ShiftReleased";
		title = newState ? NSLocalizedString(@"Shift Key Pressed", @"") : NSLocalizedString(@"Shift Key Released", @"");
		identifier = @"HWGrowlShiftKey";
		imageName = newState ? @"Capster-Shift-On" : @"Capster-Shift-Off";
	}else {
		return;
	}
	
	//Check that we are enabled in the keyboard monitor's preferences
	NSNumber *enabled = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKeyPath:[NSString stringWithFormat:@"hwgkeyboardkeysenabled.%@", enabledKey]];
	if(![enabled boolValue])
		return;
	
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:@"tif"];
    NSData *iconData = [NSData dataWithContentsOfFile:imagePath];
    [delegate notifyWithName:name
                       title:title
                 description:nil
                        icon:iconData
            identifierString:identifier
               contextString:nil
                      plugin:self];
}

-(void) initFlags
{
	NSUInteger flags = [NSEvent modifierFlags];
	capsFlag = flags & NSAlphaShiftKeyMask ? YES : NO;
	fnFlag = flags & NSFunctionKeyMask ? YES : NO;
	shiftFlag = flags & NSShiftKeyMask ? YES : NO;
}

#pragma mark HWGrowlPluginProtocol

-(void)setDelegate:(id<HWGrowlPluginControllerProtocol>)aDelegate{
	delegate = aDelegate;
}
-(id<HWGrowlPluginControllerProtocol>)delegate {
	return delegate;
}
-(NSString*)pluginDisplayName{
	return NSLocalizedString(@"Keyboard Monitor", @"");
}
-(NSImage*)preferenceIcon {
	static NSImage *_icon = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_icon = [[NSImage imageNamed:@"HWGPrefsCapster"] retain];
	});
	return _icon;
}
-(NSView*)preferencePane {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		[NSBundle loadNibNamed:@"KeyboardMonitorPrefs" owner:self];
	});
	return prefsView;
}
-(BOOL)enabledByDefault {
	return NO;
}

#pragma mark HWGrowlPluginNotifierProtocol

-(NSArray*)noteNames {
	return [NSArray arrayWithObjects:@"CapsLockOn", @"CapsLockOff", @"FNPressed", @"FNReleased", @"ShiftPressed", @"ShiftReleased", nil];
}
-(NSDictionary*)localizedNames {
	return [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Caps Lock On", @""), @"CapsLockOn",
			  NSLocalizedString(@"Caps Lock Off", @""), @"CapsLockOff",
			  NSLocalizedString(@"FN Key Pressed", @""), @"FNPressed",
			  NSLocalizedString(@"FN Key Released", @""), @"FNReleased",
			  NSLocalizedString(@"Shift Key Pressed", @""), @"ShiftPressed",
			  NSLocalizedString(@"Shift Key Released", @""), @"ShiftReleased", nil];
}
-(NSDictionary*)noteDescriptions {
	return [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Caps Lock On", @""), @"CapsLockOn",
			  NSLocalizedString(@"Caps Lock Off", @""), @"CapsLockOff",
			  NSLocalizedString(@"FN Key Pressed", @""), @"FNPressed",
			  NSLocalizedString(@"FN Key Released", @""), @"FNReleased",
			  NSLocalizedString(@"Shift Key Pressed", @""), @"ShiftPressed",
			  NSLocalizedString(@"Shift Key Released", @""), @"ShiftReleased", nil];
}
-(NSArray*)defaultNotifications {
	return [NSArray arrayWithObjects:@"CapsLockOn", @"CapsLockOff", @"FNPressed", @"FNReleased", @"ShiftPressed", @"ShiftReleased", nil];
}

@end
