//
//  FormattingPreferencesProxy.m
//  GrowlTunes
//
//  Created by Travis Tilley on 11/24/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "FormattingPreferencesHelper.h"
#import "FormattingToken.h"


@interface FormattingPreferencesHelper ()

@property(readwrite, STRONG, atomic) NSMutableDictionary* podcast;
@property(readwrite, STRONG, atomic) NSMutableDictionary* stream;
@property(readwrite, STRONG, atomic) NSMutableDictionary* show;
@property(readwrite, STRONG, atomic) NSMutableDictionary* movie;
@property(readwrite, STRONG, atomic) NSMutableDictionary* musicVideo;
@property(readwrite, STRONG, atomic) NSMutableDictionary* music;
@property(readwrite, STRONG, atomic) NSMutableArray *dictionaries;

-(NSArray*)tokenCloud;

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
@synthesize dictionaries = _dictionaries;

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

-(id)init {
	if((self = [super init])){
		
		_defaults = [NSUserDefaults standardUserDefaults];
		RETAIN(_defaults);
		[self loadDefaults];
	}
	return self;
}

-(void)dealloc
{
    RELEASE(_podcast);
    RELEASE(_stream);
    RELEASE(_show);
    RELEASE(_movie);
    RELEASE(_musicVideo);
    RELEASE(_music);
    RELEASE(_defaults);
	RELEASE(_dictionaries);
    SUPER_DEALLOC;
}

-(void)loadDefaults
{
	NSDictionary* format = [_defaults dictionaryForKey:@"format"];
	if (!format) format = [NSDictionary dictionary];
	
	NSArray* types = $array(formattingTypes);
	NSArray* attributes = $array(formattingAttributes);
	
	NSMutableArray *dictBuild = [NSMutableArray arrayWithCapacity:[types count]];
	for (NSString* type in types) {
		NSMutableDictionary* mutableValue;
		NSDictionary* immutableValue = [format objectForKey:type];
		
		if (immutableValue) {
			mutableValue = AUTORELEASE([immutableValue mutableCopy]);
		} else {
			mutableValue = AUTORELEASE([[NSMutableDictionary alloc] init]);
		}
		
		for (NSString* attribute in attributes) {
			NSMutableData* mutableAttribute;
			NSData* immutableAttribute = [mutableValue objectForKey:attribute];
			
			if (immutableAttribute) {
				mutableAttribute = AUTORELEASE([immutableAttribute mutableCopy]);
			} else {
				mutableAttribute = AUTORELEASE([[NSMutableData alloc] init]);
				NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:mutableAttribute];
				NSMutableArray* emptyArray = [NSMutableArray array];
				[archiver encodeRootObject:emptyArray];
				[archiver finishEncoding];
				RELEASE(archiver);
			}
			
			[mutableValue setValue:mutableAttribute forKey:attribute];
		}
		
		[mutableValue setValue:type forKey:@"formatType"];
		[dictBuild addObject:mutableValue];
		[self setValue:mutableValue forKey:type];
	}
	self.dictionaries = dictBuild;
}

-(void)saveDefaults
{
    NSMutableDictionary* newFormat = [NSMutableDictionary dictionary];
	[self.dictionaries enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		[newFormat setValue:obj forKey:[obj valueForKey:@"formatType"]];
	}];
    
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

-(NSArray*)tokenCloud {
	static NSArray *_tokenCloud = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSMutableArray *buildArray = [NSMutableArray array];
		[[[FormattingToken tokenMap] allKeys] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			[buildArray addObject:[NSString stringWithFormat:@"[%@]", obj]];
		}];
		_tokenCloud = [buildArray copy];
	});
	return _tokenCloud;
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
    return AUTORELEASE([[FormattingToken alloc] initWithEditingString:editingString]);
}

- (NSTokenStyle)tokenField:(NSTokenField *)tokenField styleForRepresentedObject:(id)representedObject
{
    if ([representedObject respondsToSelector:@selector(tokenStyle)]) {
        return (NSTokenStyle)[representedObject performSelector:@selector(tokenStyle)];
    }
    return NSPlainTextTokenStyle;
}

- (NSArray*)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(NSUInteger)index {
	[self saveDefaults];
	return tokens;
}

- (NSArray*)tokenField:(NSTokenField *)tokenField readFromPasteboard:(NSPasteboard *)pboard {
	NSMutableArray *results = [NSMutableArray array];
	NSArray *pBoardItems = [pboard readObjectsForClasses:[NSArray arrayWithObject:[NSString class]] options:nil];
	[pBoardItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		FormattingToken *token = [[FormattingToken alloc] initWithEditingString:obj];
		[results addObject:token];
		RELEASE(token);
	}];
	return results;
}

- (BOOL)tokenField:(NSTokenField *)tokenField writeRepresentedObjects:(NSArray *)objects toPasteboard:(NSPasteboard *)pboard {
	[pboard writeObjects:[objects valueForKey:@"editingString"]];
	return YES;
}

@end
