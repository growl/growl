#include "GetMetadataForFile.h"
#include <CoreServices/CoreServices.h> 
#include <GrowlDefines.h>

/* -----------------------------------------------------------------------------
    Get metadata attributes from file
   
   This function's job is to extract useful information your file format supports
   and return it as a dictionary
   ----------------------------------------------------------------------------- */

Boolean GetMetadataForFile(void *thisInterface,
			   CFMutableDictionaryRef attributes,
			   CFStringRef contentTypeUTI,
			   CFStringRef pathToFile)
{
	Boolean success;
	CFURLRef ticketURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, pathToFile, kCFURLPOSIXPathStyle, /*isDirectory*/ false);
	CFReadStreamRef stream = CFReadStreamCreateWithFile(kCFAllocatorDefault, ticketURL);
	CFReadStreamOpen(stream);
	CFPropertyListFormat format;
	CFStringRef errorString = NULL;
	CFPropertyListRef ticket = CFPropertyListCreateFromStream(kCFAllocatorDefault,
													 stream,
													 /*streamLength*/ 0,
													 kCFPropertyListImmutable,
													 &format,
													 &errorString
													 );
	if (errorString) {
		//NSLog(CFSTR("GrowlImporter: Error importing ticket from URL %@: %@"), ticketURL, errorString);
		success = FALSE;
	} else {
		const void *value;
		value = CFDictionaryGetValue(ticket, GROWL_APP_NAME);
		if (value) {
			CFDictionarySetValue(attributes, kMDItemTitle, value);
		}
		value = CFDictionaryGetValue(ticket, GROWL_TICKET_VERSION);
		if (value) {
			CFDictionarySetValue(attributes, kMDItemVersion, value);
		}
		success = TRUE;
	}
	CFRelease(ticket);
	CFReadStreamClose(stream);
	CFRelease(stream);
	CFRelease(ticketURL);

    return success;
}
