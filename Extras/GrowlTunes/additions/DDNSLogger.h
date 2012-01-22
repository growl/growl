//
//  DDNSLogger.h
//
//  Created by Travis Tilley on 12/19/11.
//  Copyright (c) 2011 Travis Tilley. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import "LoggerClient.h"
#import "DDLog.h"


@interface DDLogMessage (DDNSLogger)

-(NSData *)logData;

-(NSImage *)logImage;

-(void)setLogData:(NSData *)logData;

-(void)setLogImage:(NSImage *)logImage;

-(id)initWithLogData:(NSData *)logData 
               level:(int)ilogLevel 
                flag:(int)ilogFlag 
             context:(int)ilogContext 
                file:(const char *)srcFile 
            function:(const char *)srcFunction
                line:(int)srcLine 
                 tag:(NSString *)tag;

-(id)initWithLogImage:(NSImage *)logImage
                level:(int)ilogLevel
                 flag:(int)ilogFlag
              context:(int)ilogContext 
                 file:(const char *)srcFile
             function:(const char *)srcFunction
                 line:(int)srcLine 
                  tag:(NSString *)tag;

@end


@interface DDLog (DDNSLogger)

+(void)log:(BOOL)asynchronous
     level:(int)level
      flag:(int)flag
   context:(int)context 
      file:(const char *)file
  function:(const char *)function
      line:(int)line 
       tag:(NSString *)tag
      data:(NSData *)data;

+(void)log:(BOOL)asynchronous
     level:(int)level
      flag:(int)flag
   context:(int)context 
      file:(const char *)file
  function:(const char *)function
      line:(int)line 
       tag:(NSString *)tag
     image:(NSImage *)image;

@end


@interface DDNSLogger : DDAbstractLogger <DDLogger> {
    @private    
    Logger* nslogger;
}

+(DDNSLogger*)sharedInstance;

-(NSString*)loggerName;
-(void)logMessage:(DDLogMessage*)logMessage;

@end

