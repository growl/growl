//
//  NSPreferencesModule.h
//  GrowlMail
//
//  Created by Ingmar Stein on Fri Oct 29 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.

#import <Cocoa/Cocoa.h>

@protocol NSPreferencesModule
- (void)moduleWasInstalled;
- (void)moduleWillBeRemoved;
- (void)didChange;
- (void)initializeFromDefaults;
- (void)willBeDisplayed;
- (void)saveChanges;
- (char)hasChangesPending;
- imageForPreferenceNamed:fp12;
- viewForPreferenceNamed:fp12;
@end

@interface NSPreferencesModule:NSObject <NSPreferencesModule>
{
    IBOutlet NSBox *_preferencesView;
    struct _NSSize _minSize;
    char _hasChanges;
    void *_reserved;
}

+ (id)sharedInstance;
- (void)dealloc;
- (id)init;
- (NSString *)preferencesNibName;
- (void)setPreferencesView:fp12;
- (id)viewForPreferenceNamed:(NSString *)aName;
- (NSImage *)imageForPreferenceNamed:(NSString *)aName;
- (NSString *)titleForIdentifier:(NSString *)aName;
- (char)hasChangesPending;
- (void)saveChanges;
- (void)willBeDisplayed;
- (void)initializeFromDefaults;
- (void)didChange;
- (NSSize)minSize;
- (void)moduleWillBeRemoved;
- (void)moduleWasInstalled;
- (char)isResizable;

@end
