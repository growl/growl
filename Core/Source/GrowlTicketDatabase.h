//
//  GrowlTicketDatabase.h
//  Growl
//
//  Created by Daniel Siemer on 2/21/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlAbstractDatabase.h"

@interface GrowlTicketDatabase : GrowlAbstractDatabase

+(GrowlTicketDatabase *)sharedInstance;

-(void)upgradeFromTicketFiles;

@end
