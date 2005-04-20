//
//  RRGrowlMenu.h
//  
//

#import <Foundation/Foundation.h>
#import "SystemUIPlugin.h"

@class GrowlPreferences;

@interface GrowlMenu : NSMenuExtra {
    NSMenu				*menu;

    NSImage				*img;
    NSImage				*altImg;

	GrowlPreferences	*preferences;
}

- (NSMenu *) buildMenu;
@end
