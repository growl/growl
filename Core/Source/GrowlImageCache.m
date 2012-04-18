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
@dynamic ImageData;
@dynamic Image;
@dynamic Notifications;
@dynamic Thumbnail;

-(void)setImage:(NSData*)data andHash:(NSString*)hash
{
   self.ImageData = data;
   [self setPrimitiveValue:[[[NSImage alloc]initWithData:data] autorelease] forKey:@"Image"];
   self.Checksum = hash;
}

-(NSImage*)Image
{
   [self willAccessValueForKey:@"Image"];
   NSImage *image = [self primitiveValueForKey:@"Image"];
   [self didAccessValueForKey:@"Image"];
   
   if (!image)
   {
      NSData *imageData = [self ImageData];
      if (imageData != nil)
      {
         image = [[[NSImage alloc] initWithData:imageData] autorelease];
         [self setPrimitiveValue:image forKey:@"Image"];
      }
   }
   return image;
}

-(NSImage*)Thumbnail
{
   [self willAccessValueForKey:@"Thumbnail"];
   NSImage *thumb = [self primitiveValueForKey:@"Thumbnail"];
   [self didAccessValueForKey:@"Thumbnail"];
   
   if(!thumb)
   {
      thumb = [[[self Image] copyWithZone:nil] autorelease];
      [thumb setScalesWhenResized:YES];
      [thumb setSize:NSMakeSize(32, 32)];
      [self setPrimitiveValue:thumb forKey:@"Thumbnail"];
   }
   return thumb;
}

-(void)setImage:(NSImage*)image
{
   [self willChangeValueForKey:@"Image"];
   [self setPrimitiveValue:image forKey:@"Image"];
   [self didChangeValueForKey:@"Image"];
   [self setValue:[image PNGRepresentation] forKey:@"ImageData"];
}

@end

