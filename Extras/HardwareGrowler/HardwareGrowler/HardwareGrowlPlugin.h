//
//  HardwareGrowlPlugin.h
//  HardwareGrowler
//
//  Created by Daniel Siemer on 5/2/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HWGrowlPluginControllerProtocol <NSObject>
@required
-(void)notifyWithName:(NSString*)name 
					 title:(NSString*)title
			 description:(NSString*)description
					  icon:(NSData*)iconData
	  identifierString:(NSString*)identifier
		  contextString:(NSString*)context
					plugin:(id)plugin;

-(BOOL)onLaunchEnabled;

@end

@protocol HWGrowlPluginProtocol <NSObject>
@required
-(void)setDelegate:(id<HWGrowlPluginControllerProtocol>)aDelegate;
-(id<HWGrowlPluginControllerProtocol>)delegate;
-(NSString*)pluginDisplayName;
-(NSView*)preferencePane;

@end

@protocol HWGrowlPluginNotifierProtocol <NSObject>
@required
-(NSArray*)noteNames;
-(NSDictionary*)localizedNames;
-(NSDictionary*)noteDescriptions;
-(NSArray*)defaultNotifications;

@optional
-(void)postRegistrationInit;
-(void)fireOnLaunchNotes;
-(void)noteClosed:(NSString*)contextString byClick:(BOOL)clicked;

@end

/* Used for purely stat monitoring plugins */
@protocol HWGrowlPluginMonitorProtocol <NSObject>
@optional
-(NSView*)menuBarSizedView;
-(NSView*)menuViewOfWidth:(CGFloat)width;

@end
