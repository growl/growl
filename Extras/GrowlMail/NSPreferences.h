/*
 *  NSPreferences.h
 *  GrowlMail
 *
 *  Created by Ingmar Stein on 30.10.04.
 *  Copyright 2004 __MyCompanyName__. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>


@interface NSPreferences:NSObject
{
    NSWindow *_preferencesPanel;
    NSBox *_preferenceBox;
    NSMatrix *_moduleMatrix;
    NSButtonCell *_okButton;
    NSButtonCell *_cancelButton;
    NSButtonCell *_applyButton;
    NSMutableArray *_preferenceTitles;
    NSMutableArray *_preferenceModules;
    NSMutableDictionary *_masterPreferenceViews;
    NSMutableDictionary *_currentSessionPreferenceViews;
    NSBox *_originalContentView;
    char _isModal;
    float _constrainedWidth;
    id _currentModule;
    void *_reserved;
}

+ sharedPreferences;
+ (void)setDefaultPreferencesClass:(Class)fp12;
+ (Class)defaultPreferencesClass;
- init;
- (void)dealloc;
- (void)addPreferenceNamed:fp12 owner:fp16;
- (void)_setupToolbar;
- (void)_setupUI;
- (struct _NSSize)preferencesContentSize;
- (void)showPreferencesPanel;
- (void)showPreferencesPanelForOwner:fp12;
- (int)showModalPreferencesPanelForOwner:fp12;
- (int)showModalPreferencesPanel;
- (void)ok:fp12;
- (void)cancel:fp12;
- (void)apply:fp12;
- (void)_selectModuleOwner:fp12;
- windowTitle;
- (void)confirmCloseSheetIsDone:fp12 returnCode:(int)fp16 contextInfo:(void *)fp20;
- (char)windowShouldClose:fp12;
- (void)windowDidResize:fp12;
- (struct _NSSize)windowWillResize:fp16 toSize:(struct _NSSize)fp20;
- (char)usesButtons;
- (void)toolbarItemClicked:fp12;
- toolbar:fp12 itemForItemIdentifier:fp16 willBeInsertedIntoToolbar:(char)fp20;
- toolbarDefaultItemIdentifiers:fp12;
- toolbarAllowedItemIdentifiers:fp12;
@end
