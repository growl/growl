//
//  GrowlBonjourBrowser.m
//  Growl
//
//  Created by Daniel Siemer on 12/12/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlBonjourBrowser.h"

@implementation GrowlBonjourBrowser

@synthesize browser;
@synthesize services;

@synthesize browseCount;

+(GrowlBonjourBrowser*)sharedBrowser {
   static GrowlBonjourBrowser *_sharedBrowser;
   static dispatch_once_t onceToken;
   dispatch_once(&onceToken, ^{
      _sharedBrowser = [[self alloc] init];
   });
   return _sharedBrowser;
}

-(BOOL)startBrowsing{
   browseCount++;

   if(!browser){
      NSLog(@"Starting browsing for _gntp._tcp.");
      self.services = [NSMutableArray array];
      browser = [[NSNetServiceBrowser alloc] init];
      [browser setDelegate:self];
      [browser searchForServicesOfType:@"_gntp._tcp." inDomain:@""];
   }
   return YES;
}

-(BOOL)stopBrowsing{
   if(browseCount == 0){
      NSLog(@"WARNING! Attempt to decrement the bonjour browse count when already 0!");
      return YES;
   }
   
   browseCount--;
   if(browseCount == 0){
      NSLog(@"Stopping browsing for _gntp._tcp.");
      [browser stop];
      self.services = nil;
      return YES;
   }
   return NO;
}


#pragma mark NSNetServiceBrowser Delegate Methods

-(void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)netServiceBrowser 
{
   if(browser){
      self.browser = nil;
   }
   [[NSNotificationCenter defaultCenter] postNotificationName:GNTPBrowserStopNotification
                                                       object:self];
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
            didNotSearch:(NSDictionary *)errorDict
{
   if(browser)
      self.browser = nil;
   browseCount = 0;
   NSLog(@"Did not start search for _gntp._tcp; Error Code: %@, Error Domain: %@", [errorDict valueForKey:NSNetServicesErrorCode], [errorDict valueForKey:NSNetServicesErrorDomain]);
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
          didFindService:(NSNetService *)aNetService 
              moreComing:(BOOL)moreComing 
{
   [services addObject:aNetService];
   [[NSNotificationCenter defaultCenter] postNotificationName:GNTPServiceFoundNotification 
                                                       object:self 
                                                     userInfo:[NSDictionary dictionaryWithObject:aNetService 
                                                                                          forKey:GNTPServiceKey]];
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
        didRemoveService:(NSNetService *)aNetService 
              moreComing:(BOOL)moreComing 
{
   [services removeObject:aNetService];
   [[NSNotificationCenter defaultCenter] postNotificationName:GNTPServiceRemovedNotification
                                                       object:self 
                                                     userInfo:[NSDictionary dictionaryWithObject:aNetService 
                                                                                          forKey:GNTPServiceKey]];
}

@end
