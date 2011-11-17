//
//  GrowlNotificationRowView.h
//  Growl
//
//  Created by Daniel Siemer on 7/8/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface GrowlNotificationRowView : NSTableRowView{
    BOOL mouseInside;
    NSTrackingArea *trackingArea;
}
@property (nonatomic) BOOL mouseInside;

-(void)drawRoundedRectInRect:(NSRect)rect;

@end