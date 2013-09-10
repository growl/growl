//
//  GrowlUserScriptTaskUtilities.m
//  Growl
//
//  Created by Daniel Siemer on 10/24/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlUserScriptTaskUtilities.h"
#import "GrowlDefines.h"
#import "GrowlDefinesInternal.h"
#import "NSStringAdditions.h"

@implementation GrowlUserScriptTaskUtilities

+(BOOL)hasScriptTaskClass {
   return NSClassFromString(@"NSUserScriptTask") != nil;
}

static NSURL *baseScriptDirURL = nil;
+(NSURL*)baseScriptDirectoryURL {

	if(![self hasScriptTaskClass])
		return nil;
	
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *urlError = nil;
        baseScriptDirURL = [[[NSFileManager defaultManager] URLForDirectory:NSApplicationScriptsDirectory
                                                                   inDomain:NSUserDomainMask
                                                          appropriateForURL:nil
                                                                     create:YES
                                                                      error:&urlError] retain];
        if(urlError)
        {
            NSLog(@"Error retrieving Application Scripts directoy, %@", urlError);
        }
    });
    
   return baseScriptDirURL;
}

+(NSArray*)contentsOfScriptDirectory {
	NSURL *baseURL = [self baseScriptDirectoryURL];
	if(baseURL)
		return [[NSFileManager defaultManager] contentsOfDirectoryAtURL:baseURL
														 includingPropertiesForKeys:nil
																				  options:NSDirectoryEnumerationSkipsHiddenFiles
																					 error:nil];
	return nil;
}

+(BOOL)hasRulesScript {
	static BOOL _hasScript = NO;
	BOOL result = NO;
	NSArray *scripts = [self contentsOfScriptDirectory];
	NSIndexSet *found = [scripts indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
		if([[obj lastPathComponent] isEqualToString:@"Rules.scpt"])
			return YES;
		return NO;
	}];
	result = [found count] > 0;
	if(result != _hasScript){
		_hasScript = result;
		[[NSNotificationCenter defaultCenter] postNotificationName:@"GrowlRuleScriptStatusChange"
																			 object:nil
																		  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:_hasScript]
																															forKey:@"hasRules"]];
	}
	return result;
}

+(NSUserScriptTask*)scriptTaskForFile:(NSString*)fileName {
	if(!fileName)
		return nil;
	
   NSUserScriptTask* result = nil;
   if([self hasScriptTaskClass]){
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

+(NSUserAppleScriptTask*)rulesScriptTask {
	NSUserScriptTask *task = [self scriptTaskForFile:@"Rules.scpt"];
	if(task && [task isKindOfClass:[NSUserAppleScriptTask class]])
		return (NSUserAppleScriptTask*)task;
	
	return nil;
}

+(NSAppleEventDescriptor*)appleEventDescriptorForNotification:(NSDictionary*)dict {
	NSString *host = [dict valueForKey:GROWL_NOTIFICATION_GNTP_SENT_BY];
   if(!host || [host isLocalHost])
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
	NSInteger priority = [[dict valueForKey:GROWL_NOTIFICATION_PRIORITY] integerValue];
	FourCharCode priorityScriptCode = 'PrNo';
	switch (priority) {
		case -2:
			priorityScriptCode = 'PrVL';
			break;
		case -1:
			priorityScriptCode = 'PrMo';
			break;
		case 1:
			priorityScriptCode = 'PrHi';
			break;
		case 2:
			priorityScriptCode = 'PrEm';
			break;
		case 0:
		case -1000:
		default:
			priorityScriptCode = 'PrNo';
			break;
	}
	[noteDesc setDescriptor:[NSAppleEventDescriptor descriptorWithEnumCode:priorityScriptCode] forKeyword:'Prio'];
	
   return noteDesc;
}

+(BOOL)isAppleEventDescriptorBoolean:(NSAppleEventDescriptor*)event {
	BOOL result = NO;
	DescType type = [event descriptorType];
	if(type == typeBoolean ||
		type == typeFalse ||
		type == typeTrue)
	{
		result = YES;
	}else if(type == typeEnumerated){
		OSType enumValue = [event enumCodeValue];
		if(enumValue == kAENo || enumValue == kAEYes){
			result = YES;
		}
	}
	return result;
}

@end
