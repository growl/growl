//
//  NSObject+XPCHelpers.m
//  Growl
//
//  Created by Daniel Siemer on 9/15/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "NSObject+XPCHelpers.h"


@implementation NSObject (NSObject_XPCHelpers)

+(id)xpcObjectToNSObject:(xpc_object_t)object
{
   id nsValue = nil;
   xpc_type_t newType = xpc_get_type(object);
   
   if (newType == XPC_TYPE_DICTIONARY) {
      nsValue = [NSMutableDictionary dictionaryWithCapacity:xpc_dictionary_get_count(object)];
      xpc_dictionary_apply(object, ^bool(const char *key, xpc_object_t obj){
         NSString *nsKey = [NSString stringWithCString:key encoding:NSUTF8StringEncoding];
         id nsObj = [self xpcObjectToNSObject:obj];
         
         if (nsObj)
            [nsValue setObject:nsObj forKey:nsKey];
         
         return true;
      });
   }
   else if (newType == XPC_TYPE_ARRAY) {
      nsValue = [NSMutableArray arrayWithCapacity:xpc_array_get_count(object)];
      xpc_array_apply(object, ^_Bool(size_t index, xpc_object_t obj) {
         [nsValue addObject:[self xpcObjectToNSObject:obj]];
         return true;
      });
   }
   else if (newType == XPC_TYPE_STRING) {
      const char *string = xpc_string_get_string_ptr(object);
      nsValue = [NSString stringWithUTF8String:string];
   }
   else if (newType == XPC_TYPE_BOOL) {
      BOOL boolValue = xpc_bool_get_value(object);
      nsValue = [NSNumber numberWithBool:boolValue];
   }
   else if (newType == XPC_TYPE_INT64) {
      int64_t intValue = xpc_int64_get_value(object);
      nsValue = [NSNumber numberWithInteger:(NSInteger)intValue];
   }
   else if (newType == XPC_TYPE_UINT64) {
      uint64_t uintValue = xpc_uint64_get_value(object);
      nsValue = [NSNumber numberWithUnsignedInteger:(NSUInteger)uintValue];
   }
   else if (newType == XPC_TYPE_DOUBLE) {
      double_t doubleValue = xpc_double_get_value(object);
      nsValue = [NSNumber numberWithDouble:doubleValue];
   }
   else if (newType == XPC_TYPE_DATA) {
      const void *rawData = xpc_data_get_bytes_ptr(object);
      size_t dataLength = xpc_data_get_length(object);
      nsValue = [[[NSData alloc] initWithBytes:rawData length:dataLength] autorelease];
   }
   
   return nsValue;
}

-(xpc_object_t)newXPCObject
{
   xpc_object_t returnVal = NULL;
   if ([self isKindOfClass:[NSDictionary class]]) {
      returnVal = xpc_dictionary_create(NULL, NULL, 0);
      [(NSDictionary*)self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
         xpc_object_t xpcObj = [obj newXPCObject];
         if(xpcObj != NULL){
            xpc_dictionary_set_value(returnVal, [key UTF8String], xpcObj);
            xpc_release(xpcObj);
         }
      }];
   }else if ([self isKindOfClass:[NSString class]]){
      returnVal = xpc_string_create([(NSString*)self UTF8String]);
   }else if ([self isKindOfClass:[NSData class]]){
      returnVal = xpc_data_create([(NSData*)self bytes], [(NSData*)self length]);
   }else if ([self isKindOfClass:[NSArray class]]){
      returnVal = xpc_array_create(NULL, 0);
      [(NSArray*)self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         xpc_object_t appendVal = [obj newXPCObject];
         if(appendVal != NULL){
            xpc_array_set_value(returnVal, XPC_ARRAY_APPEND, appendVal);
            xpc_release(appendVal);
         }
      }];
   }else if ([self isKindOfClass:[NSNumber class]]){
      if(self == (NSNumber *)kCFBooleanTrue){
         returnVal = xpc_bool_create(true);
      }else if(self == (NSNumber *)kCFBooleanTrue){
         returnVal = xpc_bool_create(false);
      }else{
         const char* objCType = [(NSNumber*)self objCType];
         if(strcmp(objCType, @encode(unsigned long)) == 0){
            returnVal = xpc_uint64_create([(NSNumber*)self unsignedLongValue]);
         }else if(strcmp(objCType, @encode(long)) == 0){
            returnVal = xpc_int64_create([(NSNumber*)self longValue]);
         }else{
            returnVal = xpc_double_create([(NSNumber*)self doubleValue]);
         }
      }
   }
   
   return returnVal;
}

@end
