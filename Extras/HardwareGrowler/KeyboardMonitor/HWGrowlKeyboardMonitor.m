//
//  HWGrowlKeyboardMonitor.m
//  HardwareGrowler
//
//  Created by Daniel Siemer on 5/29/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "HWGrowlKeyboardMonitor.h"

typedef enum {
	capslockKey = 0,
	numlockKey,
	fnKeyKey,
	shiftKey
} HWGMonitoredKeyType;

@interface HWGrowlKeyboardMonitor ()

@property (nonatomic, assign) id<HWGrowlPluginControllerProtocol> delegate;
@property (nonatomic) BOOL capsFlag;
@property (nonatomic) BOOL numlockFlag;
@property (nonatomic) BOOL fnFlag;
@property (nonatomic) BOOL shiftFlag;

@end

@implementation HWGrowlKeyboardMonitor

@synthesize delegate;

@synthesize capsFlag;
@synthesize numlockFlag;
@synthesize fnFlag;
@synthesize shiftFlag;

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
		BOOL numlock = flags & NSNumericPadKeyMask ? YES : NO;
		BOOL shift = flags & NSShiftKeyMask ? YES : NO;
		
		CHECK_FLAG(caps);
		CHECK_FLAG(fn);
		CHECK_FLAG(numlock);
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
	NSData *iconData = nil;
	
	if([type isEqualToString:@"caps"]){
		name = newState ? @"CapsLockOn" : @"CapsLockOff";
		title = newState ? NSLocalizedString(@"Caps Lock On", @"") : NSLocalizedString(@"Caps Lock Off", @"");
		identifier = @"HWGrowlCaps";
		iconData = newState ? [[NSImage imageNamed:@"caps_on"] TIFFRepresentation] : [[NSImage imageNamed:@"caps_off"] TIFFRepresentation];
	}else if ([type isEqualToString:@"numlock"]){
		name = newState ? @"NumLockOn" : @"NumLockOff";
		title = newState ? NSLocalizedString(@"Num Lock On", @"") : NSLocalizedString(@"Num Lock Off", @"");
		identifier = @"HWGrowlNumLock";
		iconData = newState ? [[NSImage imageNamed:@"caps_on"] TIFFRepresentation] : [[NSImage imageNamed:@"caps_off"] TIFFRepresentation];
	}else if ([type isEqualToString:@"fn"]){
		name = newState ? @"FNPressed" : @"FNReleased";
		title = newState ? NSLocalizedString(@"FN Key Pressed", @"") : NSLocalizedString(@"FN Key Pressed", @"");
		identifier = @"HWGrowlFNKey";
		iconData = newState ? [[NSImage imageNamed:@"fn_on"] TIFFRepresentation] : [[NSImage imageNamed:@"fn_off"] TIFFRepresentation];
	}else if ([type isEqualToString:@"shift"]){
		name = newState ? @"ShiftPressed" : @"ShiftReleased";
		title = newState ? NSLocalizedString(@"Shift Key Pressed", @"") : NSLocalizedString(@"Shift Key Presed", @"");
		identifier = @"HWGrowlShiftKey";
		//iconData = newState ? [[NSImage imageNamed:@"caps_on"] TIFFRepresentation] : [[NSImage imageNamed:@"caps_off"] TIFFRepresentation];
	}else {
		return;
	}
	
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
	numlockFlag = flags & NSNumericPadKeyMask ? YES : NO;
	capsFlag = flags & NSAlphaShiftKeyMask ? YES : NO;
	fnFlag = flags & NSFunctionKeyMask ? YES : NO;
}

#pragma mark HWGrowlPluginProtocol

-(void)setDelegate:(id<HWGrowlPluginControllerProtocol>)aDelegate{
	delegate = aDelegate;
}
-(id<HWGrowlPluginControllerProtocol>)delegate {
	return delegate;
}
-(NSString*)pluginDisplayName{
	return NSLocalizedString(@"Capster", @"");
}
-(NSImage*)preferenceIcon {
	static NSImage *_icon = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		//_icon = [[NSImage imageNamed:@"HWGPrefsDrivesVolumes"] retain];
	});
	return _icon;
}
-(NSView*)preferencePane {
	return nil;
}
-(BOOL)enabledByDefault {
	return NO;
}

#pragma mark HWGrowlPluginNotifierProtocol

-(NSArray*)noteNames {
	return [NSArray arrayWithObjects:@"CapsLockOn", @"CapsLockOff", @"NumLockOn", @"NumLockOff", @"FNPressed", @"FNReleased", @"ShiftPressed", @"ShiftReleased", nil];
}
-(NSDictionary*)localizedNames {
	return [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Caps Lock On", @""), @"CapsLockOn",
			  NSLocalizedString(@"Caps Lock Off", @""), @"CapsLockOff",
			  NSLocalizedString(@"Num Lock On", @""), @"NumLockOn",
			  NSLocalizedString(@"Num Lock Off", @""), @"NumLockOff",
			  NSLocalizedString(@"FN Key Pressed", @""), @"FNPressed",
			  NSLocalizedString(@"FN Key Released", @""), @"FNReleased",
			  NSLocalizedString(@"Shift Key Pressed", @""), @"ShiftPressed",
			  NSLocalizedString(@"Shift Key Released", @""), @"ShiftReleased", nil];
}
-(NSDictionary*)noteDescriptions {
	return [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Caps Lock On", @""), @"CapsLockOn",
			  NSLocalizedString(@"Caps Lock Off", @""), @"CapsLockOff",
			  NSLocalizedString(@"Num Lock On", @""), @"NumLockOn",
			  NSLocalizedString(@"Num Lock Off", @""), @"NumLockOff",
			  NSLocalizedString(@"FN Key Pressed", @""), @"FNPressed",
			  NSLocalizedString(@"FN Key Released", @""), @"FNReleased",
			  NSLocalizedString(@"Shift Key Pressed", @""), @"ShiftPressed",
			  NSLocalizedString(@"Shift Key Released", @""), @"ShiftReleased", nil];
}
-(NSArray*)defaultNotifications {
	return [NSArray arrayWithObjects:@"CapsLockOn", @"CapsLockOff", @"NumLockOn", @"NumLockOff", @"FNPressed", @"FNReleased", nil];
}

@end
