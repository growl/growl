//
//  NSWorkspaceAdditions.h
//  Growl
//
//  Created by Ingmar Stein on 16.05.05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <Cocoa/Cocoa.h>

@interface NSWorkspace (GrowlAdditions)
- (NSImage *) iconForApplication:(NSString *) inName;

- (BOOL) getFileType:(out NSString **)outFileType creatorCode:(out NSString **)outCreatorCode forURL:(NSURL *)URL;
- (BOOL) getFileType:(out NSString **)outFileType creatorCode:(out NSString **)outCreatorCode forFile:(NSString *)path;

@end
