//
//  NSWindowAdditions.h
//  Growl
//
//  Created by Ofri Wolfus on 21/08/05.
//  Copyright 2005 Ofri Wolfus. All rights reserved.
//

#import <AppKit/NSWindow.h>


@interface NSWindow (GrowlAdditions)

- (NSPoint)frameOrigin;
- (NSSize)frameSize;

@end
