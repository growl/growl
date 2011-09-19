//
//  GrowlController.h
//  Capster
//
//  Created by Vasileios Georgitzikis on 9/3/11.
//  Copyright 2011 Tzikis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Growl/Growl.h>


@interface GrowlController : NSObject <GrowlApplicationBridgeDelegate>
{
@private
    
}
- (void) sendStartupGrowlNotification;
- (void) sendCapsLockNotification:(NSUInteger) newState;
@end
