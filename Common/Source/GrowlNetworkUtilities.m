//
//  GrowlNetworkUtilities.m
//  Growl
//
//  Created by Daniel Siemer on 11/11/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlNetworkUtilities.h"
#import "NSStringAdditions.h"
#import "GrowlDefinesInternal.h"

#import <SystemConfiguration/SystemConfiguration.h>
#include <netinet/in.h>
#include <arpa/inet.h>

@implementation GrowlNetworkUtilities

+(NSString*)localHostName
{
   NSString *hostname = @"localhost";
   
   CFStringRef cfHostName = SCDynamicStoreCopyLocalHostName(NULL);
   if(cfHostName != NULL){
      hostname = [[(NSString*)cfHostName copy] autorelease];
      CFRelease(cfHostName);
      if ([hostname hasSuffix:@".local"]) {
         hostname = [hostname substringToIndex:([hostname length] - [@".local" length])];
      }
   }
   return hostname;
}

+(NSData*)addressData:(NSData*)original coercedToPort:(NSInteger)port {
   NSData *result = nil;
	if ([original length] >= sizeof(struct sockaddr))
	{
		struct sockaddr *addrX = (struct sockaddr *)[original bytes];
		
		if (addrX->sa_family == AF_INET)
		{
			if ([original length] >= sizeof(struct sockaddr_in))
			{
				struct sockaddr_in *addr4 = (struct sockaddr_in *)addrX;
				
				addr4->sin_port = htons(GROWL_TCP_PORT);
            result = [NSData dataWithBytes:&addr4 length:sizeof(addr4)];
         }
		}
		else if (addrX->sa_family == AF_INET6)
		{
			if ([original length] >= sizeof(struct sockaddr_in6))
			{
				struct sockaddr_in6 *addr6 = (struct sockaddr_in6 *)addrX;
				
            addr6->sin6_port = port;
            result = [NSData dataWithBytes:&addr6 length:sizeof(addr6)];
			}
		}
	}
   
   return result;
}

+ (NSData *)addressDataForGrowlServerOfType:(NSString *)type withName:(NSString *)name withDomain:(NSString*)domain
{
	if ([name hasSuffix:@".local"])
		name = [name substringWithRange:NSMakeRange(0, [name length] - [@".local" length])];
   
	if ([name Growl_isLikelyDomainName]) {
		CFHostRef host = CFHostCreateWithName(kCFAllocatorDefault, (CFStringRef)name);
		CFStreamError error;
		if (CFHostStartInfoResolution(host, kCFHostAddresses, &error)) {
			NSArray *addresses = (NSArray *)CFHostGetAddressing(host, NULL);
			
			if ([addresses count]) {
				/* DNS lookup success! */
            CFRelease(host);
				return [addresses objectAtIndex:0];
			}
		}
		if (host) CFRelease(host);
		
	} else if ([name Growl_isLikelyIPAddress]) {
      struct in_addr addr4;
      struct in6_addr addr6;
      
      if(inet_pton(AF_INET, [name cStringUsingEncoding:NSUTF8StringEncoding], &addr4) == 1){
         struct sockaddr_in serverAddr;
         
         memset(&serverAddr, 0, sizeof(serverAddr));
         serverAddr.sin_len = sizeof(struct sockaddr_in);
         serverAddr.sin_family = AF_INET;
         serverAddr.sin_addr.s_addr = addr4.s_addr;
         serverAddr.sin_port = htons(GROWL_TCP_PORT);
         return [NSData dataWithBytes:&serverAddr length:sizeof(serverAddr)];
      }
      else if(inet_pton(AF_INET6, [name cStringUsingEncoding:NSUTF8StringEncoding], &addr6) == 1){
         struct sockaddr_in6 serverAddr;
         
         memset(&serverAddr, 0, sizeof(serverAddr));
         serverAddr.sin6_len        = sizeof(struct sockaddr_in6);
         serverAddr.sin6_family     = AF_INET6;
         serverAddr.sin6_addr       = addr6;
         serverAddr.sin6_port       = htons(GROWL_TCP_PORT);
         return [NSData dataWithBytes:&serverAddr length:sizeof(serverAddr)];
      }else{
         NSLog(@"No address (shouldnt happen)");
         return nil;
      }
   } 
	
   NSString *machineDomain = domain;
   if(!machineDomain)
      machineDomain = @"local.";
	/* If we make it here, treat it as a computer name on the local network */ 
	NSNetService *service = [[[NSNetService alloc] initWithDomain:machineDomain type:type name:name] autorelease];
	if (!service) {
		/* No such service exists. The computer is probably offline. */
		return nil;
	}
	
	/* Work for 8 seconds to resolve the net service to an IP and port. We should be running
	 * on a background concurrent queue, so blocking is fine.
	 */
	[service scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:@"PrivateGrowlMode"];
	[service resolveWithTimeout:8.0];
	CFAbsoluteTime deadline = CFAbsoluteTimeGetCurrent() + 8.0;
	CFTimeInterval remaining;
	while ((remaining = (deadline - CFAbsoluteTimeGetCurrent())) > 0 && [[service addresses] count] == 0) {
      CFRunLoopRunInMode((CFStringRef)@"PrivateGrowlMode", remaining, TRUE);
	}
	[service stop];
	
	NSArray *addresses = [service addresses];
	if (![addresses count]) {
		/* Lookup failed */
		return nil;
	}
	
	return [addresses objectAtIndex:0];
}

@end
