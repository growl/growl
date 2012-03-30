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

@property (nonatomic, retain) NSMutableArray *displayedBridges;
@property (nonatomic, retain) NSMutableArray *bridgeQueue;

@property (nonatomic, retain) NSMutableArray *positionControllers;

@end

@implementation GrowlDisplayBridgeController

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
		self.displayedBridges = [NSMutableArray array];
		self.bridgeQueue = [NSMutableArray array];
		self.positionControllers = [NSMutableArray array];
		GrowlPositionController *mainPositionController = [[GrowlPositionController alloc] initWithScreenFrame:[[NSScreen mainScreen] visibleFrame]];
		[positionControllers addObject:mainPositionController];
		[mainPositionController release];
	}
	return self;
}

-(BOOL)displayWindow:(GrowlDisplayWindowController*)window
{
	if(![[window plugin] requiresPositioning]){
		return YES;
	}else{
		NSDictionary *configDict = [[window notification] configurationDict];
		GrowlPositionOrigin	position = configDict ? [[configDict valueForKey:@"com.growl.positioncontroller.selectedposition"] intValue] : GrowlTopRightCorner;
		
		//	NSScreen *preferredScreen = [displayController screen];
		GrowlPositionController *controller = [positionControllers objectAtIndex:0U];
		
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

-(void)displayBridge:(GrowlDisplayWindowController*)window reposition:(BOOL)reposition
{
	if(reposition){
		CGPoint startOrigin = [window occupiedRect].origin;
		[self clearRectForDisplay:window];
		if([self displayWindow:window]){
			CGPoint newOrigin = [window occupiedRect].origin;
			if(!CGPointEqualToPoint(startOrigin, newOrigin)) NSLog(@"Different origin for coalescing");
			
			[displayedBridges addObject:window];
		}else{
			NSLog(@"Couldnt find space for coalescing notification, adding to queue");
			[[window window] orderOut:self];
			[bridgeQueue addObject:window];
		}
	}else if([self displayWindow:window]){
		[window foundSpaceToStart];
		[displayedBridges addObject:window];
	}else
		[bridgeQueue addObject:window];
}

-(void)checkQueuedBridges
{
	__block GrowlDisplayBridgeController *blockSelf = self;
	if([bridgeQueue count]){
		dispatch_async(dispatch_get_main_queue(), ^{
			__block NSMutableArray *found = [NSMutableArray array];
			[blockSelf.bridgeQueue enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				if([blockSelf displayWindow:obj]){
					[found addObject:obj];
					[obj foundSpaceToStart];
				}
			}];
			[blockSelf.bridgeQueue removeObjectsInArray:found];
		});
	}
}

-(void)clearRectForDisplay:(GrowlDisplayWindowController*)window
{
	[displayedBridges removeObject:window];
	if([[window plugin] requiresPositioning]){
		//NSLog(@"clear rect");
		CGRect clearRect = [window occupiedRect];
		GrowlPositionController *controller = [positionControllers objectAtIndex:0U];
		[controller vacateRect:clearRect];
		
		[[self class] cancelPreviousPerformRequestsWithTarget:self
																	selector:@selector(checkQueuedBridges) 
																	  object:nil];
		[self performSelector:@selector(checkQueuedBridges) withObject:nil afterDelay:.2];
	}
}

@end
