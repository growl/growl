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
}
- (IBAction)toggleEnable:(id)sender;
- (IBAction)toggleIgnoreJunk:(id)sender;

@end
