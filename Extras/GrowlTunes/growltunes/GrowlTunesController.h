//
//  GrowlTunesController.h
//  growltunes
//
//  Created by Travis Tilley on 11/7/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>

@class ITunesConductor;

@interface GrowlTunesController : NSObject <GrowlApplicationBridgeDelegate> {
    __strong ITunesConductor* _iTunesConductor;
    __strong NSMenu* _statusItemMenu;
    NSStatusItem* _statusItem;
}

@property(readonly, strong, nonatomic) ITunesConductor* conductor;
@property(readwrite, strong, nonatomic) IBOutlet NSMenu* statusItemMenu;

- (IBAction)quitGrowlTunes:(id)sender;
- (void)createStatusItem;

@end
