//
//  KABubbleController.h
//  Growl
//
//  Created by Nelson Elhage on Wed Jun 09 2004.
//  Copyright (c) 2004 Nelson Elhage. All rights reserved.
//

@interface KABubbleController : NSObject {

}

#pragma mark Growl Gets Satisfaction

- (void) loadPlugin;
- (NSString *) author;
- (NSString *) name;
- (NSString *) userDescription;
- (NSString *) version;
- (void) unloadPlugin;

- (void)  displayNotificationWithInfo:(NSDictionary *) noteDict;

@end
