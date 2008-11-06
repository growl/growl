//
//  GrowlApplicationAdditions.h
//  Growl
//
//  Created by Evan Schoenberg on 11/5/08.//

#import <Cocoa/Cocoa.h>

@interface NSApplication (GrowlApplicationAdditions)

- (void)getSystemVersionMajor:(unsigned *)major
                        minor:(unsigned *)minor
                       bugFix:(unsigned *)bugFix;

@end
