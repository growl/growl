//
//  GrowlAppleScriptNoteConverter.m
//  Growl
//
//  Created by Daniel Siemer on 10/24/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlAppleScriptNoteConverter.h"
#import "GrowlDefines.h"
#import "GrowlDefinesInternal.h"
#import "NSStringAdditions.h"

@implementation GrowlAppleScriptNoteConverter

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

@end
