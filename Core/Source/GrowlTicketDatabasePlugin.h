//
//  GrowlTicketDatabasePlugin.h
//  Growl
//
//  Created by Daniel Siemer on 3/2/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface GrowlTicketDatabasePlugin : NSManagedObject

@property (nonatomic, retain) id configuration;
@property (nonatomic, retain) NSString * pluginID;
@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSString * configID;
@property (nonatomic, retain) NSString * pluginType;

-(GrowlPlugin*)pluginInstanceForConfiguration;

@end
