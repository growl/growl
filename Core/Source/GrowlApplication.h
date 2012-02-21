//
//  GrowlApplication.h
//  Growl
//
//  Created by Evan Schoenberg on 5/10/07.
//  Copyright 2007 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GrowlApplication : NSApplication {
	NSTimer *autoreleasePoolRefreshTimer;
}

@property (nonatomic, retain) NSString *appMenuLabel;
@property (nonatomic, retain) NSString *aboutAppLabel;
@property (nonatomic, retain) NSString *preferencesLabel;
@property (nonatomic, retain) NSString *servicesMenuLabel;
@property (nonatomic, retain) NSString *hideAppLabel;
@property (nonatomic, retain) NSString *hideOthersLabel;
@property (nonatomic, retain) NSString *showAllLabel;
@property (nonatomic, retain) NSString *quitAppLabel;

@property (nonatomic, retain) NSString *editMenuLabel;
@property (nonatomic, retain) NSString *undoLabel;
@property (nonatomic, retain) NSString *redoLabel;
@property (nonatomic, retain) NSString *cutLabel;
@property (nonatomic, retain) NSString *theCopyLabel;
@property (nonatomic, retain) NSString *pasteLabel;
@property (nonatomic, retain) NSString *pasteAndMatchLabel;
@property (nonatomic, retain) NSString *deleteLabel;
@property (nonatomic, retain) NSString *selectAllLabel;

@property (nonatomic, retain) NSString *findMenuLabel;
@property (nonatomic, retain) NSString *findLabel;
@property (nonatomic, retain) NSString *findAndReplaceLabel;
@property (nonatomic, retain) NSString *findNextLabel;
@property (nonatomic, retain) NSString *findPreviousLabel;
@property (nonatomic, retain) NSString *useSelectionForFindLabel;
@property (nonatomic, retain) NSString *jumpToSelectionLabel;

@property (nonatomic, retain) NSString *spellingGrammarMenuLabel;
@property (nonatomic, retain) NSString *showSpellingGrammarLabel;
@property (nonatomic, retain) NSString *checkDocumentNowLabel;
@property (nonatomic, retain) NSString *checkSpellingWhileTypingLabel;
@property (nonatomic, retain) NSString *checkGrammarWithSpelling;
@property (nonatomic, retain) NSString *correctSpellingAutomatically;

@property (nonatomic, retain) NSString *substitutionsMenuLabel;
@property (nonatomic, retain) NSString *showSubstitutionsLabel;
@property (nonatomic, retain) NSString *smartCopyPasteLabel;
@property (nonatomic, retain) NSString *smartQuotesLabel;
@property (nonatomic, retain) NSString *smartDashesLabel;
@property (nonatomic, retain) NSString *smartLinksLabel;
@property (nonatomic, retain) NSString *dataDetectorsLabel;
@property (nonatomic, retain) NSString *textReplacementLabel;

@property (nonatomic, retain) NSString *transformationsMenuLabel;
@property (nonatomic, retain) NSString *makeUpperCaseLabel;
@property (nonatomic, retain) NSString *makeLowerCaseLabel;
@property (nonatomic, retain) NSString *capitalizeLabel;

@property (nonatomic, retain) NSString *speechMenuLabel;
@property (nonatomic, retain) NSString *startSpeaking;
@property (nonatomic, retain) NSString *stopSpeaking;

@property (nonatomic, retain) NSString *windowMenuLabel;
@property (nonatomic, retain) NSString *minimizeLabel;
@property (nonatomic, retain) NSString *zoomLabel;
@property (nonatomic, retain) NSString *closeLabel;
@property (nonatomic, retain) NSString *bringAllToFrontLabel;

@property (nonatomic, retain) NSString *helpMenuLabel;
@property (nonatomic, retain) NSString *appHelpLabel;

@end
