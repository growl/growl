//
//  GrowlErrorGNTPPacket.h
//  Growl
//
//  Created by Daniel Siemer on 9/7/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlGNTPPacket.h"
#import "GrowlGNTPDefines.h"

@interface GrowlErrorGNTPPacket : GrowlGNTPPacket{
   NSString *errorDescription;
   GrowlGNTPErrorCode errorCode;
}

@property (nonatomic, retain) NSString *errorDescription;
@property (nonatomic) GrowlGNTPErrorCode errorCode;

@end
