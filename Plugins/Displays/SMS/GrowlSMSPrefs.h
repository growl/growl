//
//  GrowlSMSMePrefs.h
//  Display Plugins
//
//  Created by Diggory Laycock
//  Copyright 2005–2011 The Growl Project All rights reserved.
//

#import "GrowlPluginPreferencePane.h"

@interface GrowlSMSPrefs: GrowlPluginPreferencePane {
}

@property (nonatomic, retain) NSString *smsNotifications;
@property (nonatomic, retain) NSString *accountRequiredLabel;
@property (nonatomic, retain) NSString *instructions;
@property (nonatomic, retain) NSString *accountLabel;
@property (nonatomic, retain) NSString *passwordLabel;
@property (nonatomic, retain) NSString *apiIDLabel;
@property (nonatomic, retain) NSString *destinationLabel;

- (NSString *) getAccountName;
- (void) setAccountName:(NSString *)value;

- (NSString *) getAccountAPIID;
- (void) setAccountAPIID:(NSString *)value;

- (NSString *) getDestinationNumber;
- (void) setDestinationNumber:(NSString *)value;

- (NSString *) accountPassword;
- (void) setAccountPassword:(NSString *)value;

@end
