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

@end

@protocol HWGrowlPluginProtocol <NSObject>
@required
-(void)setDelegate:(id<HWGrowlPluginControllerProtocol>)aDelegate;
-(id<HWGrowlPluginControllerProtocol>)delegate;
-(id)preferencePane;
-(NSArray*)noteNames;
-(NSDictionary*)localizedNames;
-(NSDictionary*)noteDescriptions;
-(NSArray*)defaultNotifications;

@optional
-(void)noteClosed:(NSDictionary*)note byClick:(BOOL)clicked;

@end


