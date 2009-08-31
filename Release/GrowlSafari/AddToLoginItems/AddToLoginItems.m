#import <Foundation/Foundation.h>
#include <sysexits.h>

int main (int argc, char **argv) {
	int status = EXIT_SUCCESS;

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	LSSharedFileListRef list = (LSSharedFileListRef)[NSMakeCollectable(LSSharedFileListCreate(kCFAllocatorDefault, kLSSharedFileListSessionLoginItems, /*options*/ NULL)) autorelease];

	UInt32 seed = 0U;
	NSArray *existingItems = [NSMakeCollectable(LSSharedFileListCopySnapshot(list, &seed)) autorelease];

	//Drop the first argument, which is argv[0], not an input path.
	NSEnumerator *args = [[[NSProcessInfo processInfo] arguments] objectEnumerator];
	[args nextObject];

	for (NSString *path in args) {
		NSURL *URL = [NSURL fileURLWithPath:path];

		//First, make sure that the item doesn't already exist.
		NSURL *existingURL = nil;
		OSStatus err;
		for (id itemAsObject in existingItems) {
			//These are CFTypes, so this is OK.
			LSSharedFileListItemRef item = (LSSharedFileListItemRef)itemAsObject;

			err = LSSharedFileListItemResolve(item, kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes, (CFURLRef *)&existingURL, /*outRef*/ NULL);
			if (existingURL)
				existingURL = [NSMakeCollectable(existingURL) autorelease];

			if (err == noErr && [existingURL isEqual:URL])
				break;
			else
				existingURL = nil;
		}

		if (existingURL) {
			//No need to add this item, as it's already there.
			continue;
		}

		IconRef icon = NULL;
		FSRef ref;
		if (CFURLGetFSRef((CFURLRef)URL, &ref)) {
			err = GetIconRefFromFileInfo(&ref, /*fileNameLength*/ 0U, /*fileName*/ NULL, kFSCatInfoNone, /*catalogInfo*/ NULL, kIconServicesNormalUsageFlag, &icon, /*outLabel*/ NULL);
			if (err != noErr)
				icon = NULL; //Just in case we received a bogus icon pointer.
		}

		LSSharedFileListItemRef insertedItem = LSSharedFileListInsertItemURL(list,
			kLSSharedFileListItemLast,
			(CFStringRef)[[NSFileManager defaultManager] displayNameAtPath:path],
			icon,
			(CFURLRef)URL,
			/*propertiesToSet*/ (CFDictionaryRef)[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:(id)kLSSharedFileListItemHidden],
			/*propertiesToClear*/ NULL);
		if (!insertedItem)
			status = EX_UNAVAILABLE;

		if (icon)
			ReleaseIconRef(icon);
	}

	[pool drain];
	return status;
}
