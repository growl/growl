#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include <Cocoa/Cocoa.h>
#include <objc/runtime.h>

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	if(QLPreviewRequestIsCancelled(preview))
		return noErr;
	
	NSBundle *pluginBundle = [NSBundle bundleWithPath:[(NSURL*)url path]];
	[pluginBundle load];

	id plugin = [[[[pluginBundle principalClass] alloc] init] autorelease];
	id wc = [[[plugin performSelector:@selector(windowControllerClass)] alloc] initWithWindowNibName:[plugin windowNibName]];
	
	
	NSWindow *window = [wc window];
	NSImage *previewImage = [[NSImage alloc] initWithSize:window.frame.size];
	[previewImage lockFocus];
	[window display];
	[previewImage unlockFocus];
	
	QLPreviewRequestSetDataRepresentation(preview, (CFDataRef)[previewImage TIFFRepresentation], kUTTypeImage, nil);
	[pool drain];
	return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview) {
    // implement only if supported
}
