// Copyright (C) 2011 by Joachim Bengtsson
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


#import "SPLowVerbosity.h"

NSString *$urlencode(NSString *unencoded) {
	// Thanks, http://www.tikirobot.net/wp/2007/01/27/url-encode-in-cocoa/
	return [(__bridge id)CFURLCreateStringByAddingPercentEscapes(
														kCFAllocatorDefault, 
														(CFStringRef)unencoded, 
														NULL, 
														(CFStringRef)@";/?:@&=+$,", 
														kCFStringEncodingUTF8
														) autorelease];
}

id SPDictionaryWithPairs(NSArray *pairs, BOOL mutablep)
{
	NSUInteger count = pairs.count/2;
	id keys[count], values[count];
	size_t kvi = 0;
	for(size_t idx = 0; kvi < count;) {
		keys[kvi] = [pairs objectAtIndex:idx++];
		values[kvi++] = [pairs objectAtIndex:idx++];
	}
	return [mutablep?[NSMutableDictionary class]:[NSDictionary class] dictionaryWithObjects:values forKeys:keys count:kvi];
}

NSError *$makeErr(NSString *domain, NSInteger code, NSString *localizedDesc)
{
    return [NSError errorWithDomain:domain code:code userInfo:$dict(
        NSLocalizedDescriptionKey, localizedDesc
    )];
}

#if NS_BLOCKS_AVAILABLE
@implementation NSDictionary (SPMap)
-(NSDictionary*)sp_map:(id(^)(NSString *key, id value))mapper
{
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    for(NSString *key in self.allKeys)
        [d setObject:mapper(key, [self objectForKey:key]) forKey:key];
    return [[d copy] autorelease];
}
@end
#endif
