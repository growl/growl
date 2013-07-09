//
//  GrowlApplicationBridge_Private.h
//  Growl
//
//  Created by Daniel Siemer on 5/9/13.
//  Copyright (c) 2013 The Growl Project. All rights reserved.
//

#import <Growl/Growl.h>

@interface GrowlApplicationBridge ()

@property (nonatomic, assign) BOOL hasGrowlThreeFrameworkSupport;

/*!	@method	_applicationNameForGrowlSearchingRegistrationDictionary:
 *	@abstract Obtain the name of the current application.
 *	@param regDict	The dictionary to search, or <code>nil</code> not to.
 *	@result	The name of the current application.
 *	@discussion	Does not call +bestRegistrationDictionary, and is therefore safe to call from it.
 */
- (NSString *) _applicationNameForGrowlSearchingRegistrationDictionary:(NSDictionary *)regDict;
/*!	@method	_applicationNameForGrowlSearchingRegistrationDictionary:
 *	@abstract Obtain the icon of the current application.
 *	@param regDict	The dictionary to search, or <code>nil</code> not to.
 *	@result	The icon of the current application, in IconFamily format (same as is used in 'icns' resources and .icns files).
 *	@discussion	Does not call +bestRegistrationDictionary, and is therefore safe to call from it.
 */
- (NSData *) _applicationIconDataForGrowlSearchingRegistrationDictionary:(NSDictionary *)regDict;

- (void) queueNote:(GrowlNote*)note;
- (void) finishedWithNote:(GrowlNote*)note;
- (BOOL) _growlIsReachableUpdateCache:(BOOL)update;
- (void) _checkSandbox;

- (GrowlNote*)noteForUUID:(NSString*)uuid;

- (void) context:(id)clickContext statusUpdate:(GrowlNoteStatus)status;

@end
