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

@interface GrowlDisplayBridgeController () {
	NSMutableSet *pending;
	NSMutableSet *allWindows;
	NSMutableSet *displayedWindows;
	NSMutableArray *windowQueue;
	NSMutableDictionary *windowsByDisplayID;
	NSMutableDictionary *positionControllers;
	NSMutableDictionary *queueKeysByDisplayID;
	NSMutableDictionary *queuingDisplayQueues;
	NSMutableDictionary *queuingDisplayCurrentWindows;
}

@property (nonatomic, retain) NSMutableSet *pending;
@property (nonatomic, retain) NSMutableSet *allWindows;
@property (nonatomic, retain) NSMutableSet *displayedWindows;
@property (nonatomic, retain) NSMutableArray *windowQueue;
@property (nonatomic, retain) NSMutableDictionary *windowsByDisplayID;

@property (nonatomic, retain) NSMutableDictionary *positionControllers;

@property (nonatomic, retain) NSMutableDictionary *queueKeysByDisplayID;
@property (nonatomic, retain) NSMutableDictionary *queuingDisplayQueues;
@property (nonatomic, retain) NSMutableDictionary *queuingDisplayCurrentWindows;

@end

@implementation GrowlDisplayBridgeController

@synthesize pending;
@synthesize allWindows;
@synthesize displayedWindows;
@synthesize windowQueue;
@synthesize windowsByDisplayID;
@synthesize positionControllers;

@synthesize queueKeysByDisplayID;
@synthesize queuingDisplayQueues;
@synthesize queuingDisplayCurrentWindows;

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
		
		self.queueKeysByDisplayID = [NSMutableDictionary dictionary];
		self.queuingDisplayQueues = [NSMutableDictionary dictionary];
		self.queuingDisplayCurrentWindows = [NSMutableDictionary dictionary];
		
		__block GrowlDisplayBridgeController *blockSelf = self;
		//Generate a position controller for each display
		[[NSScreen screens] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			[blockSelf addPositionControllersForScreen:obj];
		}];
		
/*		void (^screenChangeBlock)(NSNotification*) = ^(NSNotification *note){
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
				
				NSMutableSet *queueKeys = [blockSelf.queueKeysByDisplayID valueForKey:key];
				[queueKeys enumerateObjectsUsingBlock:^(id queueObj, BOOL *queueStop) {
					[blockSelf.queuingDisplayCurrentWindows removeObjectForKey:queueObj];
					//tell these to redisplay
					NSMutableArray *queue = [queuingDisplayQueues valueForKey:queueObj];
					[queue enumerateObjectsUsingBlock:^(id windowObj, NSUInteger windowIDX, BOOL *windowStop) {
						//NSLog(@"old queue key: %@ new key: %@", queueObj, [windowObj displayQueueKey]);
						//This isn't working quite right yet
						[blockSelf displayQueueWindow:windowObj];
					}];
					[queuingDisplayQueues removeObjectForKey:queueObj];
				}];
				[blockSelf.queueKeysByDisplayID removeObjectForKey:key];
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
																	 usingBlock:screenChangeBlock];*/
      
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(displayChangeNotification:)
                                                   name:NSApplicationDidChangeScreenParametersNotification
                                                 object:nil];
	}
	return self;
}

-(void)displayChangeNotification:(NSNotification*)note {
   __block GrowlDisplayBridgeController *blockSelf = self;
   NSArray *screens = [NSScreen screens];
   __block NSMutableArray *newIDs = [NSMutableArray array];
   [screens enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      NSUInteger screenID = [obj screenID];
      [newIDs addObject:[NSString stringWithFormat:@"%lu", screenID]];
   }];
   
   __block NSMutableArray *toRemove = [NSMutableArray array];
   [self.positionControllers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
      if(![newIDs containsObject:key])
         [toRemove addObject:key];
   }];
   
   if([toRemove count]) NSLog(@"Removing %lu positioning controller(s)", [toRemove count]);
   [[self.positionControllers dictionaryWithValuesForKeys:toRemove] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
      NSMutableSet *displayed = [blockSelf.windowsByDisplayID valueForKey:key];
      [blockSelf.displayedWindows minusSet:displayed];
      [blockSelf.allWindows minusSet:displayed];
      [blockSelf.positionControllers removeObjectForKey:key];
      [blockSelf.windowsByDisplayID removeObjectForKey:key];
      
      NSMutableSet *queueKeys = [blockSelf.queueKeysByDisplayID valueForKey:key];
      [queueKeys enumerateObjectsUsingBlock:^(id queueObj, BOOL *queueStop) {
         [blockSelf.queuingDisplayCurrentWindows removeObjectForKey:queueObj];
         //tell these to redisplay
         NSMutableArray *queue = [queuingDisplayQueues valueForKey:queueObj];
         [queue enumerateObjectsUsingBlock:^(id windowObj, NSUInteger windowIDX, BOOL *windowStop) {
            //NSLog(@"old queue key: %@ new key: %@", queueObj, [windowObj displayQueueKey]);
            //This isn't working quite right yet
            [blockSelf displayQueueWindow:windowObj];
         }];
         [queuingDisplayQueues removeObjectForKey:queueObj];
      }];
      [blockSelf.queueKeysByDisplayID removeObjectForKey:key];
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
	GrowlPositionController* result = nil;
	@try {
		result = [self positionControllerForScreen:[window screen]];
	}
	@catch (NSException *exception) {
		NSLog(@"Caught Exception: %@ trying to get the position controller for window %@", exception, window);
	}
	@finally {
		
	}
	return result;
}

-(BOOL)displayWindow:(GrowlDisplayWindowController*)window
{
	if(![[window plugin] requiresPositioning]){
		[window setOccupiedRect:[[window screen] frame]];
		return YES;
	}else{
		GrowlPositionController *controller = [self positionControllerForWindow:window];
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
	//If pending doesn't contain us, likely webkit is telling us to update the position due to a coalescing update
	//In that case, tell it to reposition.  Makes sure that we dont have a problem with coalescing in WebKit displays
	if([pending containsObject:window]){
		[self displayWindow:window reposition:NO];
		[pending removeObject:window];
	}else{
		[self displayWindow:window reposition:YES];
	}
	[window release];
}

-(void)displayQueueWindow:(GrowlDisplayWindowController*)window 
{
	[allWindows addObject:window];
	BOOL display = YES;
	if(![[window plugin] requiresPositioning]){
		NSString *displayQueueKey = [window displayQueueKey];
		if([queuingDisplayCurrentWindows valueForKey:displayQueueKey] || [queuingDisplayQueues valueForKey:displayQueueKey]){
			display = NO;
			NSMutableArray *queue = [queuingDisplayQueues valueForKey:displayQueueKey];
			if(!queue){
				queue = [NSMutableArray array];
				[queuingDisplayQueues setValue:queue forKey:displayQueueKey];
			}
			[queue addObject:window];
		}
		NSString *screenID = [[window screen] screenIDString];
		NSMutableSet *keys = [queueKeysByDisplayID valueForKey:screenID];
		if(!keys){
			keys = [NSMutableSet set];
			[queueKeysByDisplayID setValue:keys forKey:screenID];
		}
		[keys addObject:displayQueueKey];
	}
	
	if(display){
		[window setOccupiedRect:[[window screen] frame]];
		[window foundSpaceToStart];
		[displayedWindows addObject:window];
		NSMutableSet *controllerSet = [windowsByDisplayID valueForKey:[NSString stringWithFormat:@"%lu", [[window screen] screenID]]];
		if(controllerSet) [controllerSet addObject:window];
		NSString *displayQueueKey = [window displayQueueKey];
		[queuingDisplayCurrentWindows setValue:window forKey:displayQueueKey];
	}
}

-(void)displayWindow:(GrowlDisplayWindowController*)window reposition:(BOOL)reposition
{
	if(![[window plugin] requiresPositioning]){
		[self displayQueueWindow:window];
	}else{
		GrowlPositionController *controller = [self positionControllerForWindow:window];
		[allWindows addObject:window];
		if(reposition){
			[self clearRect:[window occupiedRect] inPositionController:controller];
			if(![self displayWindow:window]){
				NSLog(@"Couldnt find space for coalescing notification, adding to queue");
				[window stopDisplay];
				[displayedWindows removeObject:window];
				[windowQueue addObject:window];
			}
		} else if([self displayWindow:window]){
			[window foundSpaceToStart];
			[displayedWindows addObject:window];
			NSMutableSet *controllerSet = [windowsByDisplayID valueForKey:[NSString stringWithFormat:@"%lu", [controller deviceID]]];
			if(controllerSet) [controllerSet addObject:window];
		}else{
			//NSLog(@"putting in queue");
			[windowQueue addObject:window];
		}
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
					NSMutableSet *controllerSet = [blockSelf.windowsByDisplayID valueForKey:[[obj screen] screenIDString]];
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
	if([[window plugin] requiresPositioning]){
		GrowlPositionController *controller = [self positionControllerForWindow:window];
		CGRect clearRect = [window occupiedRect];
		[self clearRect:clearRect inPositionController:controller];
		
		[[self class] cancelPreviousPerformRequestsWithTarget:self
																	selector:@selector(checkQueuedWindows) 
																	  object:nil];
		[self performSelector:@selector(checkQueuedWindows) 
					  withObject:nil 
					  afterDelay:.2
						  inModes:[NSArray arrayWithObjects:NSRunLoopCommonModes, NSEventTrackingRunLoopMode, nil]];
	}else{
		//Get our next window out for this windows display queue key if there is one
		NSString *displayQueueKey = [window displayQueueKey];
		GrowlDisplayWindowController *current = [queuingDisplayCurrentWindows valueForKey:displayQueueKey];
		if(current == window){
			if([queuingDisplayQueues valueForKey:displayQueueKey])
			{
				NSMutableArray *displayQueue = [queuingDisplayQueues valueForKey:displayQueueKey];
				GrowlDisplayWindowController *nextWindow = [displayQueue objectAtIndex:0U];
				[nextWindow setOccupiedRect:[[nextWindow screen] frame]];
				[nextWindow foundSpaceToStart];
				[displayedWindows addObject:nextWindow];
				
				[queuingDisplayCurrentWindows setValue:nextWindow forKey:displayQueueKey];
				[displayQueue removeObjectAtIndex:0U];
				if(![displayQueue count]){
					//We dont have a queue, remove it so we track properly whether to enqueue more notes
					[queuingDisplayQueues removeObjectForKey:displayQueueKey];
				}
			}else {
				[queuingDisplayCurrentWindows removeObjectForKey:displayQueueKey];
			}
		}else{
			//NSLog(@"Error!, queue window %@ not the current window for queue key %@\nLikely a result of a removed screen", window, displayQueueKey);
		}
 	}
	NSMutableSet *controllerSet = [windowsByDisplayID valueForKey:[[window screen] screenIDString]];
	if(controllerSet) [controllerSet removeObject:window];
	[displayedWindows removeObject:window];
	[allWindows removeObject:window];
}

@end
