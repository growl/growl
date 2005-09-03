//
//  SyncNotifier.h
//  HardwareGrowler
//
//  Created by Ingmar Stein on 03.09.05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SyncNotifier : NSObject {
	id delegate;
}

- (id) initWithDelegate:(id)object;
@end

@interface NSObject(SyncNotifierDelegate)
- (void) syncStarted;
- (void) syncFinished;
@end
