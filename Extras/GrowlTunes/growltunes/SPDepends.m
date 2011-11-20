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


#import "SPDepends.h"
#import "SPKVONotificationCenter.h"
#import <objc/runtime.h>

@interface SPDependency ()
@property(copy, nonatomic) SPDependsCallback callback;
@property(assign, nonatomic) id owner;
@property(retain, nonatomic) NSMutableArray *subscriptions;
@end

@implementation SPDependency
@synthesize callback = _callback, owner = _owner;
@synthesize subscriptions = _subscriptions;

-initWithDependencies:(NSArray*)pairs callback:(SPDependsCallback)callback owner:(id)owner
{
	
	self.callback = callback;
	self.owner = owner;
	
	self.subscriptions = [NSMutableArray array];
	
	SPKVONotificationCenter *nc = [SPKVONotificationCenter defaultCenter];
	
	
	NSEnumerator *en = [pairs objectEnumerator];
	id object = [en nextObject];
	id next = [en nextObject];
	
	for(;;) {
		SPKVObservation *subscription = [nc addObserver:self toObject:object forKeyPath:next options:0 selector:@selector(somethingChanged)];
		[_subscriptions addObject:subscription];
		
		next = [en nextObject];
		if(!next) break;
		
		if(![next isKindOfClass:[NSString class]]) {
			object = next;
			next = [en nextObject];
		}
	}
	
	self.callback();
	
	return self;
}
-(void)invalidate
{
	for(SPKVObservation *observation in _subscriptions)
		[observation unregister];
	self.callback = nil;
}
-(void)dealloc
{
	self.subscriptions = nil;
	self.owner = nil;
	self.callback = nil;
	[super dealloc];
}
-(void)somethingChanged
{
#if _DEBUG
	NSAssert(self.callback != nil, @"Somehow a KVO reached us after an 'invalidate'?");
#endif
	if(self.callback)
		self.callback();
}
@end

static void *dependenciesKey = &dependenciesKey;

id SPAddDependency(id owner, NSString *associationName, NSArray *dependenciesAndNames, SPDependsCallback callback)
{
	id dep = [[[SPDependency alloc] initWithDependencies:dependenciesAndNames callback:callback owner:owner] autorelease];
	if(owner && associationName) {
		NSMutableDictionary *dependencies = objc_getAssociatedObject(owner, dependenciesKey);
		if(!dependencies) dependencies = [NSMutableDictionary dictionary];

		SPDependency *oldDependency = [dependencies objectForKey:associationName];
		if(oldDependency) [oldDependency invalidate];
		
		[dependencies setObject:dep forKey:associationName];
		objc_setAssociatedObject(owner, dependenciesKey, dependencies, OBJC_ASSOCIATION_RETAIN);
	}
	return dep;
}

id SPAddDependencyV(id owner, NSString *associationName, ...)
{
	NSMutableArray *dependenciesAndNames = [NSMutableArray new];
	va_list va;
	va_start(va, associationName);
	
	id object = va_arg(va, id);
	id peek = va_arg(va, id);
	do {
		[dependenciesAndNames addObject:object];
		object = peek;
		peek = va_arg(va, id);
	} while(peek != nil);
	
	id dep = SPAddDependency(owner, associationName, dependenciesAndNames, object);
	
	[dependenciesAndNames release];
	return dep;
}

void SPRemoveAssociatedDependencies(id owner)
{
	NSMutableDictionary *dependencies = objc_getAssociatedObject(owner, dependenciesKey);
	for(SPDependency *dep in [dependencies allValues])
		[dep invalidate];
	
	objc_setAssociatedObject(owner, dependenciesKey, nil, OBJC_ASSOCIATION_RETAIN);
}