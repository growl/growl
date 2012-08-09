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

#include <netinet/in.h>
#include <arpa/inet.h>
#include <ifaddrs.h>

@implementation GrowlNetworkUtilities

+(NSArray*)routableIPAddresses {
	NSMutableArray *addresses = nil;
	struct ifaddrs *interfaces = NULL;
   struct ifaddrs *current = NULL;
   
   if(getifaddrs(&interfaces) == 0)
   {
      current = interfaces;
      while (current != NULL) {
         NSString *currentString = nil;
         
         NSString *interface = [NSString stringWithUTF8String:current->ifa_name];
         
         if(![interface isEqualToString:@"lo0"] && ![interface isEqualToString:@"utun0"])
         {
            if (current->ifa_addr->sa_family == AF_INET) {
               char stringBuffer[INET_ADDRSTRLEN];
               struct sockaddr_in *ipv4 = (struct sockaddr_in *)current->ifa_addr;
               if (inet_ntop(AF_INET, &(ipv4->sin_addr), stringBuffer, INET_ADDRSTRLEN))
                  currentString = [NSString stringWithFormat:@"%s", stringBuffer];
            } else if (current->ifa_addr->sa_family == AF_INET6) {
               char stringBuffer[INET6_ADDRSTRLEN];
               struct sockaddr_in6 *ipv6 = (struct sockaddr_in6 *)current->ifa_addr;
               if (inet_ntop(AF_INET6, &(ipv6->sin6_addr), stringBuffer, INET6_ADDRSTRLEN))
                  currentString = [NSString stringWithFormat:@"%s", stringBuffer];
            }          
            
            if(currentString && ![currentString isLocalHost]){
					if(!addresses)
						addresses = [NSMutableArray array];
					[addresses addObject:currentString];
            }
         }
         
         current = current->ifa_next;
      }
   }
   freeifaddrs(interfaces);
	return [[addresses copy] autorelease];
}

+(NSString*)getPrimaryIPOfType:(NSString*)type fromStore:(SCDynamicStoreRef)dynStore
{
   NSString *returnIP = nil;
   NSString *primaryKey = [NSString stringWithFormat:@"State:/Network/Global/%@", type];
   CFDictionaryRef newValue = SCDynamicStoreCopyValue(dynStore, (CFStringRef)primaryKey);
   if (newValue) {
		//Get a key to look up the actual IPv4 info in the dynStore
		NSString *ipKey = [NSString stringWithFormat:@"State:/Network/Interface/%@/%@",
								 [(NSDictionary*)newValue objectForKey:@"PrimaryInterface"], type];
		CFDictionaryRef ipInfo = SCDynamicStoreCopyValue(dynStore, (CFStringRef)ipKey);
		if (ipInfo) {
			CFArrayRef addrs = CFDictionaryGetValue(ipInfo, CFSTR("Addresses"));
			if (addrs && CFArrayGetCount(addrs)) {
				CFStringRef ip = CFArrayGetValueAtIndex(addrs, 0);
				returnIP = [NSString stringWithString:(NSString*)ip];
			}
			CFRelease(ipInfo);
		}
      CFRelease(newValue);
	}   
   return returnIP;
}

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
            struct sockaddr_in *inAddr4 = (struct sockaddr_in *)addrX;
				struct sockaddr_in addr4;
				memset(&addr4, 0, sizeof(addr4));
            addr4.sin_len = sizeof(struct sockaddr_in);
            addr4.sin_family = AF_INET;
            addr4.sin_addr.s_addr = inAddr4->sin_addr.s_addr;
				addr4.sin_port = htons(port);
            result = [NSData dataWithBytes:&addr4 length:sizeof(addr4)];
         }
		}
		else if (addrX->sa_family == AF_INET6)
		{
			if ([original length] >= sizeof(struct sockaddr_in6))
			{
				struct sockaddr_in6 *inAddr6 = (struct sockaddr_in6 *)addrX;
				struct sockaddr_in6 addr6;
				memset(&addr6, 0, sizeof(addr6));
            addr6.sin6_len = sizeof(struct sockaddr_in6);
            addr6.sin6_family = AF_INET6;
            addr6.sin6_addr = inAddr6->sin6_addr;
				addr6.sin6_port = htons(port);
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
				/* DNS lookup success! Make a copy, as releasing host will deallocate it. */
            NSData *result = [[[addresses objectAtIndex:0] copy] autorelease];
            CFRelease(host);
            result = [[[self addressData:result coercedToPort:GROWL_TCP_PORT] copy] autorelease];
				return result;
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
	
    /* Making a copy appears to be necessary, just like for CFNetServiceGetAddressing() */
	return [[[addresses objectAtIndex:0] copy] autorelease];
}

@end
