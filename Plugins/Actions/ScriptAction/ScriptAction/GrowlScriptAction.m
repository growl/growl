//
//  GrowlScriptAction.m
//  ScriptAction
//
//  Created by Daniel Siemer on 10/8/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//  

#import "GrowlScriptAction.h"
#import "GrowlScriptActionPreferencePane.h"
#import <GrowlPlugins/GrowlDefines.h>

@implementation GrowlScriptAction

-(id)init{
   if(NSClassFromString(@"NSUserScriptTask") == nil)
      return nil;
   
   if((self = [super init])){
      
   }
   return self;
}

-(BOOL)hasAppleScriptTaskClass {
   return NSClassFromString(@"NSUserAppleScriptTask") != nil;
}
-(NSURL*)baseScriptDirectoryURL {
   NSError *urlError = nil;
   NSURL *baseURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationScriptsDirectory
                                                           inDomain:NSUserDomainMask
                                                  appropriateForURL:nil
                                                             create:YES
                                                              error:&urlError];
   if(urlError){
      static dispatch_once_t onceToken;
      dispatch_once(&onceToken, ^{
         NSLog(@"Error retrieving Application Scripts directoy, %@", urlError);
      });
   }
   return urlError ? nil : baseURL;
}
- (NSUserScriptTask*)scriptTaskForFile:(NSString*)fileName {
   NSUserScriptTask* result = nil;
   if([self hasAppleScriptTaskClass]){
      NSURL *baseURL = [self baseScriptDirectoryURL];
      
      if(baseURL){
         NSError *error = nil;
         NSURL *path = [baseURL URLByAppendingPathComponent:fileName];
         result = [[NSUserScriptTask alloc] initWithURL:path
                                                  error:&error];
         if(error && !result){
            NSLog(@"Error retrieving script task for file %@ - %@", fileName, error);
         }
      }
   }
   return [result autorelease];
}

-(NSAppleEventDescriptor*)notificationDescriptor:(NSDictionary*)dict {
   NSString *host = [dict valueForKey:@"GNTP Notification Sent-By"];
   if(!host /*|| [host isLocalHost]*/)
      host = @"localhost";
   
   id icon = [dict valueForKey:GROWL_NOTIFICATION_ICON_DATA];
   NSData *iconData = [icon isKindOfClass:[NSData class]] ? icon : ([icon isKindOfClass:[NSImage class]] ? [icon TIFFRepresentation] : nil);
   
   NSAppleEventDescriptor *noteDesc = [NSAppleEventDescriptor recordDescriptor];
   [noteDesc setDescriptor:[NSAppleEventDescriptor descriptorWithString:host] forKeyword:'NtHs'];
   [noteDesc setDescriptor:[NSAppleEventDescriptor descriptorWithString:[dict valueForKey:GROWL_APP_NAME]] forKeyword:'ApNm'];
   [noteDesc setDescriptor:[NSAppleEventDescriptor descriptorWithString:[dict valueForKey:GROWL_NOTIFICATION_NAME]] forKeyword:'NtTp'];
   [noteDesc setDescriptor:[NSAppleEventDescriptor descriptorWithString:[dict valueForKey:GROWL_NOTIFICATION_TITLE]] forKeyword:'Titl'];
   [noteDesc setDescriptor:[NSAppleEventDescriptor descriptorWithString:[dict valueForKey:GROWL_NOTIFICATION_DESCRIPTION]] forKeyword:'Desc'];
   [noteDesc setDescriptor:[NSAppleEventDescriptor descriptorWithBoolean:[[dict valueForKey:GROWL_NOTIFICATION_STICKY] boolValue]] forKeyword:'Stic'];
   if(iconData != nil){
      [noteDesc setDescriptor:[NSAppleEventDescriptor descriptorWithDescriptorType:typeData
                                                                              data:iconData]
                   forKeyword:'Icon'];
   }
   return noteDesc;
}

-(NSDictionary*)strippedDownDictionaryForAutomator:(NSDictionary*)dict {
   NSMutableDictionary *result = [NSMutableDictionary dictionary];
   
   NSString *host = [dict valueForKey:@"GNTP Notification Sent-By"];
   if(!host /*|| [host isLocalHost]*/)
      host = @"localhost";
   
   id icon = [dict valueForKey:GROWL_NOTIFICATION_ICON_DATA];
   NSData *iconData = [icon isKindOfClass:[NSData class]] ? icon : ([icon isKindOfClass:[NSImage class]] ? [icon TIFFRepresentation] : nil);
   
   [result setObject:host forKey:@"host"];
   [result setObject:[dict valueForKey:GROWL_APP_NAME] forKey:@"application"];
   [result setObject:[dict valueForKey:GROWL_NOTIFICATION_NAME] forKey:@"type"];
   [result setObject:[dict valueForKey:GROWL_NOTIFICATION_TITLE] forKey:@"title"];
   [result setObject:[dict valueForKey:GROWL_NOTIFICATION_DESCRIPTION] forKey:@"description"];
   //if([dict valueForKey:GROWL_NOTIFICATION_STICKY])
      //[result setObject:[dict valueForKey:GROWL_NOTIFICATION_STICKY] forKey:@"sticky"];
   //else
      //[result setObject:[NSNumber numberWithBool:NO] forKey:@"sticky"];
   if(iconData != nil){
      //[result setObject:iconData forKey:@"icon"];
   }
   return [[result copy] autorelease];
}

-(NSArray*)unixArgumentsForDictionary:(NSDictionary*)dict {
   NSMutableArray *result = [NSMutableArray array];
   NSString *host = [dict valueForKey:@"GNTP Notification Sent-By"];
   if(!host /*|| [host isLocalHost]*/)
      host = @"localhost";
   
   //id icon = [dict valueForKey:GROWL_NOTIFICATION_ICON_DATA];
   //NSData *iconData = [icon isKindOfClass:[NSData class]] ? icon : ([icon isKindOfClass:[NSImage class]] ? [icon TIFFRepresentation] : nil);
   
   [result addObject:host];
   [result addObject:[dict valueForKey:GROWL_APP_NAME]];
   [result addObject:[dict valueForKey:GROWL_NOTIFICATION_NAME]];
   [result addObject:[dict valueForKey:GROWL_NOTIFICATION_TITLE]];
   [result addObject:[dict valueForKey:GROWL_NOTIFICATION_DESCRIPTION]];
   BOOL sticky = [dict valueForKey:GROWL_NOTIFICATION_STICKY] ? [[dict valueForKey:GROWL_NOTIFICATION_STICKY] boolValue] : NO;
   NSString *stickyString = sticky ? @"yes" : @"no";
   [result addObject:stickyString];
   /*if(iconData != nil){
      [result addObject:iconData];
   }*/

   return [[result copy] autorelease];
}


/* Dispatch a notification with a configuration, called on the default priority background concurrent queue
 * Unless you need to use UI, do not send something to the main thread/queue.
 * If you have a requirement to be serialized, make a custom serial queue for your own use. 
 */
-(void)dispatchNotification:(NSDictionary *)notification withConfiguration:(NSDictionary *)configuration {
   NSString *fileName = @"ActionTest.sh";
   NSUserScriptTask *scriptTask = [self scriptTaskForFile:fileName];

   if(scriptTask){
      if([scriptTask isKindOfClass:[NSUserAppleScriptTask class]]){
         int pid = [[NSProcessInfo processInfo] processIdentifier];
         NSAppleEventDescriptor *thisApplication = [NSAppleEventDescriptor descriptorWithDescriptorType:typeKernelProcessID
                                                                                                  bytes:&pid
                                                                                                 length:sizeof(pid)];
         //GrAcScPe
         NSAppleEventDescriptor *event = [NSAppleEventDescriptor appleEventWithEventClass:'GrAc'
                                                                                  eventID:'ScPe'
                                                                         targetDescriptor:thisApplication
                                                                                 returnID:kAutoGenerateReturnID
                                                                            transactionID:kAnyTransactionID];
         [event setDescriptor:[self notificationDescriptor:notification] forKeyword:'NtPa'];
         [(NSUserAppleScriptTask*)scriptTask executeWithAppleEvent:event
                                                 completionHandler:^(NSAppleEventDescriptor *result, NSError *completionError) {
                                                    if(completionError){
                                                       NSLog(@"Error running selected AppleScript: %@", completionError);
                                                    }
                                                 }];
      }else if([scriptTask isKindOfClass:[NSUserUnixTask class]]){
         //Pass arguments
         [(NSUserUnixTask*)scriptTask setStandardInput:[NSFileHandle fileHandleWithStandardInput]];
         [(NSUserUnixTask*)scriptTask setStandardOutput:[NSFileHandle fileHandleWithStandardOutput]];
         [(NSUserUnixTask*)scriptTask setStandardError:[NSFileHandle fileHandleWithStandardError]];
         [(NSUserUnixTask*)scriptTask executeWithArguments:[self unixArgumentsForDictionary:notification]
                                         completionHandler:^(NSError *error) {
                                            if(error){
                                               NSLog(@"Error executing selected Unix Script: %@", error);
                                            }
                                         }];
         
      }else if([scriptTask isKindOfClass:[NSUserAutomatorTask class]]) {
         //Pass variables
         static dispatch_once_t onceToken;
         dispatch_once(&onceToken, ^{
            NSLog(@"Automator workflows are not supported at this time");
         });
         /*NSDictionary *justTheFacts = [self strippedDownDictionaryForAutomator:notification];
         [(NSUserAutomatorTask*)scriptTask setVariables:justTheFacts];
         [(NSUserAutomatorTask*)scriptTask executeWithInput:nil
                                          completionHandler:^(id result, NSError *error) {
                                             if(error){
                                                NSLog(@"Error executing slected automator workflow %@", error);
                                             }
                                          }];*/
      }else{
         NSLog(@"Unknown class of script task for file %@", fileName);
      }
   }else {
      NSLog(@"Unable to generate script using file %@", fileName);
   }
}

/* Auto generated method returning our PreferencePane, do not touch */
- (GrowlPluginPreferencePane *) preferencePane {
	if (!preferencePane)
		preferencePane = [[GrowlScriptActionPreferencePane alloc] initWithBundle:[NSBundle bundleWithIdentifier:@"com.Growl.ScriptAction"]];
	
	return preferencePane;
}

@end
