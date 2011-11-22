#import "LoggerClient.h"
#import "SPLowVerbosity.h"
#import "SPDepends.h"

#define $bool(val) [NSNumber numberWithBool:val]


#if defined(DEBUG) && !defined(NDEBUG)
#   undef assert
#   if __DARWIN_UNIX03
#       define assert(e) \
            (__builtin_expect(!(e), 0) ? (CFShow(CFSTR("assert going to fail, connect NSLogger NOW\n")), LoggerFlush(NULL,YES), __assert_rtn(__func__, __FILE__, __LINE__, #e)) : (void)0)
#   else
#       define assert(e)  \
            (__builtin_expect(!(e), 0) ? (CFShow(CFSTR("assert going to fail, connect NSLogger NOW\n")), LoggerFlush(NULL,YES), __assert(#e, __FILE__, __LINE__)) : (void)0)
#   endif
#endif


#define LOG_FLAG_ERROR    (1 << 0)  // 0...0001
#define LOG_FLAG_WARN     (1 << 1)  // 0...0010
#define LOG_FLAG_INFO     (1 << 2)  // 0...0100
#define LOG_FLAG_VERBOSE  (1 << 3)  // 0...1000

#define LOG_LEVEL_OFF     0
#define LOG_LEVEL_ERROR   (LOG_FLAG_ERROR)                                                    // 0...0001
#define LOG_LEVEL_WARN    (LOG_FLAG_ERROR | LOG_FLAG_WARN)                                    // 0...0011
#define LOG_LEVEL_INFO    (LOG_FLAG_ERROR | LOG_FLAG_WARN | LOG_FLAG_INFO)                    // 0...0111
#define LOG_LEVEL_VERBOSE (LOG_FLAG_ERROR | LOG_FLAG_WARN | LOG_FLAG_INFO | LOG_FLAG_VERBOSE) // 0...1111

#define LOG_ERROR   (_LogLevel & LOG_FLAG_ERROR)
#define LOG_WARN    (_LogLevel & LOG_FLAG_WARN)
#define LOG_INFO    (_LogLevel & LOG_FLAG_INFO)
#define LOG_VERBOSE (_LogLevel & LOG_FLAG_VERBOSE)

#define LOG_MACRO(level, flag, tag, ...)                        \
do {                                                            \
    if (level & flag) {                                         \
        int nsloggerlevel;                                      \
        switch(flag) {                                          \
            case LOG_FLAG_ERROR     : nsloggerlevel = 1; break; \
            case LOG_FLAG_WARN      : nsloggerlevel = 2; break; \
            case LOG_FLAG_INFO      : nsloggerlevel = 3; break; \
            case LOG_FLAG_VERBOSE   : nsloggerlevel = 4; break; \
            default                 : nsloggerlevel = 0; break; \
        }                                                       \
        LogMessageF(__FILE__, __LINE__, __PRETTY_FUNCTION__,    \
                    tag, nsloggerlevel, ##__VA_ARGS__);         \
    }                                                           \
} while(0)

#define LogErrorTag(tag, ...)   LOG_MACRO(_LogLevel, LOG_FLAG_ERROR, tag, ##__VA_ARGS__)
#define LogWarnTag(tag, ...)    LOG_MACRO(_LogLevel, LOG_FLAG_WARN, tag, ##__VA_ARGS__)
#define LogInfoTag(tag, ...)    LOG_MACRO(_LogLevel, LOG_FLAG_INFO, tag, ##__VA_ARGS__)
#define LogVerboseTag(tag, ...) LOG_MACRO(_LogLevel, LOG_FLAG_VERBOSE, tag, ##__VA_ARGS__)

#define LogError(...)   LogErrorTag(nil, ##__VA_ARGS__)
#define LogWarn(...)    LogWarnTag(nil, ##__VA_ARGS__)
#define LogInfo(...)    LogInfoTag(nil, ##__VA_ARGS__)
#define LogVerbose(...) LogVerboseTag(nil, ##__VA_ARGS__)


#define LogImage(tag, obj) do {                                                 \
    NSImage* __image = $cast(NSImage, obj);                                     \
    NSData* __data = [__image TIFFRepresentation];                              \
    NSSize __size = __image.size;                                               \
    LogImageDataF(__FILE__, __LINE__, __PRETTY_FUNCTION__,                      \
                    tag, 4, (int)__size.width, (int)__size.height, __data);     \
} while(0)


#ifdef NSLOGGER_GANK_NSLOG
#define NSLog(...) LogInfoTag(@"NSLog", ##__VA_ARGS__)
#endif


#ifdef DEBUG
    #define setLogLevel(localName) do {_LogLevel = LOG_LEVEL_VERBOSE;} while(0)
#else
    #define setLogLevel(localName) do {                                         \
        NSUserDefaults* udef = [NSUserDefaults standardUserDefaults];           \
        NSString* globalKey = @"LogLevel";                                      \
        NSString* localKey = @localName globalKey;                              \
        int localLogLevel = (int)[udef integerForKey:localKey];                 \
        int globalLogLevel = (int)[udef integerForKey:globalKey];               \
        _LogLevel = (localLogLevel == 0) ? globalLogLevel : localLogLevel;      \
    } while(0)
#endif

