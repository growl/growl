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


#import <Foundation/Foundation.h>

//#define $array(...) ({ id values[] = {__VA_ARGS__}; [NSArray arrayWithObjects:values count:sizeof(values)/sizeof(id)]; })
#define $array(...) [NSArray arrayWithObjects:__VA_ARGS__, nil]
#define $set(...) [NSSet setWithObjects:__VA_ARGS__, nil]
#define $marray(...) [NSMutableArray arrayWithObjects:__VA_ARGS__, nil]
#define $dict(...)  ({ NSArray *pairs = [NSArray arrayWithObjects:__VA_ARGS__, nil]; SPDictionaryWithPairs(pairs, false); })
#define $mdict(...) ({ NSArray *pairs = [NSArray arrayWithObjects:__VA_ARGS__, nil]; SPDictionaryWithPairs(pairs, true);  })

#define $num(val) [NSNumber numberWithInt:val]
#define $numf(val) [NSNumber numberWithDouble:val]
#define $sprintf(...) [NSString stringWithFormat:__VA_ARGS__]
#define $nsutf(cstr) [NSString stringWithUTF8String:cstr]

#define $cast(klass, obj) ({\
	__typeof__(obj) obj2 = (obj); \
	if(![obj2 isKindOfClass:[klass class]]) \
		[NSException exceptionWithName:NSInternalInconsistencyException \
								reason:$sprintf(@"%@ is not a %@", obj2, [klass class]) \
								userInfo:nil]; \
	(klass*)obj2;\
})
#define $castIf(klass, obj) ({ __typeof__(obj) obj2 = (obj); [obj2 isKindOfClass:[klass class]]?(klass*)obj2:nil; })

#define $notNull(x) ({ __typeof(x) xx = (x); NSAssert(xx != nil, @"Must not be nil"); xx; })

#ifdef __cplusplus
extern "C" {
#endif
	

NSString *$urlencode(NSString *unencoded);
id SPDictionaryWithPairs(NSArray *pairs, BOOL mutablep);

NSError *$makeErr(NSString *domain, NSInteger code, NSString *localizedDesc);

#ifdef __cplusplus
}
#endif

#if NS_BLOCKS_AVAILABLE
@interface NSDictionary (SPMap)
-(NSDictionary*)sp_map:(id(^)(NSString *key, id value))mapper;
@end
#endif