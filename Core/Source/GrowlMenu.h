//
//  GrowlMenu.h
//  
//

#import <Foundation/Foundation.h>
#import "SystemUIPlugin.h"

@class GrowlPreferences;

@interface GrowlMenu : NSMenuExtra {
	GrowlPreferences	*preferences;
}

- (IBAction) openGrowl:(id)sender;
- (IBAction) defaultDisplay:(id)sender;
- (IBAction) stopGrowl:(id)sender;
- (IBAction) startGrowl:(id)sender;
- (NSMenu *) buildMenu;
- (BOOL) validateMenuItem:(NSMenuItem *)item;
@end
