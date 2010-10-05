//
//  GrowlImageCache.m
//  Growl
//
//  Created by Daniel Siemer on 9/29/10.
//  Copyright 2010 The Growl Project. All rights reserved.
//

#import "GrowlImageCache.h"
#import "GrowlImageAdditions.h"
#import <openssl/md5.h>

@implementation GrowlImageCache

@dynamic Checksum;
@dynamic Image;
@dynamic Notifications;

+(void)initialize
{
   if(self == [GrowlImageCache class])
   {
      NSImageToDataTransformer *transformer = [[NSImageToDataTransformer alloc] init];
		[NSValueTransformer setValueTransformer:transformer forName:@"NSImageToDataTransformer"];
   }
}

-(void)setImage:(NSData*)data andHash:(NSString*)hash
{
   self.Image = data;
   self.Checksum = hash;
}

@end

@implementation NSImageToDataTransformer


+ (BOOL)allowsReverseTransformation {
	return YES;
}

+ (Class)transformedValueClass {
	return [NSData class];
}

- (id)transformedValue:(id)value {
   NSData *data = nil; 
   if([value isMemberOfClass:[NSImage class]])
   {
      data = [value PNGRepresentation];
   }else{
      data = value;
   }
	return data;
}

- (id)reverseTransformedValue:(id)value {
	NSImage *nsImage = [[NSImage alloc] initWithData:value];
	return [nsImage autorelease];
}

@end
