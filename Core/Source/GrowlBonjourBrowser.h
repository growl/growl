//
//  GrowlBonjourBrowser.h
//  Growl
//
//  Created by Daniel Siemer on 12/12/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>

#define GNTPServiceFoundNotification   @"GNTPServiceFound"
#define GNTPServiceRemovedNotification @"GNTPServiceRemoved"
#define GNTPBrowserStopNotification    @"GNTPBrowserStopped"

#define GNTPServiceKey @"GNTPService"

@interface GrowlBonjourBrowser : NSObject <NSNetServiceBrowserDelegate>

@property (nonatomic, retain) NSNetServiceBrowser *browser;
@property (nonatomic, retain) NSMutableArray *services;

@property (nonatomic) NSUInteger browseCount;

+(GrowlBonjourBrowser*)sharedBrowser;

-(BOOL)startBrowsing;
-(BOOL)stopBrowsing;

@end
