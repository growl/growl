//
//  FormattingPreferencesProxy.h
//  GrowlTunes
//
//  Created by Travis Tilley on 11/24/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FormattingPreferencesHelper : NSObject <NSWindowDelegate, NSTokenFieldDelegate> {
    @private
    
    NSMutableDictionary* _podcast;
    NSMutableDictionary* _stream;
    NSMutableDictionary* _show;
    NSMutableDictionary* _movie;
    NSMutableDictionary* _musicVideo;
    NSMutableDictionary* _music;
    NSUserDefaults* _defaults;
}

@property(readonly, retain, atomic) NSMutableDictionary* podcast;
@property(readonly, retain, atomic) NSMutableDictionary* stream;
@property(readonly, retain, atomic) NSMutableDictionary* show;
@property(readonly, retain, atomic) NSMutableDictionary* movie;
@property(readonly, retain, atomic) NSMutableDictionary* musicVideo;
@property(readonly, retain, atomic) NSMutableDictionary* music;

@end
