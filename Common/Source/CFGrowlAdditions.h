//
//  CFGrowlAdditions.h
//  Growl
//
//  Created by Mac-arena the Bored Zo on Wed Jun 18 2004.
//  Copyright 2005 The Growl Project.
//

#ifdef __OBJC__
#	define DATA_TYPE NSData *
#	define DICTIONARY_TYPE NSDictionary *
#	define STRING_TYPE NSString *
#	define ARRAY_TYPE NSArray *
#	define URL_TYPE NSURL *
#else
#	define DATA_TYPE CFDataRef
#	define DICTIONARY_TYPE CFDictionaryRef
#	define STRING_TYPE CFStringRef
#	define ARRAY_TYPE CFArrayRef
#	define URL_TYPE CFURLRef
#endif

STRING_TYPE copyCurrentProcessName(void);
URL_TYPE    copyCurrentProcessURL(void);
STRING_TYPE copyCurrentProcessPath(void);

STRING_TYPE copyTemporaryFolderPath(void);

DICTIONARY_TYPE createDockDescriptionForURL(URL_TYPE url);

/*	@function	copyIconDataForPath
 *	@param	path	The POSIX path to the file or folder whose icon you want.
 *	@result	The icon data, in IconFamily format (same as used in the 'icns' resource and in .icns files).
 */
DATA_TYPE copyIconDataForPath(STRING_TYPE path);
/*	@function	copyIconDataForURL
 *	@param	URL	The URL to the file or folder whose icon you want.
 *	@result	The icon data, in IconFamily format (same as used in the 'icns' resource and in .icns files).
 */
DATA_TYPE copyIconDataForURL(URL_TYPE URL);
