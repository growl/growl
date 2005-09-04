//
//  GrowlLog.h
//  Growl
//
//  Created by Ingmar Stein on 17.04.05.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>

void GrowlLog_log(NSString *message);
void GrowlLog_logNotificationDictionary(NSDictionary *noteDict);
void GrowlLog_logRegistrationDictionary(NSDictionary *regDict);
