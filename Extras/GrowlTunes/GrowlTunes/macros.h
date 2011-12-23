#import "additions.h"
#import "defines.h"

#define $bool(val) [NSNumber numberWithBool:val]
#define $integer(val) [NSNumber numberWithInteger:val]


#ifndef __has_feature
#define __has_feature(x) 0
#endif

#ifndef __unsafe_unretained
#define __unsafe_unretained
#endif

#ifndef __bridge
#define __bridge
#endif

#if __has_feature(objc_arc)
#   define STRONG                       strong
#   define __STRONG                     __strong
#   if __has_feature(objc_arc_weak)
#       define WEAK                     weak
#       define __WEAK                   __weak
#   else
#       define WEAK                     assign
#       define __WEAK                   __unsafe_unretained
#   endif
#else
#   define STRONG                       retain
#   define WEAK                         assign
#   if __OBJC_GC__
#       define __STRONG                 __attribute__((objc_gc(strong)))
#       define __WEAK                   __attribute__((objc_gc(weak)))
#   else
#       define __STRONG
#       define __WEAK
#   endif
#endif

static inline __attribute__((always_inline)) id UNCHANGED(id obj) {return obj;}

#if __has_feature(objc_arc)
#   define RETAIN(o)                    UNCHANGED(o)
#   define RELEASE(o)                   o = nil
#   define AUTORELEASE(o)               UNCHANGED(o)
#   define RETAIN_AUTORELEASE(o)        UNCHANGED(o)
#   define CFCollect(cfo)               CFBridgingRelease(cfo)
#   define SUPER_DEALLOC
#else
#   define RETAIN(o)                    [o retain]
#   define RELEASE(o)                   [o release], o = nil
#   define AUTORELEASE(o)               [o autorelease]
#   define RETAIN_AUTORELEASE(o)        [[o retain] autorelease]
#   define CFCollect(cfo)               [(id)CFMakeCollectable(cfo) autorelease]
#   define SUPER_DEALLOC                [super dealloc]
#endif
