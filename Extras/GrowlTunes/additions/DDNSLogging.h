//
//  DDNSLogging.h
//
//  Created by Travis Tilley on 12/20/11.
//  Copyright (c) 2011 Travis Tilley. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import "LoggerClient.h"
#import "DDLog.h"
#import "DDNSLogger.h"


#if defined(NSLOGGER) && !defined(NDEBUG)
#   undef assert
#   if __DARWIN_UNIX03
#       define assert(e)                                                                                    \
            (__builtin_expect(!(e), 0) ?                                                                    \
                (CFShow(CFSTR("assert going to fail, connect NSLogger NOW\n")), LoggerFlush(NULL,YES),      \
                    __assert_rtn(__func__, __FILE__, __LINE__, #e)) :                                       \
                (void)0)
#   else
#       define assert(e)                                                                                    \
            (__builtin_expect(!(e), 0) ?                                                                    \
                (CFShow(CFSTR("assert going to fail, connect NSLogger NOW\n")), LoggerFlush(NULL,YES),      \
                    __assert(#e, __FILE__, __LINE__)) :                                                     \
                (void)0)
#   endif
#endif


#ifndef DDNSLoggerDefaultOptions
#define DDNSLoggerDefaultOptions            (kLoggerOption_BufferLogsUntilConnection |                      \
                                             kLoggerOption_BrowseBonjour |                                  \
                                             kLoggerOption_UseSSL)
#endif

#ifndef DDNSLoggerDefaultService
#define DDNSLoggerDefaultService            "DDNSLogger"
#endif

#ifndef DDNSLoggerDefaultBufferFilename
#define DDNSLoggerDefaultBufferFilename     "DDNSLog.rawnsloggerdata"
#endif



#define DDNS_LOG_FLAG_ERROR         LOG_FLAG_ERROR
#define DDNS_LOG_FLAG_WARN          LOG_FLAG_WARN
#define DDNS_LOG_FLAG_INFO          LOG_FLAG_INFO
#define DDNS_LOG_FLAG_VERBOSE       LOG_FLAG_VERBOSE
#define DDNS_LOG_FLAG_DEBUG         (1 << 4)

#define DDNS_LOG_FLAG_DATA          (1 << 10)
#define DDNS_LOG_FLAG_IMAGE         (1 << 11)
#define DDNS_LOG_FLAG_START_BLOCK   (1 << 12)
#define DDNS_LOG_FLAG_END_BLOCK     (1 << 13)
#define DDNS_LOG_FLAG_MARKER        (1 << 14)

#define DDNS_LOG_LEVEL_OFF          LOG_LEVEL_OFF
#define DDNS_LOG_LEVEL_ERROR        LOG_LEVEL_ERROR
#define DDNS_LOG_LEVEL_WARN         LOG_LEVEL_WARN
#define DDNS_LOG_LEVEL_INFO         LOG_LEVEL_INFO
#define DDNS_LOG_LEVEL_VERBOSE      LOG_LEVEL_VERBOSE
#define DDNS_LOG_LEVEL_DEBUG        (DDNS_LOG_FLAG_ERROR | DDNS_LOG_FLAG_WARN | DDNS_LOG_FLAG_INFO | \
                                     DDNS_LOG_FLAG_VERBOSE | DDNS_LOG_FLAG_DEBUG)

#if defined(NDEBUG)
#define DDNS_LOG_LEVEL_DEFAULT      DDNS_LOG_LEVEL_WARN
#else
#define DDNS_LOG_LEVEL_DEFAULT      DDNS_LOG_LEVEL_VERBOSE
#endif

#define DDNS_LOG_ERROR              (ddLogLevel & DDNS_LOG_ERROR)
#define DDNS_LOG_WARN               (ddLogLevel & DDNS_LOG_WARN)
#define DDNS_LOG_INFO               (ddLogLevel & DDNS_LOG_INFO)
#define DDNS_LOG_VERBOSE            (ddLogLevel & DDNS_LOG_VERBOSE)
#define DDNS_LOG_DEBUG              (ddLogLevel & DDNS_LOG_DEBUG)

#ifndef DDNS_LOG_ASYNC_ENABLED
#define DDNS_LOG_ASYNC_ENABLED      LOG_ASYNC_ENABLED
#endif

#define DDNS_LOG_ASYNC_ERROR        NO
#define DDNS_LOG_ASYNC_WARN         (YES && DDNS_LOG_ASYNC_ENABLED)
#define DDNS_LOG_ASYNC_INFO         (YES && DDNS_LOG_ASYNC_ENABLED)
#define DDNS_LOG_ASYNC_VERBOSE      (YES && DDNS_LOG_ASYNC_ENABLED)
#define DDNS_LOG_ASYNC_DEBUG        (YES && DDNS_LOG_ASYNC_ENABLED)


#define DDNS_LOG_MACRO(isAsynchronous, lvl, flg, ctx, tagstr, frmt, ...)                                    \
    [DDLog log:isAsynchronous                                                                               \
         level:lvl                                                                                          \
          flag:flg                                                                                          \
       context:ctx                                                                                          \
          file:__FILE__                                                                                     \
      function:__PRETTY_FUNCTION__                                                                          \
          line:__LINE__                                                                                     \
           tag:tagstr                                                                                       \
        format:(frmt), ##__VA_ARGS__]

#define DDNS_LOG_DATA_MACRO(isAsynchronous, lvl, flg, ctx, tagstr, dta)                                     \
    [DDLog log:isAsynchronous                                                                               \
         level:lvl                                                                                          \
          flag:flg                                                                                          \
       context:ctx                                                                                          \
          file:__FILE__                                                                                     \
      function:__PRETTY_FUNCTION__                                                                          \
          line:__LINE__                                                                                     \
           tag:tagstr                                                                                       \
          data:dta]

#define DDNS_LOG_IMAGE_MACRO(isAsynchronous, lvl, flg, ctx, tagstr, img)                                    \
    [DDLog log:isAsynchronous                                                                               \
         level:lvl                                                                                          \
          flag:flg                                                                                          \
       context:ctx                                                                                          \
          file:__FILE__                                                                                     \
      function:__PRETTY_FUNCTION__                                                                          \
          line:__LINE__                                                                                     \
           tag:tagstr                                                                                       \
         image:img]

#define DDNS_LOG_MAYBE(async, lvl, flg, ctx, tag, frmt, ...)                                                \
do {                                                                                                        \
    if (lvl & flg) {                                                                                        \
        DDNS_LOG_MACRO(async, lvl, flg, ctx, tag, frmt, ##__VA_ARGS__);                                     \
    }                                                                                                       \
} while(0)

#define DDNS_LOG_DATA_MAYBE(async, lvl, flg, ctx, tag, data)                                                \
do {                                                                                                        \
    if (lvl & flg) {                                                                                        \
        DDNS_LOG_DATA_MACRO(async, lvl, flg, ctx, tag, data);                                               \
    }                                                                                                       \
} while(0)

#define DDNS_LOG_IMAGE_MAYBE(async, lvl, flg, ctx, tag, image)                                              \
do {                                                                                                        \
    if (lvl & flg) {                                                                                        \
        DDNS_LOG_IMAGE_MACRO(async, lvl, flg, ctx, tag, image);                                             \
    }                                                                                                       \
} while(0)

#define DDNSLogErrorTag(tag, frmt, ...)                                                                     \
    DDNS_LOG_MAYBE(DDNS_LOG_ASYNC_ERROR, ddLogLevel,                                                        \
                   DDNS_LOG_FLAG_ERROR, 0, tag, frmt, ##__VA_ARGS__)

#define DDNSLogWarnTag(tag, frmt, ...)                                                                      \
    DDNS_LOG_MAYBE(DDNS_LOG_ASYNC_WARN, ddLogLevel,                                                         \
                   DDNS_LOG_FLAG_WARN, 0, tag, frmt, ##__VA_ARGS__)

#define DDNSLogInfoTag(tag, frmt, ...)                                                                      \
    DDNS_LOG_MAYBE(DDNS_LOG_ASYNC_INFO, ddLogLevel,                                                         \
                   DDNS_LOG_FLAG_INFO, 0, tag, frmt, ##__VA_ARGS__)

#define DDNSLogVerboseTag(tag, frmt, ...)                                                                   \
    DDNS_LOG_MAYBE(DDNS_LOG_ASYNC_VERBOSE, ddLogLevel,                                                      \
                   DDNS_LOG_FLAG_VERBOSE, 0, tag, frmt, ##__VA_ARGS__)

#define DDNSLogDebugTag(tag, frmt, ...)                                                                     \
    DDNS_LOG_MAYBE(DDNS_LOG_ASYNC_DEBUG, ddLogLevel,                                                        \
                   DDNS_LOG_FLAG_DEBUG, 0, tag, frmt, ##__VA_ARGS__)

#define DDNSLogError(frmt, ...)     DDNSLogErrorTag(nil, frmt, ##__VA_ARGS__)
#define DDNSLogWarn(frmt, ...)      DDNSLogWarnTag(nil, frmt, ##__VA_ARGS__)
#define DDNSLogInfo(frmt, ...)      DDNSLogInfoTag(nil, frmt, ##__VA_ARGS__)
#define DDNSLogVerbose(frmt, ...)   DDNSLogVerboseTag(nil, frmt, ##__VA_ARGS__)
#define DDNSLogDebug(frmt, ...)     DDNSLogDebugTag(nil, frmt, ##__VA_ARGS__)

#define DDNSLogStartBlock(msg)                                                                              \
    DDNS_LOG_MAYBE(DDNS_LOG_ASYNC_INFO, ddLogLevel,                                                         \
                   (DDNS_LOG_FLAG_INFO | DDNS_LOG_FLAG_START_BLOCK), 0, nil, @"%@", msg)

#define DDNSLogEndBlock                                                                                     \
    DDNS_LOG_MAYBE(DDNS_LOG_ASYNC_INFO, ddLogLevel,                                                         \
                   (DDNS_LOG_FLAG_INFO | DDNS_LOG_FLAG_END_BLOCK), 0, nil, nil, nil)

#define DDNSLogMarker(msg)                                                                                  \
    DDNS_LOG_MAYBE(DDNS_LOG_ASYNC_INFO, ddLogLevel,                                                         \
                   (DDNS_LOG_FLAG_INFO | DDNS_LOG_FLAG_MARKER), 0, nil, nil, msg)

#define DDNSLogData(data)                                                                                   \
    DDNS_LOG_DATA_MAYBE(DDNS_LOG_ASYNC_INFO, ddLogLevel,                                                    \
                        (DDNS_LOG_FLAG_INFO | DDNS_LOG_FLAG_DATA), 0, nil, data)

#define DDNSLogImage(image)                                                                                 \
    DDNS_LOG_IMAGE_MAYBE(DDNS_LOG_ASYNC_INFO, ddLogLevel,                                                   \
                         (DDNS_LOG_FLAG_INFO | DDNS_LOG_FLAG_IMAGE), 0, nil, image)

#define LogErrorTag(tag, ...)           DDNSLogErrorTag(tag, ##__VA_ARGS__)
#define LogWarnTag(tag, ...)            DDNSLogWarnTag(tag, ##__VA_ARGS__)
#define LogInfoTag(tag, ...)            DDNSLogInfoTag(tag, ##__VA_ARGS__)
#define LogVerboseTag(tag, ...)         DDNSLogVerboseTag(tag, ##__VA_ARGS__)
#define LogDebugTag(tag, ...)           DDNSLogDebugTag(tag, ##__VA_ARGS__)

#define LogError(...)                   LogErrorTag(nil, ##__VA_ARGS__)
#define LogWarn(...)                    LogWarnTag(nil, ##__VA_ARGS__)
#define LogInfo(...)                    LogInfoTag(nil, ##__VA_ARGS__)
#define LogVerbose(...)                 LogVerboseTag(nil, ##__VA_ARGS__)
#define LogDebug(...)                   LogDebugTag(nil, ##__VA_ARGS__)

#define LogStartBlock(msg)              DDNSLogStartBlock(msg)
#define LogEndBlock                     DDNSLogEndBlock
#define LogMarkder(msg)                 DDNSLogMarker(msg)
#define LogData(data)                   DDNSLogData(data)
#define LogImage(image)                 DDNSLogImage(image)

#ifdef GANK_NSLOG
#define NSLog(...) LogInfoTag(0, ##__VA_ARGS__)
#endif
