//
//  GrowlDisplayBridgeController.m
//  Growl
//
//  Created by Daniel Siemer on 3/29/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <GrowlPlugins/GrowlDisplayPlugin.h>
#import "GrowlDisplayBridgeController.h"
#import "GrowlPositionController.h"
#import "GrowlNotification.h"
#import "GrowlDisplayWindowController.h"
#import "GrowlPositioningDefines.h"
#import "NSScreen+GrowlScreenAdditions.h"

@interface GrowlDisplayBridgeController ()

@property (nonatomic, retain) NSMutableSet *pending;
@property (nonatomic, retain) NSMutableSet *allWindows;
@property (nonatomic, retain) NSMutableSet *displayedWindows;
@property (nonatomic, retain) NSMutableArray *windowQueue;
@property (nonatomic, retain) NSMutableDictionary *windowsByDisplayID;

@property (nonatomic, retain) NSMutableDictionary *positionControllers;

@end

@implementation GrowlDisplayBridgeController

@synthesize pending;
@synthesize allWindows;
@synthesize displayedWindows;
@synthesize windowQueue;
@synthesize windowsByDisplayID;
@synthesize positionControllers;

+(GrowlDisplayBridgeController*)sharedController {
	static GrowlDisplayBridgeController *sharedController = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedController = [[GrowlDisplayBridgeController alloc] init];
	});
	return sharedController;
}

-(id)init {
	if((self = [super init])){
		self.pending = [NSMutableSet set];
		self.allWindows = [NSMutableSet set];
		self.displayedWindows = [NSMutableSet set];
		self.windowQueue = [NSMutableArray array];
		self.positionControllers = [NSMutableDictionary dictionaryWithCapacity:[[NSScreen screens] count]];
		self.windowsByDisplayID = [NSMutableDictionary dictionaryWithCapacity:[[NSScreen screens] count]];
		
		__block GrowlDisplayBridgeController *blockSelf = self;
		//Generate a position controller for each display
		[[NSScreen screens] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			[blockSelf addPositionControllersForScreen:obj];
		}];
		
		void (^screenChangeBlock)(NSNotification*) = ^(NSNotification *note){
			NSArray *screens = [NSScreen screens];
			__block NSMutableArray *newIDs = [NSMutableArray array];
			[screens enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				NSUInteger screenID = [obj screenID];
				[newIDs addObject:[NSString stringWithFormat:@"%lu", screenID]];
			}];
			
			__block NSMutableArray *toRemove = [NSMutableArray array];
			[blockSelf.positionControllers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
				if(![newIDs containsObject:key])
					[toRemove addObject:key];
			}];
			
			if([toRemove count]) NSLog(@"Removing %lu positioning controller(s)", [toRemove count]);
			[[blockSelf.positionControllers dictionaryWithValuesForKeys:toRemove] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
				NSMutableSet *displayed = [blockSelf.windowsByDisplayID valueForKey:key];
				[blockSelf.displayedWindows minusSet:displayed];
				[blockSelf.allWindows minusSet:displayed];
				[blockSelf.positionControllers removeObjectForKey:key];
				[blockSelf.windowsByDisplayID removeObjectForKey:key];
			}];
			
			[screens enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				CGRect newRect = [obj visibleFrame];
				GrowlPositionController *controller = [blockSelf positionControllerForScreen:obj];
				if(!controller){
					[blockSelf addPositionControllersForScreen:obj];
				}else{
					CGRect currentRect = [controller screenFrame];
					if(!CGRectEqualToRect(newRect, currentRect))
					{
						if([controller isFrameFree:[controller screenFrame]])
							[controller setScreenFrame:newRect];
						else{
							[controller setUpdateFrame:YES];
							[controller setNewFrame:newRect];
						}
					}
				}
			}];
		};
		
		[[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationDidChangeScreenParametersNotification
																		  object:nil
																			queue:[NSOperationQueue mainQueue]
																	 usingBlock:screenChangeBlock];
	}
	return self;
}

-(void)addPositionControllersForScreen:(NSScreen*)screen {
	GrowlPositionController *controller = [[GrowlPositionController alloc] initWithScreenFrame:[screen visibleFrame]];
	NSUInteger screenID = [screen screenID];
	NSString *screenIDKey = [screen screenIDString];
	NSLog(@"add screen with id %@", screenIDKey);

	[controller setDeviceID:screenID];
	[positionControllers setValue:controller forKey:screenIDKey];
	
	NSMutableSet *controllerSet = [NSMutableSet set];
	[windowsByDisplayID setValue:controllerSet forKey:screenIDKey];
	[controller release];
}

-(GrowlPositionController*)positionControllerForScreenID:(NSUInteger)screenID {
	return [positionControllers valueForKey:[NSString stringWithFormat:@"%lu", screenID]];
}

-(GrowlPositionController*)positionControllerForScreen:(NSScreen*)screen {
	return [self positionControllerForScreenID:[screen screenID]];
}

-(GrowlPositionController*)positionControllerForWindow:(GrowlDisplayWindowController*)window
{
	return [self positionControllerForScreen:[window screen]];
}

-(BOOL)displayWindow:(GrowlDisplayWindowController*)window
{
	GrowlPositionController *controller = [self positionControllerForWindow:window];
	if(![[window plugin] requiresPositioning]){
		[window setOccupiedRect:[[window screen] frame]];
		return YES;
	}else{
		NSDictionary *configDict = [[window notification] configurationDict];
		GrowlPositionOrigin	position = configDict ? [[configDict valueForKey:@"com.growl.positioncontroller.selectedposition"] intValue] : GrowlTopRightCorner;
		
		NSSize displaySize = [window requiredSize];		
		CGRect found = [controller canFindSpotForSize:displaySize
											startingInPosition:position];
		if(!CGRectEqualToRect(found, CGRectZero)){
			[controller occupyRect:found];
			[window setOccupiedRect:found];
			return YES;
		}
	}
	return NO;
}

-(void)addPendingWindow:(GrowlDisplayWindowController*)window {
	[pending addObject:window];
}

-(void)windowReadyToStart:(GrowlDisplayWindowController*)window {
	[window retain];
	[self displayWindow:window reposition:NO];
	[pending removeObject:window];
	[window release];
}

-(void)displayWindow:(GrowlDisplayWindowController*)window reposition:(BOOL)reposition
{
	[allWindows addObject:window];
	GrowlPositionController *controller = [self positionControllerForWindow:window];
	if(reposition){
		[self clearRect:[window occupiedRect] inPositionController:controller];
		if(![self displayWindow:window]){
			NSLog(@"Couldnt find space for coalescing notification, adding to queue");
			[window stopDisplay];
			[displayedWindows removeObject:window];
			[windowQueue addObject:window];
		}
	}else if([self displayWindow:window]){
		[window foundSpaceToStart];
		[displayedWindows addObject:window];
		NSMutableSet *controllerSet = [windowsByDisplayID valueForKey:[NSString stringWithFormat:@"%lu", [controller deviceID]]];
		if(controllerSet) [controllerSet addObject:window];
	}else{
		//NSLog(@"putting in queue");
		[windowQueue addObject:window];
	}
}

-(void)checkQueuedWindows
{
	__block GrowlDisplayBridgeController *blockSelf = self;
	if([windowQueue count]){
		dispatch_async(dispatch_get_main_queue(), ^{
			__block NSMutableArray *found = [NSMutableArray array];
			[blockSelf.windowQueue enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				if([blockSelf displayWindow:obj]){
					[found addObject:obj];
					[obj foundSpaceToStart];
					[[blockSelf displayedWindows] addObject:obj];
					GrowlPositionController *controller = [self positionControllerForWindow:obj];
					NSMutableSet *controllerSet = [blockSelf.windowsByDisplayID valueForKey:[NSString stringWithFormat:@"%lu", [controller deviceID]]];
					if(controllerSet) [controllerSet addObject:obj];
				}
			}];
			[blockSelf.windowQueue removeObjectsInArray:found];
		});
	}
}

-(void)clearRect:(CGRect)rect inPositionController:(GrowlPositionController*)controller {
	[controller vacateRect:rect];
	if([controller updateFrame] && [controller isFrameFree:[controller screenFrame]]){
		[controller setUpdateFrame:NO];
		[controller setScreenFrame:[controller newFrame]];
	}
}

-(void)takeDownDisplay:(GrowlDisplayWindowController*)window
{
	GrowlPositionController *controller = [self positionControllerForWindow:window];
	if([[window plugin] requiresPositioning]){
		CGRect clearRect = [window occupiedRect];
		[self clearRect:clearRect inPositionController:controller];
		
		[[self class] cancelPreviousPerformRequestsWithTarget:self
																	selector:@selector(checkQueuedWindows) 
																	  object:nil];
		[self performSelector:@selector(checkQueuedWindows) withObject:nil afterDelay:.2];
	}
	NSMutableSet *controllerSet = [windowsByDisplayID valueForKey:[NSString stringWithFormat:@"%lu", [controller deviceID]]];
	if(controllerSet) [controllerSet removeObject:window];
	[displayedWindows removeObject:window];
	[allWindows removeObject:window];
}

@end
