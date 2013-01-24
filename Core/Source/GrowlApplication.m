//
//  GrowlApplication.m
//  Growl
//
//  Created by Evan Schoenberg on 5/10/07.
//

#import "GrowlApplication.h"
#import "GrowlApplicationController.h"

@implementation GrowlApplication

@synthesize appMenuLabel;
@synthesize aboutAppLabel;
@synthesize preferencesLabel;
@synthesize servicesMenuLabel;
@synthesize hideAppLabel;
@synthesize hideOthersLabel;
@synthesize showAllLabel;
@synthesize quitAppLabel;

@synthesize editMenuLabel;
@synthesize undoLabel;
@synthesize redoLabel;
@synthesize cutLabel;
@synthesize theCopyLabel;
@synthesize pasteLabel;
@synthesize pasteAndMatchLabel;
@synthesize deleteLabel;
@synthesize selectAllLabel;

@synthesize findMenuLabel;
@synthesize findLabel;
@synthesize findAndReplaceLabel;
@synthesize findNextLabel;
@synthesize findPreviousLabel;
@synthesize useSelectionForFindLabel;
@synthesize jumpToSelectionLabel;

@synthesize spellingGrammarMenuLabel;
@synthesize showSpellingGrammarLabel;
@synthesize checkDocumentNowLabel;
@synthesize checkSpellingWhileTypingLabel;
@synthesize checkGrammarWithSpelling;
@synthesize correctSpellingAutomatically;

@synthesize substitutionsMenuLabel;
@synthesize showSubstitutionsLabel;
@synthesize smartCopyPasteLabel;
@synthesize smartQuotesLabel;
@synthesize smartDashesLabel;
@synthesize smartLinksLabel;
@synthesize dataDetectorsLabel;
@synthesize textReplacementLabel;

@synthesize transformationsMenuLabel;
@synthesize makeUpperCaseLabel;
@synthesize makeLowerCaseLabel;
@synthesize capitalizeLabel;

@synthesize speechMenuLabel;
@synthesize startSpeaking;
@synthesize stopSpeaking;

@synthesize windowMenuLabel;
@synthesize minimizeLabel;
@synthesize zoomLabel;
@synthesize closeLabel;
@synthesize bringAllToFrontLabel;

@synthesize helpMenuLabel;
@synthesize appHelpLabel;

- (id)init
{
   if((self = [super init])){
      NSString *appName = @"Growl";
      self.appMenuLabel = [NSString stringWithFormat:@"%@", appName];
      self.aboutAppLabel = [NSString stringWithFormat:NSLocalizedStringFromTable(@"About %@", @"mainmenu", nil), appName];
      self.preferencesLabel = NSLocalizedStringFromTable(@"Preferences...", @"mainmenu", nil);
      self.servicesMenuLabel = NSLocalizedStringFromTable(@"Services", @"mainmenu", nil);
      self.hideAppLabel = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Hide %@", @"mainmenu", nil), appName];
      self.hideOthersLabel = NSLocalizedStringFromTable(@"Hide Others", @"mainmenu", nil);
      self.showAllLabel = NSLocalizedStringFromTable(@"Show All", @"mainmenu", nil);
      self.quitAppLabel = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Quit %@", @"mainmenu", nil), appName];
      
      self.editMenuLabel = NSLocalizedStringFromTable(@"Edit", @"mainmenu", nil);
      self.undoLabel = NSLocalizedStringFromTable(@"Undo", @"mainmenu", nil);
      self.redoLabel = NSLocalizedStringFromTable(@"Redo", @"mainmenu", nil);
      self.cutLabel = NSLocalizedStringFromTable(@"Cut", @"mainmenu", nil);
      self.theCopyLabel = NSLocalizedStringFromTable(@"Copy", @"mainmenu", nil);
      self.pasteLabel = NSLocalizedStringFromTable(@"Paste", @"mainmenu", nil);
      self.pasteAndMatchLabel = NSLocalizedStringFromTable(@"Paste and Match Style", @"mainmenu", nil);
      self.deleteLabel = NSLocalizedStringFromTable(@"Delete", @"mainmenu", nil);
      self.selectAllLabel = NSLocalizedStringFromTable(@"Select All", @"mainmenu", nil);
      
      self.findMenuLabel = NSLocalizedStringFromTable(@"Find", @"mainmenu", nil);
      self.findLabel = NSLocalizedStringFromTable(@"Find...", @"mainmenu", nil);
      self.findAndReplaceLabel = NSLocalizedStringFromTable(@"Find and Replace...", @"mainmenu", nil);
      self.findNextLabel = NSLocalizedStringFromTable(@"Find Next", @"mainmenu", nil);
      self.findPreviousLabel = NSLocalizedStringFromTable(@"Find Previous", @"mainmenu", nil);
      self.useSelectionForFindLabel = NSLocalizedStringFromTable(@"Use Selection for Find", @"mainmenu", nil);
      self.jumpToSelectionLabel = NSLocalizedStringFromTable(@"Jump to Selection", @"mainmenu", nil);
      
      self.spellingGrammarMenuLabel = NSLocalizedStringFromTable(@"Spelling and Grammar", @"mainmenu", nil);
      self.showSpellingGrammarLabel = NSLocalizedStringFromTable(@"Show Spelling and Grammar", @"mainmenu", nil);
      self.checkDocumentNowLabel = NSLocalizedStringFromTable(@"Check Document Now", @"mainmenu", nil);
      self.checkSpellingWhileTypingLabel = NSLocalizedStringFromTable(@"Check Spelling While Typing", @"mainmenu", nil);
      self.checkGrammarWithSpelling = NSLocalizedStringFromTable(@"Check Grammar With Spelling", @"mainmenu", nil);
      self.correctSpellingAutomatically = NSLocalizedStringFromTable(@"Correct Spelling Automatically", @"mainmenu", nil);
      
      self.substitutionsMenuLabel = NSLocalizedStringFromTable(@"Substitutions", @"mainmenu", nil);
      self.showSubstitutionsLabel = NSLocalizedStringFromTable(@"Show Substitutions", @"mainmenu", nil);
      self.smartCopyPasteLabel = NSLocalizedStringFromTable(@"Smart Copy/Paste", @"mainmenu", nil);
      self.smartQuotesLabel = NSLocalizedStringFromTable(@"Smart Quotes", @"mainmenu", nil);
      self.smartDashesLabel = NSLocalizedStringFromTable(@"Smart Dashes", @"mainmenu", nil);
      self.smartLinksLabel = NSLocalizedStringFromTable(@"Smart Links", @"mainmenu", nil);
      self.dataDetectorsLabel = NSLocalizedStringFromTable(@"Data Detectors", @"mainmenu", nil);
      self.textReplacementLabel = NSLocalizedStringFromTable(@"Text Replacement", @"mainmenu", nil);
      
      self.transformationsMenuLabel = NSLocalizedStringFromTable(@"Transformations", @"mainmenu", nil);
      self.makeUpperCaseLabel = NSLocalizedStringFromTable(@"Make Upper Case", @"mainmenu", nil);
      self.makeLowerCaseLabel = NSLocalizedStringFromTable(@"Make Lower Case", @"mainmenu", nil);
      self.capitalizeLabel = NSLocalizedStringFromTable(@"Capitalize", @"mainmenu", nil);

      self.speechMenuLabel = NSLocalizedStringFromTable(@"Speech", @"mainmenu", nil);
      self.startSpeaking = NSLocalizedStringFromTable(@"Start Speaking", @"mainmenu", nil);
      self.stopSpeaking = NSLocalizedStringFromTable(@"Stop Speaking", @"mainmenu", nil);
      
      self.windowMenuLabel = NSLocalizedStringFromTable(@"Window", @"mainmenu", nil);
      self.minimizeLabel = NSLocalizedStringFromTable(@"Minimize", @"mainmenu", nil);
      self.zoomLabel = NSLocalizedStringFromTable(@"Zoom", @"mainmenu", nil);
      self.closeLabel = NSLocalizedStringFromTable(@"Close", @"mainmenu", nil);
      self.bringAllToFrontLabel = NSLocalizedStringFromTable(@"Bring All to Front", @"mainmenu", nil);
      
      self.helpMenuLabel = NSLocalizedStringFromTable(@"Help", @"mainmenu", nil);
      self.appHelpLabel = [NSString stringWithFormat:NSLocalizedStringFromTable(@"%@ Help", @"mainmenu", nil), appName];
   }
   return self;
}

- (void)dealloc {
   [appMenuLabel release];
   [aboutAppLabel release];
   [preferencesLabel release];
   [servicesMenuLabel release];
   [hideAppLabel release];
   [hideOthersLabel release];
   [showAllLabel release];
   [quitAppLabel release];
   
   [editMenuLabel release];
   [undoLabel release];
   [redoLabel release];
   [cutLabel release];
   [theCopyLabel release];
   [pasteLabel release];
   [pasteAndMatchLabel release];
   [deleteLabel release];
   [selectAllLabel release];
   
   [findMenuLabel release];
   [findLabel release];
   [findAndReplaceLabel release];
   [findNextLabel release];
   [findPreviousLabel release];
   [useSelectionForFindLabel release];
   [jumpToSelectionLabel release];
   
   [spellingGrammarMenuLabel release];
   [showSpellingGrammarLabel release];
   [checkDocumentNowLabel release];
   [checkSpellingWhileTypingLabel release];
   [checkGrammarWithSpelling release];
   [correctSpellingAutomatically release];
   
   [substitutionsMenuLabel release];
   [showSubstitutionsLabel release];
   [smartCopyPasteLabel release];
   [smartQuotesLabel release];
   [smartDashesLabel release];
   [smartLinksLabel release];
   [dataDetectorsLabel release];
   [textReplacementLabel release];
   
   [transformationsMenuLabel release];
   [makeUpperCaseLabel release];
   [makeLowerCaseLabel release];
   [capitalizeLabel release];
   
   [speechMenuLabel release];
   [startSpeaking release];
   [stopSpeaking release];

   [windowMenuLabel release];
   [minimizeLabel release];
   [zoomLabel release];
   [closeLabel release];
   [bringAllToFrontLabel release];
   
   [helpMenuLabel release];
   [appHelpLabel release];
   [super dealloc];
}

- (BOOL)paused
{
    return [[GrowlPreferencesController sharedController] squelchMode];
}

- (BOOL)allowsIncomingNetwork
{
   return [[GrowlPreferencesController sharedController] isGrowlServerEnabled];
}

- (BOOL)forwardingEnabled {
   return [[GrowlPreferencesController sharedController] isForwardingEnabled];
}

- (BOOL)subscriptionAllowed {
   return [[GrowlPreferencesController sharedController] isSubscriptionAllowed];
}

- (IBAction)orderFrontStandardAboutPanel:(id)sender
{
   [[GrowlApplicationController sharedController] showPreferences];
   [[GrowlPreferencesController sharedController] setSelectedPreferenceTab:6];
}

- (IBAction)openPreferences:(id)sender
{
   [[GrowlApplicationController sharedController] showPreferences];
}

- (IBAction)showHelp:(id)sender
{
   [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://growl.info/documentation.php"]];
}

@end
