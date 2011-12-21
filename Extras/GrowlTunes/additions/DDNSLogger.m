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
{
    self = [self initWithLogMsg:@"data message" 
                          level:ilogLevel 
                           flag:ilogFlag 
                        context:ilogContext 
                           file:srcFile 
                       function:srcFunction 
                           line:srcLine];
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
{
    self = [self initWithLogMsg:@"image message" 
                          level:ilogLevel 
                           flag:ilogFlag 
                        context:ilogContext 
                           file:srcFile 
                       function:srcFunction 
                           line:srcLine];
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
      data:(NSData *)data
{
    DDLogMessage* logMessage = [[DDLogMessage alloc] initWithLogData:data 
                                                               level:level 
                                                                flag:flag 
                                                             context:context 
                                                                file:file 
                                                            function:function 
                                                                line:line];
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
     image:(NSImage *)image
{
    DDLogMessage* logMessage = [[DDLogMessage alloc] initWithLogImage:image 
                                                                level:level 
                                                                 flag:flag 
                                                              context:context 
                                                                 file:file 
                                                             function:function 
                                                                 line:line];
    [self queueLogMessage:logMessage asynchronously:asynchronous];
    [logMessage release];
}

@end


@implementation DDNSLoggerTagMap

-(id)init
{
    self = [super init];
    if (self) {
        _map = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)addTag:(NSString *)tag forContext:(int)loggingContext
{
    OSSpinLockLock(&_lock);
    {
        [_map setValue:[NSNumber numberWithInt:loggingContext] forKey:tag];
    }
    OSSpinLockUnlock(&_lock);
}

-(void)addContext:(int)loggingContext forTag:(NSString *)tag
{
    [self addTag:tag forContext:loggingContext];
}

-(NSDictionary *)currentMap
{
    NSDictionary* result = nil;
    
    OSSpinLockLock(&_lock);
    {
        result = [_map copy];
    }
    OSSpinLockUnlock(&_lock);
    
    return [result autorelease];
}

-(BOOL)tagIsInMap:(NSString *)tag
{
    BOOL result = NO;
    
    OSSpinLockLock(&_lock);
    {
        NSArray* tags = [_map allKeys];
        result = [tags containsObject:tag];
    }
    OSSpinLockUnlock(&_lock);
    
    return result;
}

-(BOOL)contextIsInMap:(int)loggingContext
{
    BOOL result = NO;
    
    OSSpinLockLock(&_lock);
    {
        NSArray* contexts = [_map allValues];
        result = [contexts containsObject:[NSNumber numberWithInt:loggingContext]];
    }
    OSSpinLockUnlock(&_lock);
    
    return result;
}

-(int)getContextForTag:(NSString *)tag
{
    int result = -1;
    
    OSSpinLockLock(&_lock);
    {
        result = [[_map valueForKey:tag] intValue];
    }
    OSSpinLockUnlock(&_lock);
    
    return result;
}

-(NSString *)getTagForContext:(int)loggingContext
{
    NSString* __block tag = nil;
    
    OSSpinLockLock(&_lock);
    {
        NSNumber* wrapped = [NSNumber numberWithInt:loggingContext];
        [_map enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([wrapped isEqualToNumber:obj]) {
                tag = key;
                *stop = YES;
            }
        }];
    }
    OSSpinLockUnlock(&_lock);
    
    return tag;
}

@end


@implementation DDNSLogger

__strong static DDNSLogger* sharedInstance;

+(void)initialize
{
    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        sharedInstance = [[DDNSLogger alloc] init];
    }
}

+(DDNSLogger*)sharedInstance
{
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
        tagMap = [[DDNSLoggerTagMap alloc] init];
        nslogger = LoggerInit();
        LoggerSetOptions(nslogger, DDNSLoggerDefaultOptions);
        NSString *bufferPath = [NSHomeDirectory() stringByAppendingPathComponent:
                                [NSString stringWithCString:DDNSLoggerDefaultBufferFilename 
                                                   encoding:NSUTF8StringEncoding]];
        LoggerSetBufferFile(nslogger, (__bridge CFStringRef)bufferPath);
        CFStringRef host = CFSTR(DDNSLoggerDefaultHost);
        LoggerSetViewerHost(nslogger, host, 50000);
        CFRelease(host);
        CFStringRef serviceName = CFSTR(DDNSLoggerDefaultService);
        LoggerSetupBonjour(nslogger, NULL, serviceName);
        CFRelease(serviceName);
        LoggerStart(nslogger);
    }
    return self;
}

-(void)dealloc
{
    LoggerFlush(nslogger, NO);
    LoggerStop(nslogger);
    [tagMap release];
    [super dealloc];
}

-(NSString*)loggerName
{
    return @"com.teaspoonofinsanity.DDNSLogger";
}

-(void)addTag:(NSString*)tag forContext:(int)loggingContext
{    
    dispatch_block_t block = ^{
        [tagMap addTag:tag forContext:loggingContext]; 
    };
    
    if (dispatch_get_current_queue() == loggerQueue) {
        block();
    } else {
        dispatch_async([DDLog loggingQueue], block);
    }
}

-(DDNSLoggerTagMap*)tagMap
{
    if (dispatch_get_current_queue() == loggerQueue) {
        return [[tagMap retain] autorelease];
    }
    
    __block DDNSLoggerTagMap* map;
    
    dispatch_async([DDLog loggingQueue], ^{
        map = [tagMap retain];
    });
    
    return [map autorelease];
}

-(void)logMessage:(DDLogMessage*)logMessage
{
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
    
    // nslogger also allows you to filter messages based on tag. we're piggybacking on the context bitfield for this
    NSString* tag = nil;
    if ([tagMap contextIsInMap:logMessage->logContext]) {
        tag = [[[tagMap getTagForContext:logMessage->logContext] retain] autorelease];
    } else if (logMessage->logContext != 0) {
        tag = @"unknown";
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
}

@end
