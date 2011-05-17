//
//  GrowlHistoryWindowNotificationCell.h
//  Growl
//
//  Created by Daniel Siemer on 5/7/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GrowlHistoryNotification;

@interface GrowlHistoryWindowNotificationCell : NSCell {
   GrowlHistoryNotification *note;
   NSAttributedString *applicationLine;
   NSAttributedString *descriptionLine;
   NSAttributedString *tooltipString;
}
@property (nonatomic, retain) GrowlHistoryNotification *note;

@end
