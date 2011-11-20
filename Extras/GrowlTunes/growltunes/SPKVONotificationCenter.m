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


#import "SPKVONotificationCenter.h"
#import <libkern/OSAtomic.h>
#import <objc/message.h>

// Inspired by http://www.mikeash.com/svn/MAKVONotificationCenter/MAKVONotificationCenter.m


static NSString *SPKVOContext = @"SPKVObservation";
typedef void (*SPKVOCallback)(id, SEL, NSDictionary*, id, NSString *);

@interface SPKVObservation ()
@property(nonatomic, assign) id observer;
@property(nonatomic, assign) id observed;
@property(nonatomic, copy)   NSString *keyPath;
@property(nonatomic)         SEL selector;
@end


@implementation SPKVObservation
@synthesize observer = _observer, observed = _observed, selector = _sel, keyPath = _keyPath;
-(id)initWithObserver:(id)observer observed:(id)observed keyPath:(NSString*)keyPath selector:(SEL)sel options:(NSKeyValueObservingOptions)options
{
	_observer = observer;
	_observed = observed;
	_sel = sel;
	self.keyPath = keyPath;
	[_observed addObserver:self forKeyPath:keyPath options:options context:SPKVOContext];
	return self;
}
-(void)dealloc
{
	[self unregister];
	[_keyPath release];
	[super dealloc];
}
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(context != SPKVOContext) return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	
	if(_sel)
		((SPKVOCallback)objc_msgSend)(_observer, _sel, change, object, keyPath);
	else
		[_observer observeValueForKeyPath:keyPath ofObject:object change:change context:self];
}
-(id)unregister
{
	[_observed removeObserver:self forKeyPath:_keyPath];
	_observed = nil;
	return self;
}
@end



@implementation SPKVONotificationCenter
+ (id)defaultCenter
{
	static SPKVONotificationCenter *center = nil;
	if(!center)
	{
		SPKVONotificationCenter *newCenter = [self new];
		if(!OSAtomicCompareAndSwapPtrBarrier(nil, newCenter, (void *)&center))
			[newCenter release];
	}
	return center;
}
-(SPKVObservation*)addObserver:(id)observer toObject:(id)observed forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options
{
	return [self addObserver:observer toObject:observed forKeyPath:keyPath options:options selector:NULL];
}
-(SPKVObservation*)addObserver:(id)observer toObject:(id)observed forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options selector:(SEL)sel
{
	SPKVObservation *helper = [[[SPKVObservation alloc] initWithObserver:observer observed:observed keyPath:keyPath selector:sel options:options] autorelease];
	return helper;
}
@end
