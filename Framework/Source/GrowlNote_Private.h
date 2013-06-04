//
//  GrowlNote_Private.h
//  Growl
//
//  Created by Daniel Siemer on 5/8/13.
//  Copyright (c) 2013 The Growl Project. All rights reserved.
//

#import <Growl/Growl.h>

@interface GrowlNote ()

+ (NSDictionary *) notificationDictionaryByFillingInDictionary:(NSDictionary *)notifDict;

-(void)notify;
-(void)cancelNote;

-(void)fallback;
-(void)handleStatusUpdate:(GrowlNoteStatus)status;

@end
