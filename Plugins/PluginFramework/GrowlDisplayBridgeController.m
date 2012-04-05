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

@interface GrowlDisplayBridgeController ()

@property (nonatomic, retain) NSMutableSet *pending;
@property (nonatomic, retain) NSMutableSet *allWindows;
@property (nonatomic, retain) NSMutableArray *displayedBridges;
@property (nonatomic, retain) NSMutableArray *bridgeQueue;

@property (nonatomic, retain) NSMutableArray *positionControllers;

@end

@implementation GrowlDisplayBridgeController

@synthesize pending;
@synthesize allWindows;
@synthesize displayedBridges;
@synthesize bridgeQueue;
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
		self.displayedBridges = [NSMutableArray array];
		self.bridgeQueue = [NSMutableArray array];
		self.positionControllers = [NSMutableArray arrayWithCapacity:[[NSScreen screens] count]];
		
		__block GrowlDisplayBridgeController *blockSelf = self;
		//Generate a position controller for each display
		[[NSScreen screens] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			GrowlPositionController *positionController = [[GrowlPositionController alloc] initWithScreenFrame:[obj visibleFrame]];
			NSUInteger screenID = [blockSelf deviceIDForScreen:obj];
			NSLog(@"%lu", screenID);
			[positionController setDeviceID:screenID];
			[blockSelf.positionControllers addObject:positionController];
			[positionController release];
		}];
		
		void (^screenChangeBlock)(NSNotification*) = ^(NSNotification *note){
			NSArray *screens = [NSScreen screens];
			if([screens count] != [blockSelf.positionControllers count]){				
				return;
			}
			[screens enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				CGRect newRect = [obj visibleFrame];
				GrowlPositionController *controller = [blockSelf.positionControllers objectAtIndex:idx];
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
			}];
		};
		
		[[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationDidChangeScreenParametersNotification
																		  object:nil
																			queue:[NSOperationQueue mainQueue]
																	 usingBlock:screenChangeBlock];
	}
	return self;
}

-(NSUInteger)deviceIDForScreen:(NSScreen*)screen {
	return [[[screen deviceDescription] valueForKey:@"NSScreenNumber"] unsignedIntegerValue];
}

-(GrowlPositionController*)positionControllerForWindow:(GrowlDisplayWindowController*)window
{
	NSUInteger screenNumber = [window screenNumber];
	if(screenNumber < [positionControllers count])
		return [positionControllers objectAtIndex:screenNumber];
	return [positionControllers objectAtIndex:0U];
}

-(BOOL)displayWindow:(GrowlDisplayWindowController*)window
{
	if(![[window plugin] requiresPositioning]){
		return YES;
	}else{
		NSDictionary *configDict = [[window notification] configurationDict];
		GrowlPositionOrigin	position = configDict ? [[configDict valueForKey:@"com.growl.positioncontroller.selectedposition"] intValue] : GrowlTopRightCorner;
		
		GrowlPositionController *controller = [self positionControllerForWindow:window];
		
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
	if(reposition){
		GrowlPositionController *controller = [positionControllers objectAtIndex:0U];
		[self clearRect:[window occupiedRect] inPositionController:controller];
		if(![self displayWindow:window]){
			NSLog(@"Couldnt find space for coalescing notification, adding to queue");
			[window stopDisplay];
			[displayedBridges removeObject:window];
			[bridgeQueue addObject:window];
		}
	}else if([self displayWindow:window]){
		[window foundSpaceToStart];
		[displayedBridges addObject:window];
	}else{
		//NSLog(@"putting in queue");
		[bridgeQueue addObject:window];
	}
}

-(void)checkQueuedWindows
{
	__block GrowlDisplayBridgeController *blockSelf = self;
	if([bridgeQueue count]){
		dispatch_async(dispatch_get_main_queue(), ^{
			__block NSMutableArray *found = [NSMutableArray array];
			[blockSelf.bridgeQueue enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				if([blockSelf displayWindow:obj]){
					[found addObject:obj];
					[obj foundSpaceToStart];
					[[blockSelf displayedBridges] addObject:obj];
				}
			}];
			[blockSelf.bridgeQueue removeObjectsInArray:found];
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
	[displayedBridges removeObject:window];
	if([[window plugin] requiresPositioning]){
		CGRect clearRect = [window occupiedRect];
		GrowlPositionController *controller = [self positionControllerForWindow:window];
		[self clearRect:clearRect inPositionController:controller];
		
		[[self class] cancelPreviousPerformRequestsWithTarget:self
																	selector:@selector(checkQueuedWindows) 
																	  object:nil];
		[self performSelector:@selector(checkQueuedWindows) withObject:nil afterDelay:.2];
	}
	[displayedBridges removeObject:window];
	[allWindows removeObject:window];
}

@end
