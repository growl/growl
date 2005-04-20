//
//  RRGrowlMenu.h
//  
//

#import <Foundation/Foundation.h>
#import "SystemUIPlugin.h"
#import "GrowlPreferences.h"

@interface GrowlMenu : NSMenuExtra {
    NSMenu				*menu;

    NSImage				*img;
    NSImage				*altImg;

	GrowlPreferences	*preferences;
}

- (NSMenu *) buildMenu;
- (void) clearMenu:(NSMenu *)menu;

//Boolean IsOptionDown( void );
@end
