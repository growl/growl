//
//  NSMutableAttributedStringAdditions.h
//  Growl
//
//  Created by Ingmar Stein on 19.06.05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSMutableAttributedString(GrowlAdditions)
- (void) addDefaultAttributes:(NSDictionary *)defaultAttributes;
@end
