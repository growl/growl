//
//  NSStringAdditions.m
//  Growl
//
//  Created by Ingmar Stein on 16.05.05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "NSStringAdditions.h"
#include <arpa/inet.h>
#include <netdb.h>
#import "NSMutableStringAdditions.h"

#import <SystemConfiguration/SCDynamicStoreCopySpecific.h>

@implementation NSString (GrowlAdditions)

- (unsigned long) unsignedLongValue {
	return strtoul([self UTF8String], /*endptr*/ NULL, /*base*/ 0);
}

- (unsigned) unsignedIntValue {
	return (unsigned int)[self unsignedLongValue];
}

- (BOOL) isSubpathOf:(NSString *)superpath {
	NSString *canonicalSuperpath = [superpath stringByStandardizingPath];
	NSString *canonicalSubpath = [self stringByStandardizingPath];
	return [canonicalSubpath isEqualToString:canonicalSuperpath]
		|| [canonicalSubpath hasPrefix:[canonicalSuperpath stringByAppendingString:@"/"]];
}

- (BOOL)Growl_isLikelyDomainName
{
	NSUInteger length = [self length];
	NSString *lowerSelf = [self lowercaseString];
	if (length > 3 &&
       [self rangeOfString:@"." options:NSLiteralSearch].location != NSNotFound) {
		static NSArray *TLD2 = nil;
		static NSArray *TLD3 = nil;
		static NSArray *TLD4 = nil;
		if (!TLD2) {
			TLD2 = [[NSArray arrayWithObjects:@".ac", @".ad", @".ae", @".af", @".ag", @".ai", @".al", @".am", @".an", @".ao", @".aq", @".ar", @".as", @".at", @".au", @".aw", @".az", @".ba", @".bb", @".bd", @".be", @".bf", @".bg", @".bh", @".bi", @".bj", @".bm", @".bn", @".bo", @".br", @".bs", @".bt", @".bv", @".bw", @".by", @".bz", @".ca", @".cc", @".cd", @".cf", @".cg", @".ch", @".ci", @".ck", @".cl", @".cm", @".cn", @".co", @".cr", @".cu", @".cv", @".cx", @".cy", @".cz", @".de", @".dj", @".dk", @".dm", @".do", @".dz", @".ec", @".ee", @".eg", @".eh", @".er", @".es", @".et", @".eu", @".fi", @".fj", @".fk", @".fm", @".fo", @".fr", @".ga", @".gd", @".ge", @".gf", @".gg", @".gh", @".gi", @".gl", @".gm", @".gn", @".gp", @".gq", @".gr", @".gs", @".gt", @".gu", @".gw", @".gy", @".hk", @".hm", @".hn", @".hr", @".ht", @".hu", @".id", @".ie", @".il", @".im", @".in", @".io", @".iq", @".ir", @".is", @".it", @".je", @".jm", @".jo", @".jp", @".ke", @".kg", @".kh", @".ki", @".km", @".kn", @".kp", @".kr", @".kw", @".ky", @".kz", @".la", @".lb", @".lc", @".li", @".lk", @".lr", @".ls", @".lt", @".lu", @".lv", @".ly", @".ma", @".mc", @".md", @".me", @".mg", @".mh", @".mk", @".ml", @".mm", @".mn", @".mo", @".mp", @".mq", @".mr", @".ms", @".mt", @".mu", @".mv", @".mw", @".mx", @".my", @".mz", @".na", @".nc", @".ne", @".nf", @".ng", @".ni", @".nl", @".no", @".np", @".nr", @".nu", @".nz", @".om", @".pa", @".pe", @".pf", @".pg", @".ph", @".pk", @".pl", @".pm", @".pn", @".pr", @".ps", @".pt", @".pw", @".py", @".qa", @".re", @".ro", @".ru", @".rw", @".sa", @".sb", @".sc", @".sd", @".se", @".sg", @".sh", @".si", @".sj", @".sk", @".sl", @".sm", @".sn", @".so", @".sr", @".st", @".sv", @".sy", @".sz", @".tc", @".td", @".tf", @".tg", @".th", @".tj", @".tk", @".tm", @".tn", @".to", @".tp", @".tr", @".tt", @".tv", @".tw", @".tz", @".ua", @".ug", @".uk", @".um", @".us", @".uy", @".uz", @".va", @".vc", @".ve", @".vg", @".vi", @".vn", @".vu", @".wf", @".ws", @".ye", @".yt", @".yu", @".za", @".zm", @".zw", nil] retain];
			TLD3 = [[NSArray arrayWithObjects:@".com",@".edu",@".gov",@".int",@".mil",@".net",@".org",@".biz",@".",@".pro",@".cat", nil] retain];
			TLD4 = [[NSArray arrayWithObjects:@".info",@".aero",@".coop",@".mobi",@".jobs",@".arpa", nil] retain];
		}
		if ([TLD2 containsObject:[lowerSelf substringFromIndex:length-3]] ||
          (length > 4 && [TLD3 containsObject:[lowerSelf substringFromIndex:length-4]]) ||
          (length > 5 && [TLD4 containsObject:[lowerSelf substringFromIndex:length-5]]) ||
          [lowerSelf hasSuffix:@".museum"] || [lowerSelf hasSuffix:@".travel"]) {
			return YES;
		} else {
			return NO;
		}
	}
	
	return NO;
}

- (BOOL)Growl_isLikelyIPAddress
{
    void * ipV4;
    void * ipV6;
   if(inet_pton(AF_INET, [self cStringUsingEncoding:NSUTF8StringEncoding], &ipV4) == 1 ||
      inet_pton(AF_INET6, [self cStringUsingEncoding:NSUTF8StringEncoding], &ipV6) == 1)
      return YES;
   else
      return NO;
}

- (BOOL)isLocalHost
{
    NSString *hostName = (NSString*)SCDynamicStoreCopyLocalHostName(NULL);
    [hostName autorelease];
    if ([hostName hasSuffix:@".local"]) {
		hostName = [hostName substringToIndex:([hostName length] - [@".local" length])];
	}
	if ([self isEqualToString:@"127.0.0.1"] || 
        [self isEqualToString:@"::1"] || 
        [self isEqualToString:@"0:0:0:0:0:0:0:1"] ||
        [self caseInsensitiveCompare:@"localhost"] == NSOrderedSame ||
        [self caseInsensitiveCompare:hostName] == NSOrderedSame)
		return YES;
	else {
		return NO;
	}
}

+(NSString*)stringWithAddressData:(NSData*)aAddressData {
	struct sockaddr *socketAddress = (struct sockaddr *)[aAddressData bytes];
	char stringBuffer[INET6_ADDRSTRLEN];
	NSString* addressAsString = nil;
	if (socketAddress->sa_family == AF_INET) {
		struct sockaddr_in *ipv4 = (struct sockaddr_in *)socketAddress;
		if (inet_ntop(AF_INET, &(ipv4->sin_addr), stringBuffer, INET6_ADDRSTRLEN))
         addressAsString = [NSString stringWithFormat:@"%s:%d", stringBuffer, ipv4->sin_port];
		else
			addressAsString = @"IPv4 un-ntopable";
	} else if (socketAddress->sa_family == AF_INET6) {
		struct sockaddr_in6 *ipv6 = (struct sockaddr_in6 *)socketAddress;
		if (inet_ntop(AF_INET6, &(ipv6->sin6_addr), stringBuffer, INET6_ADDRSTRLEN))
			// Suggested IPv6 format (see http://www.faqs.org/rfcs/rfc2732.html)
         addressAsString = [NSString stringWithFormat:@"[%s]:%d", stringBuffer, ipv6->sin6_port ];
		else
			addressAsString = @"IPv6 un-ntopable";
	} else
		addressAsString = @"neither IPv6 nor IPv4";
   
	return addressAsString;
}

+(NSString*)hostNameForAddressData:(NSData *)aAddressData {
	char hostname[NI_MAXHOST];
	struct sockaddr *socketAddress = (struct sockaddr *)[aAddressData bytes];
	if (getnameinfo(socketAddress, (socklen_t)[aAddressData length],
                   hostname, (socklen_t)sizeof(hostname),
                   /*serv*/ NULL, /*servlen*/ 0,
                   NI_NAMEREQD))
		return nil;
	else
      return [NSString stringWithCString:hostname encoding:NSASCIIStringEncoding];
}

- (NSString*)stringByEscapingForHTML
{
    return [[[self mutableCopy] escapeForHTML] autorelease];
}

@end