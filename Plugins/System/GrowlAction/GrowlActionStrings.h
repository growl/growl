//
//  GrowlActionStrings.h
//  GrowlAction
//
//  Created by Daniel Siemer on 10/24/12.
//
//

#import <Foundation/Foundation.h>

@interface GrowlActionStrings : NSObject

@property (nonatomic, retain) NSString *titleLabel;
@property (nonatomic, retain) NSString *descriptionLabel;
@property (nonatomic, retain) NSString *priorityLabel;
@property (nonatomic, retain) NSString *stickyLabel;

@property (nonatomic, retain) NSString *veryLowPriority;
@property (nonatomic, retain) NSString *moderatePriority;
@property (nonatomic, retain) NSString *normalPriority;
@property (nonatomic, retain) NSString *highPriority;
@property (nonatomic, retain) NSString *emergencyPriority;

@end
