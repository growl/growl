//
//  GrowlMusicVideoWindowController.h
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import <GrowlPlugins/GrowlDisplayWindowController.h>

@class GrowlMusicVideoWindowView;

@interface GrowlMusicVideoWindowController : GrowlDisplayWindowController {
	CGFloat						frameHeight;
	CGFloat						frameY;
	NSInteger					priority;
	BOOL						doFadeIn;
}

@end
