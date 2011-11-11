//
//  GrowlNetworkUtilities.m
//  Growl
//
//  Created by Daniel Siemer on 11/11/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlNetworkUtilities.h"

#import <SystemConfiguration/SystemConfiguration.h>

@implementation GrowlNetworkUtilities

+(NSString*)localHostName
{
   NSString *hostname = @"localhost";
   
   CFStringRef cfHostName = SCDynamicStoreCopyLocalHostName(NULL);
   if(cfHostName != NULL){
      hostname = [[(NSString*)cfHostName copy] autorelease];
      CFRelease(cfHostName);
      if ([hostname hasSuffix:@".local"]) {
         hostname = [hostname substringToIndex:([hostname length] - [@".local" length])];
      }
   }
   return hostname;
}

@end
