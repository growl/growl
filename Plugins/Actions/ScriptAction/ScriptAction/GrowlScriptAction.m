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
#import <GrowlPlugins/GrowlUserScriptTaskUtilities.h>

@implementation GrowlScriptAction

-(id)init{
   if(![GrowlUserScriptTaskUtilities hasScriptTaskClass])
      return nil;
   
   if((self = [super init])){
      
   }
   return self;
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

-(NSArray*)unixArgumentsForDictionary:(NSDictionary*)dict withOrderedKeys:(NSArray*)keys {
	NSMutableArray *result = [NSMutableArray array];
	[keys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if([obj isEqualToString:GROWL_APP_NAME] ||
			[obj isEqualToString:GROWL_NOTIFICATION_NAME] ||
			[obj isEqualToString:GROWL_NOTIFICATION_TITLE]){
			if([dict valueForKey:obj] != nil)
				[result addObject:[dict valueForKey:obj]];
		}else if([obj isEqualToString:@"GNTP Notification Sent-By"]){
			NSString *host = [dict valueForKey:obj];
			if(!host /*|| [host isLocalHost]*/)
				host = @"localhost";
			[result addObject:host];
		}else if([obj isEqualToString:GROWL_NOTIFICATION_STICKY]){
			BOOL sticky = [dict valueForKey:GROWL_NOTIFICATION_STICKY] ? [[dict valueForKey:GROWL_NOTIFICATION_STICKY] boolValue] : NO;
			NSString *stickyString = sticky ? @"0" : @"1";
			[result addObject:stickyString];
		}else if([obj isEqualToString:GROWL_NOTIFICATION_PRIORITY]){
			NSInteger priority = [dict valueForKey:GROWL_NOTIFICATION_STICKY] ? [[dict valueForKey:GROWL_NOTIFICATION_STICKY] boolValue] : NO;
			NSString *priorityString = [NSString stringWithFormat:@"%ld", priority];
			[result addObject:priorityString];
		}else if([obj isEqualToString:GROWL_NOTIFICATION_ICON_DATA]){
/*			id icon = [dict valueForKey:GROWL_NOTIFICATION_ICON_DATA];
			NSData *iconData = [icon isKindOfClass:[NSData class]] ? icon : ([icon isKindOfClass:[NSImage class]] ? [icon TIFFRepresentation] : nil);
			if(iconData != nil){
				[result addObject:iconData];
			}*/
		}
	}];
	return result;
}

-(NSArray*)defaultArgumentsArray {
	static NSArray *_arguments = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_arguments = [@[@"GNTP Notification Sent-By",
						  GROWL_APP_NAME,
						  GROWL_NOTIFICATION_NAME,
						  GROWL_NOTIFICATION_TITLE,
						  GROWL_NOTIFICATION_DESCRIPTION,
						  GROWL_NOTIFICATION_PRIORITY,
						  GROWL_NOTIFICATION_STICKY/*,
						  GROWL_NOTIFICATION_ICON_DATA*/] retain];
	});
	return _arguments;
}

-(NSArray*)unixArgumentsForDictionary:(NSDictionary*)dict {
	return [self unixArgumentsForDictionary:dict withOrderedKeys:[self defaultArgumentsArray]];
}


/* Dispatch a notification with a configuration, called on the default priority background concurrent queue
 * Unless you need to use UI, do not send something to the main thread/queue.
 * If you have a requirement to be serialized, make a custom serial queue for your own use. 
 */
-(void)dispatchNotification:(NSDictionary *)notification withConfiguration:(NSDictionary *)configuration {
   NSString *fileName = [configuration valueForKey:@"ScriptActionFileName"];
	if(!fileName || [fileName isEqualToString:@""])
		NSLog(@"Error! Either file '%@' is null, or empty", fileName);
   NSUserScriptTask *scriptTask = [GrowlUserScriptTaskUtilities scriptTaskForFile:fileName];

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
         [event setDescriptor:[GrowlUserScriptTaskUtilities appleEventDescriptorForNotification:notification] forKeyword:'NtPa'];
         [(NSUserAppleScriptTask*)scriptTask executeWithAppleEvent:event
                                                 completionHandler:^(NSAppleEventDescriptor *result, NSError *completionError) {
                                                    if(completionError){
                                                       NSLog(@"Error running selected AppleScript: %@", completionError);
                                                    }
                                                 }];
      }else if([scriptTask isKindOfClass:[NSUserUnixTask class]]){
         [(NSUserUnixTask*)scriptTask setStandardInput:[NSFileHandle fileHandleWithStandardInput]];
         [(NSUserUnixTask*)scriptTask setStandardOutput:[NSFileHandle fileHandleWithStandardOutput]];
         [(NSUserUnixTask*)scriptTask setStandardError:[NSFileHandle fileHandleWithStandardError]];
			NSArray *argumentKeys = [configuration valueForKey:@"ScriptActionUnixArguments"];
			NSArray *arguments = nil;
			if(argumentKeys)
				arguments = [self unixArgumentsForDictionary:notification withOrderedKeys:argumentKeys];
			else
				arguments = [self unixArgumentsForDictionary:notification];
         [(NSUserUnixTask*)scriptTask executeWithArguments:arguments
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
