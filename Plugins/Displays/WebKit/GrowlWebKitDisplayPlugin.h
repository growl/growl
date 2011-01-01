//
//  GrowlWebKitDisplayPlugin.h
//  Growl
//
//  Created by JKP on 13/11/2005.
//	Copyright 2005–2011 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlDisplayPlugin.h"

@interface GrowlWebKitDisplayPlugin : GrowlDisplayPlugin {
	NSString    *style;
}

- (id) initWithStyleBundle:(NSBundle *)styleBundle;

@end
