//
//  GrowlAppleScriptSupport.m
//  Growl
//
//  Created by Rudy Richter on 8/17/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlAppleScriptSupport.h"

//we define this ourselves
enum { cMissingValue                 = 'msng'};

@implementation NSData (GrowlAppleScriptSupport)

+ (id)scriptingImageWithDescriptor:(NSAppleEventDescriptor *)descriptor
{
	if ( [descriptor descriptorType] == typeType && [descriptor typeCodeValue] == cMissingValue )
	{
		return nil;
	}
	
	if ( [descriptor descriptorType] != typeTIFF )
	{
		descriptor = [descriptor coerceToDescriptorType: typeTIFF];
		if (descriptor == nil)
		{
			return nil;
		}		
	}
	
	return [descriptor data];
}

- (id)scriptingImageDescriptor
{
	return [NSAppleEventDescriptor descriptorWithDescriptorType: typeTIFF data: self];
}


@end
