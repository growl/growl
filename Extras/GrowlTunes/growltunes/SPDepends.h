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


typedef void(^SPDependsCallback)();

#if __cplusplus
extern "C" {
#endif

/**
 * Add a dependency from an object to another object.
 * Registers that your object depends on the given objects and their key paths,
 * and invokes the callback when the values of any of the given key paths
 * changes.
 * 
 * @param owner See associationName. 
 * @param associationName If an owner and association name is given, the dependency 
 *                        object is associated with the owner under the given name, 
 *                        and automatically deallocated if another dependency with the 
 *                        same name is given, or if the owner object dies.
 *
 *                        If the automatic association described above is not used, 
 *                        you must retain the returned dependency object until the 
 *                        dependency becomes invalid.
 * @param callback Called when the association changes. Always called once immediately
 *                 after registration.
 * @example
 *  __block __typeof(self) selff; // weak reference
 *  NSArray *dependencies = [NSArray arrayWithObjects:foo, @"bar", @"baz", a, @"b", nil]
 *  SPAddDependency(self, @"modifyThing", dependencies, ^ {
 *      selff.thing = foo.bar*3 + foo.baz - a.b;
 *  });
 */
id SPAddDependency(id owner, NSString *associationName, NSArray *dependenciesAndNames, SPDependsCallback callback);
/**
 * Like SPAddDependency, but can be called varg style without an explicit array object.
 * End with the callback and then nil.
 */
id SPAddDependencyV(id owner, NSString *associationName, ...);

/**
 * Removes all dependencies this object has on other objects.
 */
void SPRemoveAssociatedDependencies(id owner);

#if __cplusplus
}
#endif

/**
 * Shortcut for SPAddDependencyV
 */
#define $depends(associationName, object, keypath, ...) ({ \
	__block __typeof(self) selff = self; /* Weak reference*/ \
	SPAddDependencyV(self, associationName, object, keypath, __VA_ARGS__, nil);\
})


@interface SPDependency : NSObject {
    @private
    SPDependsCallback _callback;
    id __unsafe_unretained _owner;
    NSMutableArray* _subscriptions;
}
@end

