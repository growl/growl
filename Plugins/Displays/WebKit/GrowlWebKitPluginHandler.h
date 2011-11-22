//
//  GrowlWebKitPluginHandler.m
//  Growl
//
//  Created by JKP on 03/11/2005.
//	Copyright 2005Ð2011 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GrowlWebKitPluginHandler : GrowlAbstractSingletonObject <GrowlPluginHandler> {

}

- (id) initSingleton;
- (BOOL) loadPluginAtPath:(NSString *)path;

@end
