//
//  GrowlTunes-Amazon.m
//  GrowlTunes-Amazon
//
//  Created by Karl Adam on 9/29/04.
//  Copyright 2004 matrixPointer. All rights reserved.
//

#import "GrowlTunes-Amazon.h"

/* Based On Code Originally submitted by James Van Dyne */

#ifndef MAC_OS_X_VERSION_10_4 > MAC_OS_X_VERSION_MAX_ALLOWED
	int NSXMLDocumentTidyXML = 1 << 10;  //  Correct value goes here.
#endif

@implementation GrowlTunes_Amazon

- (id) init {
	if ( self = [super init] ) {
		// Can't assume we have internet, but we are till someone figures a good test
		weGetInternet = YES;
	}
	return self;
}

- (NSImage *)artworkForTitle:(NSString *)song byArtist:(NSString *)artist onAlbum:(NSString *)album isCompilation:(BOOL)compilation {
	Class XMLDocument = NSClassFromString(@"NSXMLDocument");
	NSImage *artwork = nil;
	NSString *imageURL = nil;
	NSLog( @"Go go interweb" );
	
	NSString *search = [[NSString stringWithFormat:@"http://webservices.amazon.com/onca/xml?Service=AWSProductData&SubscriptionId=1KQJD90W67ZBHT7ZH282&Operation=ItemSearch&SearchIndex=Music&Keywords=%s %s&ResponseGroup=Images", [artist UTF8String],[album UTF8String]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSURL *url = [NSURL URLWithString:search];
	
	if ( XMLDocument ) {			// Tiger
		id testXML = [[[XMLDocument alloc] initWithContentsOfURL:url 
																	   options:NSXMLDocumentTidyXML 
																		 error:NULL] autorelease];
		NSArray *imageArray = [testXML nodesForXPath:@"/ItemSearchResponse[1]/Items[1]/Item/MediumImage[1]/URL[1]" error:NULL];
		if ( [imageArray count] > 0 ) {
			imageURL = [[imageArray objectAtIndex:0] stringValue];
			imageURL = [imageURL substringToIndex:[imageURL length]-1];
			NSLog( @"imageURL(XML) - \"%@\"", imageURL );
		}
	} else {						// Everyone Else
		NSString *xml = [NSString stringWithContentsOfURL:url];
		NSRange open = [xml rangeOfString:@"<MediumImage><URL>"];
		if(open.length != 0) {
			imageURL = [xml substringFromIndex:open.location +open.length];
			
			NSRange close = [imageURL rangeOfString:@"</URL>"];
			imageURL = [imageURL substringToIndex:close.location];
			//NSLog(@"ImageURL(OldStyle): %s",[xml UTF8String]);
		}
	}
	
	if ( imageURL ) {
		artwork = [[[NSImage alloc] initWithData:[NSData dataWithData:[[NSURL URLWithString:imageURL] resourceDataUsingCache:YES]] ] autorelease];
	}
	
	return artwork;
}
@end
