//
//  DDNSLogging.h
//
//  Created by Travis Tilley on 12/20/11.
//  Copyright (c) 2011 Travis Tilley. All rights reserved.
//

#import "LoggerClient.h"
#import "DDLog.h"
#import "DDNSLogger.h"

#if defined(DEBUG) && !defined(NDEBUG)
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

#ifndef DDNSLoggerDefaultHost
#define DDNSLoggerDefaultHost               "127.0.0.1"
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

#define DDNS_LOG_LEVEL_DEFAULT      DDNS_LOG_LEVEL_WARN

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


#define DDNS_LOG_MACRO(isAsynchronous, lvl, flg, ctx, frmt, ...)                                            \
    [DDLog log:isAsynchronous                                                                               \
         level:lvl                                                                                          \
          flag:flg                                                                                          \
       context:ctx                                                                                          \
          file:__FILE__                                                                                     \
      function:__PRETTY_FUNCTION__                                                                          \
          line:__LINE__                                                                                     \
        format:(frmt), ##__VA_ARGS__]

#define DDNS_LOG_DATA_MACRO(isAsynchronous, lvl, flg, ctx, dta)                                             \
    [DDLog log:isAsynchronous                                                                               \
         level:lvl                                                                                          \
          flag:flg                                                                                          \
       context:ctx                                                                                          \
          file:__FILE__                                                                                     \
      function:__PRETTY_FUNCTION__                                                                          \
          line:__LINE__                                                                                     \
          data:dta]

#define DDNS_LOG_IMAGE_MACRO(isAsynchronous, lvl, flg, ctx, img)                                            \
    [DDLog log:isAsynchronous                                                                               \
         level:lvl                                                                                          \
          flag:flg                                                                                          \
       context:ctx                                                                                          \
          file:__FILE__                                                                                     \
      function:__PRETTY_FUNCTION__                                                                          \
          line:__LINE__                                                                                     \
         image:img]

#define DDNS_LOG_MAYBE(async, lvl, flg, ctx, frmt, ...)                                                     \
do {                                                                                                        \
    if (lvl & flg) {                                                                                        \
        DDNS_LOG_MACRO(async, lvl, flg, ctx, frmt, ##__VA_ARGS__);                                          \
    }                                                                                                       \
} while(0)

#define DDNS_LOG_DATA_MAYBE(async, lvl, flg, ctx, data)                                                     \
do {                                                                                                        \
    if (lvl & flg) {                                                                                        \
        DDNS_LOG_DATA_MACRO(async, lvl, flg, ctx, data);                                                    \
    }                                                                                                       \
} while(0)

#define DDNS_LOG_IMAGE_MAYBE(async, lvl, flg, ctx, image)                                                   \
do {                                                                                                        \
    if (lvl & flg) {                                                                                        \
        DDNS_LOG_IMAGE_MACRO(async, lvl, flg, ctx, image);                                                  \
    }                                                                                                       \
} while(0)

#define DDNSLogErrorTag(tag, frmt, ...)                                                                     \
    DDNS_LOG_MAYBE(DDNS_LOG_ASYNC_ERROR, ddLogLevel,                                                        \
                   DDNS_LOG_FLAG_ERROR, tag, frmt, ##__VA_ARGS__)

#define DDNSLogWarnTag(tag, frmt, ...)                                                                      \
    DDNS_LOG_MAYBE(DDNS_LOG_ASYNC_WARN, ddLogLevel,                                                         \
                   DDNS_LOG_FLAG_WARN, tag, frmt, ##__VA_ARGS__)

#define DDNSLogInfoTag(tag, frmt, ...)                                                                      \
    DDNS_LOG_MAYBE(DDNS_LOG_ASYNC_INFO, ddLogLevel,                                                         \
                   DDNS_LOG_FLAG_INFO, tag, frmt, ##__VA_ARGS__)

#define DDNSLogVerboseTag(tag, frmt, ...)                                                                   \
    DDNS_LOG_MAYBE(DDNS_LOG_ASYNC_VERBOSE, ddLogLevel,                                                      \
                   DDNS_LOG_FLAG_VERBOSE, tag, frmt, ##__VA_ARGS__)

#define DDNSLogDebugTag(tag, frmt, ...)                                                                     \
    DDNS_LOG_MAYBE(DDNS_LOG_ASYNC_DEBUG, ddLogLevel,                                                        \
                   DDNS_LOG_FLAG_DEBUG, tag, frmt, ##__VA_ARGS__)

#define DDNSLogError(frmt, ...)     DDNSLogErrorTag(0, frmt, ##__VA_ARGS__)
#define DDNSLogWarn(frmt, ...)      DDNSLogWarnTag(0, frmt, ##__VA_ARGS__)
#define DDNSLogInfo(frmt, ...)      DDNSLogInfoTag(0, frmt, ##__VA_ARGS__)
#define DDNSLogVerbose(frmt, ...)   DDNSLogVerboseTag(0, frmt, ##__VA_ARGS__)
#define DDNSLogDebug(frmt, ...)     DDNSLogDebugTag(0, frmt, ##__VA_ARGS__)

#define DDNSLogStartBlock(msg)                                                                              \
    DDNS_LOG_MAYBE(DDNS_LOG_ASYNC_INFO, ddLogLevel,                                                         \
                   (DDNS_LOG_FLAG_INFO | DDNS_LOG_FLAG_START_BLOCK), 0, @"%@", msg)

#define DDNSLogEndBlock                                                                                     \
    DDNS_LOG_MAYBE(DDNS_LOG_ASYNC_INFO, ddLogLevel,                                                         \
                   (DDNS_LOG_FLAG_INFO | DDNS_LOG_FLAG_END_BLOCK), 0, nil, nil)

#define DDNSLogMarker(msg)                                                                                  \
    DDNS_LOG_MAYBE(DDNS_LOG_ASYNC_INFO, ddLogLevel,                                                         \
                   (DDNS_LOG_FLAG_INFO | DDNS_LOG_FLAG_MARKER), 0, nil, msg)

#define DDNSLogData(data)                                                                                   \
    DDNS_LOG_DATA_MAYBE(DDNS_LOG_ASYNC_VERBOSE, ddLogLevel,                                                 \
                        (DDNS_LOG_FLAG_VERBOSE | DDNS_LOG_FLAG_DATA), 0, data)

#define DDNSLogImage(image)                                                                                 \
    DDNS_LOG_IMAGE_MAYBE(DDNS_LOG_ASYNC_VERBOSE, ddLogLevel,                                                \
                         (DDNS_LOG_FLAG_VERBOSE | DDNS_LOG_FLAG_IMAGE), 0, image)

#define LogErrorTag(tag, ...)           DDNSLogErrorTag(tag, ##__VA_ARGS__)
#define LogWarnTag(tag, ...)            DDNSLogWarnTag(tag, ##__VA_ARGS__)
#define LogInfoTag(tag, ...)            DDNSLogInfoTag(tag, ##__VA_ARGS__)
#define LogVerboseTag(tag, ...)         DDNSLogVerboseTag(tag, ##__VA_ARGS__)
#define LogDebugTag(tag, ...)           DDNSLogDebugTag(tag, ##__VA_ARGS__)

#define LogError(...)                   LogErrorTag(0, ##__VA_ARGS__)
#define LogWarn(...)                    LogWarnTag(0, ##__VA_ARGS__)
#define LogInfo(...)                    LogInfoTag(0, ##__VA_ARGS__)
#define LogVerbose(...)                 LogVerboseTag(0, ##__VA_ARGS__)
#define LogDebug(...)                   LogDebugTag(0, ##__VA_ARGS__)

#define LogStartBlock(msg)              DDNSLogStartBlock(msg)
#define LogEndBlock                     DDNSLogEndBlock
#define LogMarkder(msg)                 DDNSLogMarker(msg)
#define LogData(data)                   DDNSLogData(data)
#define LogImage(image)                 DDNSLogImage(image)

#ifdef NSLOGGER_GANK_NSLOG
#define NSLog(...) LogInfoTag(@"NSLog", ##__VA_ARGS__)
#endif
