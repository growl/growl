//
//  GrowlSoundActionPreferencePane.h
//  SoundAction
//
//  Created by Daniel Siemer on 3/15/12.
//  Copyright 2012 The Growl Project, LLC. All rights reserved.
//

#import "GrowlPluginPreferencePane.h"

@interface GrowlSoundActionPreferencePane : GrowlPluginPreferencePane <NSTableViewDelegate>

@property (nonatomic, assign) IBOutlet NSTableView	*soundTableView;
@property (nonatomic, retain) NSArray *sounds;

-(void)updateSoundsList;

-(void)setSoundName:(NSString*)soundName;
-(NSString*)soundName;

@end
