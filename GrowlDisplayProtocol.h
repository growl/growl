//
//  GrowlDisplayProtocol.h
//  Growl
//
//  Created by Vinay Venkatesh on 9/7/04.
//

@protocol GrowlDisplayProtocol

// This does the actual loading of the plugin.
- (void) loadPlugin;
- (void) unloadPlugin;

// This does the actual displaying.
- (void) displayNotificationWithInfo:(NSDictionary *) noteDict;

// Returns the view to show for the prefs in the pref pane.  The frame of this view should be:
// (165., 20., 354., 311.) (in x, y, w, h form)  This is so that it fits properly.  Please do not
// have a tableview in this form.  If you need more space, then you are making it too complicated :P
// Seriously though, we'll figur eout how to deal with it when we come up against it.
- (NSView*) prefView;

// Don't know if I need this yet.
- (id)prefController;

// These functions are combines into one...
//- (NSString *) author;
//- (NSString *) name;
//- (NSString *) userDescription;
//- (NSString *) version;
// Which contains all of the information with the keys of the same name. 
- (NSDictionary*) pluginInfo;

@end
