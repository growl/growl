#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "iTunes.h"
#import <Growl/Growl.h>


@interface AppDelegate : NSObject <GrowlApplicationBridgeDelegate>

@property(strong) IBOutlet NSMenu* statusItemMenu;

- (IBAction)quitGrowlTunes:(id)sender;

- (void)createStatusItem;

- (void)notifyWithTitle:(NSString*)title
            description:(NSString*)description
                   name:(NSString*)name
                   icon:(NSData*)icon;

@end
