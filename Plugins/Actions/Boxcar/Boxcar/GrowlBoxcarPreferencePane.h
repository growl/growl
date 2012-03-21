//
//  GrowlBoxcarPreferencePane.h
//  Boxcar
//
//  Created by Daniel Siemer on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <GrowlPlugins/GrowlPluginPreferencePane.h>

@interface GrowlBoxcarPreferencePane : GrowlPluginPreferencePane

-(NSString*)emailAddress;
-(void)setEmailAddress:(NSString*)newAddress;

@end
