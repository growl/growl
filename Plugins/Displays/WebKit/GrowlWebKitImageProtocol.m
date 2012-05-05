//
//  GrowlWebKitImageProtocol.m
//  Growl
//
//  Created by Thijs Alkemade on 11-11-11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlWebKitImageProtocol.h"
#include "GrowlWebKitWindowController.h"

@implementation GrowlWebKitImageProtocol

+ (void)registerProtocol
{
	static BOOL isRegistered = FALSE;
	
	if (!isRegistered) {
		[NSURLProtocol registerClass:[GrowlWebKitImageProtocol class]];
		isRegistered = TRUE;
	}
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)theRequest
{
	NSString *theScheme = [[theRequest URL] scheme];
	
	return ([theScheme caseInsensitiveCompare:@"growlimage"] == NSOrderedSame);
}

// Subclasses need to implement this, but there's nothing to do there.
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
	return request;
}

- (void)startLoading
{
   NSData *iconData = nil;
	
	/* Get the image data from the cache.
	 * We use the thread safe accessors in GrowlWebKitWindowController for getting the icon
	 */
   		
   iconData = [GrowlWebKitWindowController cachedImageForKey:[self.request.URL absoluteString]];
               
   /* In case it gets dropped from the cache before it is finished here.
    * (That probably means the view is gone too, but just in case).
    */
   [iconData retain];
	
	if (!iconData) {
		
		// No point in continuing if we can't find the image.
		NSLog(@"Image %@ was not found in the cache.", self.request);
		
        [self.client URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain
                                                                           code:NSURLErrorResourceUnavailable userInfo:nil]];
		
		return;
	}
	
	NSURLResponse *response = [[NSURLResponse alloc] initWithURL:self.request.URL
														MIMEType:@"" // Probably TIFF, but it doesn't need to be.
										   expectedContentLength:[iconData length]
												textEncodingName:nil];

	/* No need to cache the image in WebKit. Even if the same URL is used again,
	 * it'll probably be a different image.
	 */
	[self.client URLProtocol:self didReceiveResponse:response
		  cacheStoragePolicy:NSURLCacheStorageNotAllowed];
	
	[self.client URLProtocol:self didLoadData:iconData];
	
	[self.client URLProtocolDidFinishLoading:self];
	
	[iconData release];
	[response release];
}

// Nothing we are able to cancel, but subclasses need this method.
- (void)stopLoading
{
	
}

@end
