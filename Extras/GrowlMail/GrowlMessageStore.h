//
//  GrowlMailStore.h
//  GrowlMail
//
//  Created by Ingmar Stein on 27.10.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "MailHeaders.h"

@interface GrowlMessageStore : MessageStore {

}
+ (void)load;
- (id)finishRoutingMessages:(NSArray *)messages routed:(NSArray *)routed;

@end
