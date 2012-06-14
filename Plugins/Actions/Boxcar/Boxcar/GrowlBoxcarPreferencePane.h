//
//  GrowlBoxcarPreferencePane.h
//  Boxcar
//
//  Created by Daniel Siemer on 3/19/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import <GrowlPlugins/GrowlPluginPreferencePane.h>

@interface GrowlBoxcarPreferencePane : GrowlPluginPreferencePane <NSURLConnectionDelegate>

@property (nonatomic, retain) NSString *errorMessage;
@property (nonatomic) BOOL validating;

-(NSString*)emailAddress;
-(void)setEmailAddress:(NSString*)newAddress;
-(NSString*)prefixString;
-(void)setPrefixString:(NSString *)newPrefix;
-(BOOL)usePrefix;
-(void)setUsePrefix:(BOOL)prefix;
-(BOOL)pushIdle;
-(void)setPushIdle:(BOOL)push;
-(BOOL)usePriority;
-(void)setUsePriority:(BOOL)use;
-(int)minPriority;
-(void)setMinPriority:(int)min;

@end
