//
//  DDNSLogger.m
//
//  Created by Travis Tilley on 12/19/11.
//  Copyright (c) 2011 Travis Tilley. All rights reserved.
//

#import <objc/objc-runtime.h>
#import "DDNSLogger.h"
#import "DDNSLogging.h"


@implementation DDLogMessage (DDNSLogger)

static char dataKey;
static char imageKey;

-(void)setAssociatedObject:(id)obj forKey:(void*)key
{
    objc_setAssociatedObject(self, key, obj, OBJC_ASSOCIATION_RETAIN);
}

-(id)getAssociatedObjectOfType:(void*)key
{
    return [[objc_getAssociatedObject(self, key) retain] autorelease];
}

-(NSData *)logData
{
    return [self getAssociatedObjectOfType:&dataKey];
}

-(NSImage *)logImage
{
    return [self getAssociatedObjectOfType:&imageKey];
}

-(void)setLogData:(NSData *)logData
{
    [self setAssociatedObject:logData forKey:&dataKey];
}

-(void)setLogImage:(NSImage *)logImage
{
    [self setAssociatedObject:logImage forKey:&imageKey];
}

-(id)initWithLogData:(NSData *)logData 
               level:(int)ilogLevel 
                flag:(int)ilogFlag 
             context:(int)ilogContext 
                file:(const char *)srcFile 
            function:(const char *)srcFunction 
                line:(int)srcLine 
                 tag:(id)tagobj
{
    self = [self initWithLogMsg:@"data message" 
                          level:ilogLevel 
                           flag:ilogFlag 
                        context:ilogContext 
                           file:srcFile 
                       function:srcFunction 
                           line:srcLine 
                            tag:(id)tagobj];
    if (self) {
        [self setLogData:logData];
    }
    return self;
}

-(id)initWithLogImage:(NSImage *)logImage
                level:(int)ilogLevel
                 flag:(int)ilogFlag
              context:(int)ilogContext
                 file:(const char *)srcFile
             function:(const char *)srcFunction
                 line:(int)srcLine 
                  tag:(id)tagobj
{
    self = [self initWithLogMsg:@"image message" 
                          level:ilogLevel 
                           flag:ilogFlag 
                        context:ilogContext 
                           file:srcFile 
                       function:srcFunction 
                           line:srcLine 
                            tag:(id)tagobj];
    if (self) {
        [self setLogImage:logImage];
    }
    return self;
}

@end


@implementation DDLog (DDNSLogger)

+(void)log:(BOOL)asynchronous
     level:(int)level
      flag:(int)flag
   context:(int)context
      file:(const char *)file
  function:(const char *)function
      line:(int)line 
       tag:(id)tag
      data:(NSData *)data
{
    DDLogMessage* logMessage = [[DDLogMessage alloc] initWithLogData:data 
                                                               level:level 
                                                                flag:flag 
                                                             context:context 
                                                                file:file 
                                                            function:function 
                                                                line:line 
                                                                 tag:(id)tag];
    [self queueLogMessage:logMessage asynchronously:asynchronous];
    [logMessage release];
}

+(void)log:(BOOL)asynchronous
     level:(int)level
      flag:(int)flag
   context:(int)context
      file:(const char *)file
  function:(const char *)function
      line:(int)line 
       tag:(id)tag
     image:(NSImage *)image
{
    DDLogMessage* logMessage = [[DDLogMessage alloc] initWithLogImage:image 
                                                                level:level 
                                                                 flag:flag 
                                                              context:context 
                                                                 file:file 
                                                             function:function 
                                                                 line:line 
                                                                  tag:(id)tag];
    [self queueLogMessage:logMessage asynchronously:asynchronous];
    [logMessage release];
}

@end


@implementation DDNSLogger

__strong static DDNSLogger* sharedInstance;

+(DDNSLogger*)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DDNSLogger alloc] init];
    });
    return sharedInstance;
}

-(id)init
{
    if (sharedInstance != nil) {
        [self release];
        return sharedInstance;
    }
    
    self = [super init];
    if (self) {
        nslogger = LoggerInit();
        LoggerSetOptions(nslogger, DDNSLoggerDefaultOptions);
        NSString *bufferPath = [NSHomeDirectory() stringByAppendingPathComponent:
                                [NSString stringWithCString:DDNSLoggerDefaultBufferFilename 
                                                   encoding:NSUTF8StringEncoding]];
        LoggerSetBufferFile(nslogger, (__bridge CFStringRef)bufferPath);
        LoggerSetViewerHost(nslogger, CFSTR(DDNSLoggerDefaultHost), 50000);
        LoggerSetupBonjour(nslogger, NULL, CFSTR(DDNSLoggerDefaultService));
    }
    return self;
}

-(void)dealloc
{
    LoggerFlush(nslogger, NO);
    LoggerStop(nslogger);
    [super dealloc];
}

-(NSString*)loggerName
{
    return @"com.teaspoonofinsanity.DDNSLogger";
}

-(void)logMessage:(DDLogMessage*)logMessage
{
    [logMessage retain];
    
    BOOL isData         = (BOOL)(logMessage->logFlag & DDNS_LOG_FLAG_DATA);
    BOOL isImage        = (BOOL)(logMessage->logFlag & DDNS_LOG_FLAG_IMAGE);
    BOOL isStartBlock   = (BOOL)(logMessage->logFlag & DDNS_LOG_FLAG_START_BLOCK);
    BOOL isEndBlock     = (BOOL)(logMessage->logFlag & DDNS_LOG_FLAG_END_BLOCK);
    BOOL isMarker       = (BOOL)(logMessage->logFlag & DDNS_LOG_FLAG_MARKER);
    BOOL isMessage      = (!isData && !isImage && !isStartBlock && !isEndBlock && !isMarker);
    
    NSString* logMsg = nil;
    if (formatter) {
        logMsg = [formatter formatLogMessage:logMessage];
    } else {
        logMsg = logMessage->logMsg;
    }
    
    // nslogger uses levels 0-4 to filter messages, with higher levels including lower level messages
    int nsloggerlevel;
    switch (logMessage->logFlag) {
        case DDNS_LOG_FLAG_ERROR    : nsloggerlevel = 0;    break;
        case DDNS_LOG_FLAG_WARN     : nsloggerlevel = 1;    break;
        case DDNS_LOG_FLAG_INFO     : nsloggerlevel = 2;    break;
        case DDNS_LOG_FLAG_VERBOSE  : nsloggerlevel = 3;    break;
        case DDNS_LOG_FLAG_DEBUG    : nsloggerlevel = 4;    break;
        default                     : nsloggerlevel = 4;    break;
    }
    
    // nslogger also allows you to filter messages based on tag
    NSString* tag = nil;
    if (logMessage->tag) {
        tag = [NSString stringWithFormat:@"%@", logMessage->tag];
    }
    
    if (isMessage) {
        LogMessageToF(nslogger,
                      logMessage->file, logMessage->lineNumber, logMessage->function,
                      tag, nsloggerlevel,
                      @"%@", logMsg);
    } else if (isData) {
        LogDataToF(nslogger,
                   logMessage->file, logMessage->lineNumber, logMessage->function,
                   tag, nsloggerlevel,
                   [logMessage logData]);
    } else if (isImage) {
        NSImage* image = [logMessage logImage];
        NSSize size = image.size;
        
        LogImageDataToF(nslogger, 
                        logMessage->file, logMessage->lineNumber, logMessage->function, 
                        tag, nsloggerlevel, 
                        (int)size.width, (int)size.height, [image TIFFRepresentation]);
    } else if (isStartBlock) {
        LogStartBlockTo(nslogger, logMessage->logMsg);
    } else if (isEndBlock) {
        LogEndBlockTo(nslogger);
    } else if (isMarker) {
        LogMarkerTo(nslogger, logMessage->logMsg);
    }
    
    [logMessage release];
}

@end
