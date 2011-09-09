//
//  GrowlErrorGNTPPacket.m
//  Growl
//
//  Created by Daniel Siemer on 9/7/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlErrorGNTPPacket.h"
#import "GrowlGNTPHeaderItem.h"

@implementation GrowlErrorGNTPPacket

@synthesize errorDescription;
@synthesize errorCode;

- (id)init
{
    if ((self = [super init])) {
       self.errorDescription = nil;
       self.errorCode = 0;
    }
    
    return self;
}

- (GrowlReadDirective)receivedHeaderItem:(GrowlGNTPHeaderItem *)headerItem
{
   NSString *name = [headerItem headerName];
   NSString *value = [headerItem headerValue];
      
   if([name caseInsensitiveCompare:@"Error-Code"] == NSOrderedSame){
      GrowlGNTPErrorCode code = [value intValue];
      self.errorCode = code;
   }else if([name caseInsensitiveCompare:@"Error-Description"] == NSOrderedSame){
      self.errorDescription = value;
   }
   
   if((errorCode != 0 && errorDescription) || headerItem == [GrowlGNTPHeaderItem separatorHeaderItem]){
      return GrowlReadDirective_PacketComplete;
   }
   return GrowlReadDirective_Continue;
}

#if GROWLHELPERAPP
- (NSDictionary *)growlDictionary
{
	NSMutableDictionary *growlDictionary = [[[super growlDictionary] mutableCopy] autorelease];
	
	[growlDictionary setValue:[NSNumber numberWithInteger:errorCode] forKey:@"Error-Code"];
   [growlDictionary setValue:errorDescription forKey:@"Error-Description"];
	
	return growlDictionary;
}
#endif

-(GrowlGNTPCallbackBehavior)callbackResultSendBehavior
{
   return GrowlGNTP_NoCallback;
}

@end
