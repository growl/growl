//
//  FormattingPreferencesProxy.h
//  GrowlTunes
//
//  Created by Travis Tilley on 11/24/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "macros.h"

@interface FormattingPreferencesHelper : NSObject <NSWindowDelegate, NSTokenFieldDelegate> {
    @private
    
    NSMutableDictionary* _podcast;
    NSMutableDictionary* _stream;
    NSMutableDictionary* _show;
    NSMutableDictionary* _movie;
    NSMutableDictionary* _musicVideo;
    NSMutableDictionary* _music;
    NSUserDefaults* _defaults;
   NSMutableArray* _dictionaries;
}

@property(readonly, STRONG, atomic) NSMutableDictionary* podcast;
@property(readonly, STRONG, atomic) NSMutableDictionary* stream;
@property(readonly, STRONG, atomic) NSMutableDictionary* show;
@property(readonly, STRONG, atomic) NSMutableDictionary* movie;
@property(readonly, STRONG, atomic) NSMutableDictionary* musicVideo;
@property(readonly, STRONG, atomic) NSMutableDictionary* music;

-(NSArray*)tokensForType:(NSString*)type andAttribute:(NSString*)attribute;

- (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject;
- (NSString *)tokenField:(NSTokenField *)tokenField editingStringForRepresentedObject:(id)representedObject;
- (id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString;
- (NSTokenStyle)tokenField:(NSTokenField *)tokenField styleForRepresentedObject:(id)representedObject;

@end
