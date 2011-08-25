//
//  CFGrowlAdditions.c
//  Growl
//
//  Created by Mac-arena the Bored Zo on Wed Jun 18 2004.
//  Copyright 2005-2006 The Growl Project.
//
// This file is under the BSD License, refer to License.txt for details

#include <Carbon/Carbon.h>
#include <unistd.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include "CFGrowlAdditions.h"

#ifndef MIN
# define MIN(a,b) ((a) < (b) ? (a) : (b))
#endif

extern Boolean CFStringGetFileSystemRepresentation() __attribute__((weak_import));
extern CFIndex CFStringGetMaximumSizeOfFileSystemRepresentation(CFStringRef string) __attribute__((weak_import));

char *createFileSystemRepresentationOfString(CFStringRef str) {
	char *buffer;
    CFIndex size = CFStringGetMaximumSizeOfFileSystemRepresentation(str);
    buffer = malloc(size);
    CFStringGetFileSystemRepresentation(str, buffer, size);
	return buffer;
}

NSString *createStringWithDate(CFDateRef date) {
	CFLocaleRef locale = CFLocaleCopyCurrent();
	CFDateFormatterRef dateFormatter = CFDateFormatterCreate(kCFAllocatorDefault,
															 locale,
															 kCFDateFormatterMediumStyle,
															 kCFDateFormatterMediumStyle);
	CFRelease(locale);
	CFStringRef dateString = CFDateFormatterCreateStringWithDate(kCFAllocatorDefault,
																 dateFormatter,
																 date);
	CFRelease(dateFormatter);
	return dateString;
}

NSString *createStringWithContentsOfFile(CFStringRef filename, CFStringEncoding encoding) {
	CFStringRef str = NULL;

	char *path = createFileSystemRepresentationOfString(filename);
	if (path) {
		FILE *fp = fopen(path, "rb");
		if (fp) {
			fseek(fp, 0, SEEK_END);
			unsigned long size = ftell(fp);
			fseek(fp, 0, SEEK_SET);
			unsigned char *buffer = malloc(size);
			if (buffer && fread(buffer, 1, size, fp) == size)
				str = CFStringCreateWithBytes(kCFAllocatorDefault, buffer, size, encoding, true);
			fclose(fp);
		}
		free(path);
	}

	return str;
}

NSString *createStringWithStringAndCharacterAndString(NSString *str0, UniChar ch, NSString *str1) {
	CFStringRef cfstr0 = (CFStringRef)str0;
	CFStringRef cfstr1 = (CFStringRef)str1;
	CFIndex len0 = (cfstr0 ? CFStringGetLength(cfstr0) : 0);
	CFIndex len1 = (cfstr1 ? CFStringGetLength(cfstr1) : 0);
	size_t length = (len0 + (ch != 0xffff) + len1);

	UniChar *buf = malloc(sizeof(UniChar) * length);
	size_t i = 0U;

	if (cfstr0) {
		CFStringGetCharacters(cfstr0, CFRangeMake(0, len0), buf);
		i += len0;
	}
	if (ch != 0xffff)
		buf[i++] = ch;
	if (cfstr1)
		CFStringGetCharacters(cfstr1, CFRangeMake(0, len1), &buf[i]);

	return CFStringCreateWithCharactersNoCopy(kCFAllocatorDefault, buf, length, /*contentsDeallocator*/ kCFAllocatorMalloc);
}

char *copyCString(NSString *str, CFStringEncoding encoding) {
	CFIndex size = CFStringGetMaximumSizeForEncoding(CFStringGetLength(str), encoding) + 1;
	char *buffer = calloc(size, 1);
	CFStringGetCString(str, buffer, size, encoding);
	return buffer;
}

NSString *copyCurrentProcessName(void) {
	ProcessSerialNumber PSN = { 0, kCurrentProcess };
	CFStringRef name = NULL;
	OSStatus err = CopyProcessName(&PSN, &name);
	if (err != noErr) {
		NSLog(CFSTR("in copyCurrentProcessName in CFGrowlAdditions: Could not get process name because CopyProcessName returned %li"), (long)err);
		name = NULL;
	}
	return name;
}

NSURL *copyCurrentProcessURL(void) {
	ProcessSerialNumber psn = { 0, kCurrentProcess };
	FSRef fsref;
	CFURLRef URL = NULL;
	OSStatus err = GetProcessBundleLocation(&psn, &fsref);
	if (err != noErr) {
		NSLog(CFSTR("in copyCurrentProcessURL in CFGrowlAdditions: Could not get application location, because GetProcessBundleLocation returned %li\n"), (long)err);
	} else {
		URL = CFURLCreateFromFSRef(kCFAllocatorDefault, &fsref);
	}
	return URL;
}
NSString *copyCurrentProcessPath(void) {
	CFURLRef URL = copyCurrentProcessURL();
	CFStringRef path = CFURLCopyFileSystemPath(URL, kCFURLPOSIXPathStyle);
	CFRelease(URL);
	return path;
}

NSURL *copyTemporaryFolderURL(void) {
	FSRef ref;
	CFURLRef url = NULL;

	OSStatus err = FSFindFolder(kOnAppropriateDisk, kTemporaryFolderType, kCreateFolder, &ref);
	if (err != noErr)
		NSLog(CFSTR("in copyTemporaryFolderPath in CFGrowlAdditions: Could not locate temporary folder because FSFindFolder returned %li"), (long)err);
	else
		url = CFURLCreateFromFSRef(kCFAllocatorDefault, &ref);

	return url;
}
NSString *copyTemporaryFolderPath(void) {
	CFStringRef path = NULL;

	CFURLRef url = copyTemporaryFolderURL();
	if (url) {
		path = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
		CFRelease(url);
	}

	return path;
}

NSData *readFile(const char *filename)
{
	CFDataRef data;
	// read the file into a CFDataRef
	FILE *fp = fopen(filename, "r");
	if (fp) {
		fseek(fp, 0, SEEK_END);
		long dataLength = ftell(fp);
		fseek(fp, 0, SEEK_SET);
		unsigned char *fileData = malloc(dataLength);
		fread(fileData, 1, dataLength, fp);
		fclose(fp);
		data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, fileData, dataLength, kCFAllocatorMalloc);
	} else
		data = NULL;

	return data;
}

NSURL *copyURLForApplication(NSString *appName)
{
	CFURLRef appURL = NULL;
	OSStatus err = LSFindApplicationForInfo(/*inCreator*/  kLSUnknownCreator,
											/*inBundleID*/ NULL,
											/*inName*/     appName,
											/*outAppRef*/  NULL,
											/*outAppURL*/  &appURL);
	return (err == noErr) ? appURL : NULL;
}

NSString *createStringWithAddressData(NSData *aAddressData) {
	struct sockaddr *socketAddress = (struct sockaddr *)CFDataGetBytePtr(aAddressData);
	// IPv6 Addresses are "FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF"
	//      at max, which is 40 bytes (0-terminated)
	// IPv4 Addresses are "255.255.255.255" at max which is smaller
	char stringBuffer[40];
	CFStringRef addressAsString = NULL;
	if (socketAddress->sa_family == AF_INET) {
		struct sockaddr_in *ipv4 = (struct sockaddr_in *)socketAddress;
		if (inet_ntop(AF_INET, &(ipv4->sin_addr), stringBuffer, 40))
			addressAsString = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("%s:%d"), stringBuffer, ipv4->sin_port);
		else
			addressAsString = CFSTR("IPv4 un-ntopable");
	} else if (socketAddress->sa_family == AF_INET6) {
		struct sockaddr_in6 *ipv6 = (struct sockaddr_in6 *)socketAddress;
		if (inet_ntop(AF_INET6, &(ipv6->sin6_addr), stringBuffer, 40))
			// Suggested IPv6 format (see http://www.faqs.org/rfcs/rfc2732.html)
			addressAsString = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("[%s]:%d"), stringBuffer, ipv6->sin6_port);
		else
			addressAsString = CFSTR("IPv6 un-ntopable");
	} else
		addressAsString = CFSTR("neither IPv6 nor IPv4");

	return addressAsString;
}

NSString *createHostNameForAddressData(NSData *aAddressData) {
	char hostname[NI_MAXHOST];
	struct sockaddr *socketAddress = (struct sockaddr *)CFDataGetBytePtr(aAddressData);
	if (getnameinfo(socketAddress, (socklen_t)CFDataGetLength(aAddressData),
					hostname, (socklen_t)sizeof(hostname),
					/*serv*/ NULL, /*servlen*/ 0,
					NI_NAMEREQD))
		return NULL;
	else
		return CFStringCreateWithCString(kCFAllocatorDefault, hostname, kCFStringEncodingASCII);
}

NSData *copyIconDataForPath(NSString *path) {
	CFDataRef data = NULL;

	//false is probably safest, and is harmless when the object really is a directory.
	CFURLRef URL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, path, kCFURLPOSIXPathStyle, /*isDirectory*/ false);
	if (URL) {
		data = copyIconDataForURL(URL);
		CFRelease(URL);
	}

	return data;
}

NSData *copyIconDataForURL(NSURL *URL)
{
	CFDataRef data = NULL;

	if (URL) {
		FSRef ref;
		if (CFURLGetFSRef(URL, &ref)) {
			IconRef icon = NULL;
			SInt16 label_noOneCares;
			OSStatus err = GetIconRefFromFileInfo(&ref,
												  /*inFileNameLength*/ 0U, /*inFileName*/ NULL,
												  kFSCatInfoNone, /*inCatalogInfo*/ NULL,
												  kIconServicesNoBadgeFlag | kIconServicesUpdateIfNeededFlag,
												  &icon,
												  &label_noOneCares);
			if (err != noErr) {
				NSLog(CFSTR("in copyIconDataForURL in CFGrowlAdditions: could not get icon for %@: GetIconRefFromFileInfo returned %li\n"), URL, (long)err);
			} else {
				IconFamilyHandle fam = NULL;
				err = IconRefToIconFamily(icon, kSelectorAllAvailableData, &fam);
				if (err != noErr) {
					NSLog(CFSTR("in copyIconDataForURL in CFGrowlAdditions: could not get icon for %@: IconRefToIconFamily returned %li\n"), URL, (long)err);
				} else {
					HLock((Handle)fam);
					data = CFDataCreate(kCFAllocatorDefault, (const UInt8 *)*(Handle)fam, GetHandleSize((Handle)fam));
					HUnlock((Handle)fam);
					DisposeHandle((Handle)fam);
				}
				ReleaseIconRef(icon);
			}
		}
	}

	return data;
}

NSURL *createURLByMakingDirectoryAtURLWithName(NSURL *parent, NSString *name)
{
	CFURLRef newDirectory = NULL;

	CFAllocatorRef allocator = parent ? CFGetAllocator(parent) : name ? CFGetAllocator(name) : kCFAllocatorDefault;

	if (parent) parent = CFRetain(parent);
	else {
		char *cwdBytes = alloca(PATH_MAX);
		getcwd(cwdBytes, PATH_MAX);
		parent = CFURLCreateFromFileSystemRepresentation(allocator, (const unsigned char *)cwdBytes, strlen(cwdBytes), /*isDirectory*/ true);
		if (!name) {
			newDirectory = parent;
			goto end;
		}
	}
	if (!parent)
		NSLog(CFSTR("in createURLByMakingDirectoryAtURLWithName in CFGrowlAdditions: parent directory URL is NULL (please tell the Growl developers)\n"), parent);
	else {
		if (name)
			name = CFRetain(name);
		else {
			name = CFURLCopyLastPathComponent(parent);
			CFURLRef newParent = CFURLCreateCopyDeletingLastPathComponent(allocator, parent);
			CFRelease(parent);
			parent = newParent;
		}

		if (!name)
			NSLog(CFSTR("in createURLByMakingDirectoryAtURLWithName in CFGrowlAdditions: name of directory to create is NULL (please tell the Growl developers)\n"), parent);
		else {
			FSRef parentRef;
			if (!CFURLGetFSRef(parent, &parentRef))
				NSLog(CFSTR("in createURLByMakingDirectoryAtURLWithName in CFGrowlAdditions: could not create FSRef for parent directory at %@ (please tell the Growl developers)\n"), parent);
			else {
				FSRef newDirectoryRef;

				struct HFSUniStr255 nameUnicode;
				CFRange range = { 0, MIN(CFStringGetLength(name), USHRT_MAX) };
				CFStringGetCharacters(name, range, nameUnicode.unicode);
				nameUnicode.length = range.length;

				struct FSRefParam refPB = {
					.ref              = &parentRef,
					.nameLength       = nameUnicode.length,
					.name             = nameUnicode.unicode,
					.whichInfo        = kFSCatInfoNone,
					.catInfo          = NULL,
					.textEncodingHint = kTextEncodingUnknown,
					.newRef           = &newDirectoryRef,
				};

				OSStatus err = PBCreateDirectoryUnicodeSync(&refPB);
				if (err == dupFNErr) {
					//dupFNErr == file (or folder) exists already. this is fine.
					err = PBMakeFSRefUnicodeSync(&refPB);
				}
				if (err == noErr) {
					NSLog(CFSTR("PBCreateDirectoryUnicodeSync or PBMakeFSRefUnicodeSync returned %li; calling CFURLCreateFromFSRef"), (long)err); //XXX
					newDirectory = CFURLCreateFromFSRef(allocator, &newDirectoryRef);
					NSLog(CFSTR("CFURLCreateFromFSRef returned %@"), newDirectory); //XXX
				} else
					NSLog(CFSTR("in createURLByMakingDirectoryAtURLWithName in CFGrowlAdditions: could not create directory '%@' in parent directory at %@: FSCreateDirectoryUnicode returned %li (please tell the Growl developers)"), name, parent, (long)err);
			}

		} //if (name)
		if(parent)
			CFRelease(parent);
		if(name)
			CFRelease(name);
	} //if (parent)

end:
	return newDirectory;
}

NSURL *createURLByCopyingFileFromURLToDirectoryURL(NSURL *file, NSURL *dest)
{
	CFURLRef destFileURL = NULL;

	FSRef fileRef, destRef, destFileRef;
	Boolean gotFileRef = CFURLGetFSRef(file, &fileRef);
	Boolean gotDestRef = CFURLGetFSRef(dest, &destRef);
	if (!gotFileRef)
		NSLog(CFSTR("in createURLByCopyingFileFromURLToDirectoryURL in CFGrowlAdditions: CFURLGetFSRef failed with source URL %@"), file);
	else if (!gotDestRef)
		NSLog(CFSTR("in createURLByCopyingFileFromURLToDirectoryURL in CFGrowlAdditions: CFURLGetFSRef failed with destination URL %@"), dest);
	else {
		OSStatus err;

        err = FSCopyObjectSync(&fileRef, &destRef, /*destName*/ NULL, &destFileRef, kFSFileOperationOverwrite);
        
		if (err == noErr)
			destFileURL = CFURLCreateFromFSRef(kCFAllocatorDefault, &destFileRef);
		else
			NSLog(CFSTR("in createURLByCopyingFileFromURLToDirectoryURL in CFGrowlAdditions: CopyObjectSync returned %li for source URL %@"), (long)err, file);
	}

	return destFileURL;
}

NSObject *createPropertyListFromURL(NSURL *file, u_int32_t mutability, CFPropertyListFormat *outFormat, NSString **outErrorString)
{
	CFPropertyListRef plist = NULL;

	if (!file)
		NSLog(CFSTR("in createPropertyListFromURL in CFGrowlAdditions: cannot read from a NULL URL"));
	else {
		CFReadStreamRef stream = CFReadStreamCreateWithFile(kCFAllocatorDefault, file);
		if (!stream)
			NSLog(CFSTR("in createPropertyListFromURL in CFGrowlAdditions: could not create stream for reading from URL %@"), file);
		else {
			if (!CFReadStreamOpen(stream))
				NSLog(CFSTR("in createPropertyListFromURL in CFGrowlAdditions: could not open stream for reading from URL %@"), file);
			else {
				CFPropertyListFormat format;
				CFStringRef errorString = NULL;

				plist = CFPropertyListCreateFromStream(kCFAllocatorDefault,
													   stream,
													   /*streamLength*/ 0,
													   mutability,
													   &format,
													   &errorString);
				if (!plist)
					NSLog(CFSTR("in createPropertyListFromURL in CFGrowlAdditions: could not read property list from URL %@ (error string: %@)"), file, errorString);

				if (outFormat) *outFormat = format;
				if (errorString) {
					if (outErrorString)
						*outErrorString = errorString;
					else
						CFRelease(errorString);
				}

				CFReadStreamClose(stream);
			}

			CFRelease(stream);
		}
	}

	return plist;
}
