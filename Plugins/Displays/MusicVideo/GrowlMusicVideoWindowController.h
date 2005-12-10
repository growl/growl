//
//  GrowlMusicVideoWindowController.h
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "GrowlDisplayWindowController.h"

@class GrowlMusicVideoWindowView;

@interface GrowlMusicVideoWindowController : GrowlDisplayWindowController {
	float						frameHeight;
	float						frameY;
	int							priority;
	NSString					*identifier;
	bool							doFadeIn;
	unsigned	depth;
}

- (NSString *) identifier;

@end
