//
//  NSFileManager+Authentication.h
//  Growl
//
//  Based on code from Sparkle, which is distributed under the Modified BSD license.
//
//  Created by Andy Matuschak on 3/9/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//

@interface NSFileManager (SUAuthenticationAdditions)
- (BOOL)deletePathWithAuthentication:(NSString *)path;
@end
