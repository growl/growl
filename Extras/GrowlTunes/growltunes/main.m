#import <Cocoa/Cocoa.h>
#import "LoggerClient.h"

int main(int argc, char *argv[])
{
    @autoreleasepool {
        // configures the default logger, but doesn't start it. this is deferred to the first log message
        Logger* nsl = LoggerGetDefaultLogger();
        NSString *bufferPath = [NSHomeDirectory() stringByAppendingPathComponent:@"GrowlTunesTemp.rawnsloggerdata"];
        LoggerSetBufferFile(nsl, (__bridge CFStringRef)bufferPath);
        LoggerSetViewerHost(nsl, CFSTR("127.0.0.1"), 50000);
        LoggerSetOptions(nsl, kLoggerOption_BufferLogsUntilConnection |
                            kLoggerOption_UseSSL | kLoggerOption_BrowseBonjour);
    }
    
    return NSApplicationMain(argc, (const char **)argv);
}
