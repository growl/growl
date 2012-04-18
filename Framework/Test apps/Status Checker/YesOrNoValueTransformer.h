//
//  YesOrNoValueTransformer.h
//  Status Checker
//
//  Created by Peter Hosey on 2009-08-07.
//  Copyright 2009 Peter Hosey. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface YesOrNoValueTransformer : NSValueTransformer {
	NSObject *yesObject;
	NSObject *noObject;
}

@property(retain) NSObject *yesObject;
@property(retain) NSObject *noObject;

@end
