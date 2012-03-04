//
//  GrowlMailMePrefs.h
//  Display Plugins
//
//  Copyright 2004 Peter Hosey. All rights reserved.
//

#import <GrowlPlugins/GrowlPluginPreferencePane.h>

@interface GrowlMailMePrefs: GrowlPluginPreferencePane {
}

@property (nonatomic, retain) NSString *recipientLabel;
@property (nonatomic, assign) IBOutlet NSTextField *emailField;

- (NSString *) getDestAddress;
- (void) setDestAddress:(NSString *)value;

@end
