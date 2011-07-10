//
//  GrowlHistoryNotification.h
//  Growl
//
//  Created by Daniel Siemer on 8/17/10.
//  Copyright 2010 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GrowlImageCache;

@interface GrowlHistoryNotification : NSManagedObject {

}
@property (nonatomic, retain) NSString * AppID;
@property (nonatomic, retain) NSString * ApplicationName;
@property (nonatomic, retain) NSString * Description;
@property (nonatomic, retain) NSString * Name;
@property (nonatomic, retain) NSDate   * Time;
@property (nonatomic, retain) NSString * Title;
@property (nonatomic, retain) NSNumber * Priority;
@property (nonatomic, retain) NSString * Identifier;
@property (nonatomic, retain) GrowlImageCache *Image;
@property (nonatomic, retain) NSNumber * deleteUponReturn;
@property (nonatomic, retain) NSNumber * showInRollup;
@property (nonatomic, retain) id GrowlDictionary;

-(void)setWithNoteDictionary:(NSDictionary*)noteDict;
-(NSString*)hashForData:(NSData*)data;

@end
