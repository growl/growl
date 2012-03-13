//
//  GrowlCompoundActionPreferencePane.h
//  Growl
//
//  Created by Daniel Siemer on 3/7/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlPluginPreferencePane.h"

@interface GrowlCompoundActionPreferencePane : GrowlPluginPreferencePane

@property (nonatomic, assign) IBOutlet NSArrayController *chosenArrayController;
@property (nonatomic, assign) IBOutlet NSArrayController *availableArrayController;
@property (nonatomic, assign) IBOutlet NSWindow *addWindow;

@end
