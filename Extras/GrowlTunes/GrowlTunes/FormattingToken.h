//
//  FormattingToken.h
//  GrowlTunes
//
//  Created by Travis Tilley on 11/27/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "macros.h"

@interface FormattingToken : NSObject <NSCoding> {
    @private
    
    BOOL _isDynamic;
    NSString* _editingString;
}

@property(readonly, nonatomic, assign) BOOL isDynamic;
@property(readonly, nonatomic, assign) NSTokenStyle tokenStyle;
@property(readonly, nonatomic, copy) NSString* editingString;
@property(readonly, nonatomic, copy) NSString* displayString;
@property(readonly, nonatomic, STRONG) NSString* lookupKey;

-(id)initWithEditingString:(NSString*)editingString;

@end
