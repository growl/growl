//
//  GrowlMailPreferencesModule.h
//  GrowlMail
//
//  Created by Ingmar Stein on 29.10.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NSPreferencesModule.h>

@interface GrowlMailPreferencesModule : NSPreferencesModule
{
	IBOutlet NSButton *enabledButton;
	IBOutlet NSButton *junkButton;
	IBOutlet NSButton *summaryButton;
	IBOutlet NSTableView *accountsView;
}
- (IBAction)toggleEnable:(id)sender;
- (IBAction)toggleIgnoreJunk:(id)sender;
- (IBAction)toggleShowSummary:(id)sender;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;

@end
