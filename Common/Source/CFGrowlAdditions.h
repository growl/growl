//
//  CFGrowlAdditions.h
//  Growl
//
//  Created by Mac-arena the Bored Zo on Wed Jun 18 2004.
//  Copyright 2005-2006 The Growl Project.
//
// This file is under the BSD License, refer to License.txt for details

#ifndef HAVE_CFGROWLADDITIONS_H
#define HAVE_CFGROWLADDITIONS_H

//see GrowlApplicationBridge-Carbon.c for rationale of using NSLog.
extern void NSLog(NSString *format, ...);

char *createFileSystemRepresentationOfString(NSString *str);
NSString *createStringWithDate(NSDate *date);

NSString *createStringWithContentsOfFile(NSString *filename, CFStringEncoding encoding);

//you can leave out any of these three components. to leave out the character, pass 0xffff.
NSString *createStringWithStringAndCharacterAndString(NSString *str0, UniChar ch, NSString *str1);

char *copyCString(NSString *str, CFStringEncoding encoding);

NSString *copyCurrentProcessName(void);
NSURL *   copyCurrentProcessURL(void);
NSString *copyCurrentProcessPath(void);

NSURL *   copyTemporaryFolderURL(void);
NSString *copyTemporaryFolderPath(void);

NSString *createStringWithAddressData(NSData *aAddressData);
NSString *createHostNameForAddressData(NSData *aAddressData);

NSData *readFile(const char *filename);
NSURL * copyURLForApplication(NSString *appName);

/*	@function	copyIconDataForPath
 *	@param	path	The POSIX path to the file or folder whose icon you want.
 *	@result	The icon data, in IconFamily format (same as used in the 'icns' resource and in .icns files). You are responsible for releasing this object.
 */
NSData *copyIconDataForPath(NSString *path);
/*	@function	copyIconDataForURL
 *	@param	URL	The URL to the file or folder whose icon you want.
 *	@result	The icon data, in IconFamily format (same as used in the 'icns' resource and in .icns files). You are responsible for releasing this object.
 */
NSData *copyIconDataForURL(NSURL *URL);

/*	@function	createURLByMakingDirectoryAtURLWithName
 *	@abstract	Create a directory.
 *	@discussion	This function has a useful side effect: if you pass
 *	 <code>NULL</code> for both parameters, this function will act basically as
 *	 CFURL version of <code>getcwd</code>(3).
 *
 *	 Also, for CF clients: the allocator used to create the returned URL will
 *	 be the allocator for the parent URL, the allocator for the name string, or
 *	 the default allocator, in that order of preference.
 *	@param	parent	The directory in which to create the new directory. If this is <code>NULL</code>, the current working directory (as returned by <code>getcwd</code>(3)) will be used.
 *	@param	name	The name of the directory you want to create. If this is <code>NULL</code>, the directory specified by the URL will be created.
 *	@result	The URL for the directory if it was successfully created (in which case, you are responsible for releasing this object); else, <code>NULL</code>.
 */
NSURL *createURLByMakingDirectoryAtURLWithName(NSURL *parent, NSString *name);

/*	@function	createURLByCopyingFileFromURLToDirectoryURL
 *	@param	file	The file to copy.
 *	@param	dest	The folder to copy it to.
 *	@result	The copy. You are responsible for releasing this object.
 */
NSURL *createURLByCopyingFileFromURLToDirectoryURL(NSURL *file, NSURL *dest);

/*	@function	createPropertyListFromURL
 *	@abstract	Reads a property list from the contents of an URL.
 *	@discussion	Creates a property list from the data at an URL (for example, a
 *	 file URL), and returns it.
 *	@param	file	The file to read.
 *	@param	mutability	A mutability-option constant indicating whether the property list (and possibly its contents) should be mutable.
 *	@param	outFormat	If the property list is read successfully, this will point to the format of the property list. You may pass NULL if you are not interested in this information. If the property list is not read successfully, the value at this pointer will be left unchanged.
 *	@param	outErrorString	If an error occurs, this will point to a string (which you are responsible for releasing) describing the error. You may pass NULL if you are not interested in this information. If no error occurs, the value at this pointer will be left unchanged.
 *	@result	The property list. You are responsible for releasing this object.
 */
NSObject *createPropertyListFromURL(NSURL *file, u_int32_t mutability, CFPropertyListFormat *outFormat, NSString **outErrorString);

#endif
