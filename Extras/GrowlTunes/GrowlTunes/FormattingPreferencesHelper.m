//
//  FormattingPreferencesProxy.m
//  GrowlTunes
//
//  Created by Travis Tilley on 11/24/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "FormattingPreferencesHelper.h"
#import "macros.h"
#import "FormattingToken.h"


@interface FormattingPreferencesHelper ()

@property(readwrite, retain, atomic) NSMutableDictionary* podcast;
@property(readwrite, retain, atomic) NSMutableDictionary* stream;
@property(readwrite, retain, atomic) NSMutableDictionary* show;
@property(readwrite, retain, atomic) NSMutableDictionary* movie;
@property(readwrite, retain, atomic) NSMutableDictionary* musicVideo;
@property(readwrite, retain, atomic) NSMutableDictionary* music;

-(void)loadDefaults;
-(void)saveDefaults;

@end


@implementation FormattingPreferencesHelper

@synthesize podcast = _podcast;
@synthesize stream = _stream;
@synthesize show = _show;
@synthesize movie = _movie;
@synthesize musicVideo = _musicVideo;
@synthesize music = _music;

static int ddLogLevel = DDNS_LOG_LEVEL_DEFAULT;

+ (int)ddLogLevel
{
    return ddLogLevel;
}

+ (void)ddSetLogLevel:(int)logLevel
{
    ddLogLevel = logLevel;
}

+ (void)initialize
{
    if (self == [FormattingPreferencesHelper class]) {
        NSNumber *logLevel = [[NSUserDefaults standardUserDefaults] objectForKey:
                              [NSString stringWithFormat:@"%@LogLevel", [self class]]];
        if (logLevel)
            ddLogLevel = [logLevel intValue];
    }
}

-(id)init
{
    self = [super init];
    
    _defaults = [NSUserDefaults standardUserDefaults];
    [self loadDefaults];
    
    return self;
}

-(void)loadDefaults
{
    NSDictionary* format = [_defaults dictionaryForKey:@"format"];
    if (!format) format = [NSDictionary dictionary];
    
    NSArray* types = $array(formattingTypes);
    NSArray* attributes = $array(formattingAttributes);
    
    for (NSString* type in types) {
        NSMutableDictionary* mutableValue;
        NSDictionary* immutableValue = [format objectForKey:type];
        
        if (immutableValue) {
            mutableValue = [immutableValue mutableCopy];
        } else {
            mutableValue = [NSMutableDictionary dictionary];
        }
        
        for (NSString* attribute in attributes) {
            NSMutableData* mutableAttribute;
            NSData* immutableAttribute = [mutableValue objectForKey:attribute];
            
            if (immutableAttribute) {
                mutableAttribute = [immutableAttribute mutableCopy];
            } else {
                mutableAttribute = [NSMutableData data];
                NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:mutableAttribute];
                NSMutableArray* emptyArray = [NSMutableArray array];
                [archiver encodeRootObject:emptyArray];
                [archiver finishEncoding];
            }
            
            [mutableValue setValue:mutableAttribute forKey:attribute];
        }
        
        [self setValue:mutableValue forKey:type];
    }
}

-(void)saveDefaults
{
    NSMutableDictionary* newFormat = [NSMutableDictionary dictionary];
    NSArray* types = $array(formattingTypes);
    for (NSString* type in types) {
        NSMutableDictionary* value = [self valueForKey:type];
        [newFormat setValue:value forKey:type];
    }
    
    [_defaults setValue:newFormat forKey:@"format"];
}

-(void)setValue:(id)value forKey:(NSString *)key
{
    [super setValue:value forKey:key];
    [self saveDefaults];
}

-(void)setValue:(id)value forKeyPath:(NSString *)keyPath
{
    [super setValue:value forKeyPath:keyPath];
    [self saveDefaults];
}

-(NSArray*)tokensForType:(NSString*)type andAttribute:(NSString*)attribute
{
    NSMutableDictionary* td = [self valueForKey:type];
    if (!td) return nil;
    
    NSMutableData* ad = [td valueForKey:attribute];
    if (!ad) return nil;
    
    NSValueTransformer* vt = [NSValueTransformer valueTransformerForName:NSKeyedUnarchiveFromDataTransformerName];
    return [vt transformedValue:ad];
}

- (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject
{
    if ([representedObject respondsToSelector:@selector(displayString)]) {
        return [representedObject valueForKey:@"displayString"];
    }
    return representedObject;
}

- (NSString *)tokenField:(NSTokenField *)tokenField editingStringForRepresentedObject:(id)representedObject
{
    if ([representedObject respondsToSelector:@selector(editingString)]) {
        return [representedObject valueForKey:@"editingString"];
    }
    return representedObject;
}

- (id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString
{
    return [[FormattingToken alloc] initWithEditingString:editingString];
}

- (NSTokenStyle)tokenField:(NSTokenField *)tokenField styleForRepresentedObject:(id)representedObject
{
    if ([representedObject respondsToSelector:@selector(tokenStyle)]) {
        return (NSTokenStyle)[representedObject performSelector:@selector(tokenStyle)];
    }
    return NSPlainTextTokenStyle;
}

@end
