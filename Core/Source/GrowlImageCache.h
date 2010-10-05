//
//  GrowlImageCache.h
//  Growl
//
//  Created by Daniel Siemer on 9/29/10.
//  Copyright 2010 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GrowlHistoryNotification;

@interface NSImageToDataTransformer : NSValueTransformer {
}
@end

@interface GrowlImageCache : NSManagedObject {
}
@property (nonatomic, retain) NSString * Checksum;
@property (nonatomic, retain) id Image;
@property (nonatomic, retain) NSSet* Notifications;

-(void)setImage:(NSData*)data andHash:(NSString*)hash;

@end

// coalesce these into one @interface GrowlImageCache (CoreDataGeneratedAccessors) section
@interface GrowlImageCache (CoreDataGeneratedAccessors)
- (void)addNotificationsObject:(GrowlHistoryNotification *)value;
- (void)removeNotificationsObject:(GrowlHistoryNotification *)value;
- (void)addNotifications:(NSSet *)value;
- (void)removeNotifications:(NSSet *)value;
@end
