//
//  CFGrowlAdditions.h
//  Growl
//
//  Created by Mac-arena the Bored Zo on Wed Jun 18 2004.
//  Copyright 2005 The Growl Project.
//

#ifdef __OBJC__
#	define DICTIONARY_TYPE NSDictionary *
#	define STRING_TYPE NSString *
#	define ARRAY_TYPE NSArray *
#	define URL_TYPE NSURL *
#else
#	define DICTIONARY_TYPE CFDictionaryRef
#	define STRING_TYPE CFStringRef
#	define ARRAY_TYPE CFArrayRef
#	define URL_TYPE CFURLRef
#endif

STRING_TYPE _copyCurrentProcessName(void);
URL_TYPE    _copyCurrentProcessURL(void);
STRING_TYPE _copyCurrentProcessPath(void);

STRING_TYPE _copyTemporaryFolderPath(void);

DICTIONARY_TYPE _createDockDescriptionForURL(URL_TYPE url);
