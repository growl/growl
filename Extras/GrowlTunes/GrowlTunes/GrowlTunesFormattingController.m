//
//  GrowlTunesFormattingController.m
//  GrowlTunes
//
//  Created by Daniel Siemer on 11/18/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlTunesFormattingController.h"
#import "FormattingToken.h"

@interface GrowlTunesFormattingController ()

@property (nonatomic, STRONG) NSDictionary *tokenDicts;

@end

@implementation GrowlTunesFormattingController

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
	if (self == [GrowlTunesFormattingController class]) {
		NSNumber *logLevel = [[NSUserDefaults standardUserDefaults] objectForKey:
									 [NSString stringWithFormat:@"%@LogLevel", [self class]]];
		if (logLevel)
			ddLogLevel = [logLevel intValue];
	}
}

-(id)init {
	if((self = [super init])){
		[self loadTokens];
	}
	return self;
}

-(void)dealloc
{
	RELEASE(_tokenDicts);
	SUPER_DEALLOC;
}

-(NSArray*)tokenCloud {
	static NSArray *_tokenCloud = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSMutableArray *buildArray = [NSMutableArray array];
		[[[FormattingToken tokenMap] allKeys] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			NSString *editString = [NSString stringWithFormat:@"[%@]", obj];
			FormattingToken *token = [FormattingToken tokenWithEditingString:editString];
			[buildArray addObject:token];
		}];
		_tokenCloud = [buildArray copy];
	});
	return _tokenCloud;
}

-(NSArray*)allTokenDicts {
	return [_tokenDicts allValues];
}

-(NSArray*)tokensForType:(NSString*)type andAttribute:(NSString*)attribute {
	NSDictionary *typeDict = [_tokenDicts valueForKey:type];
	NSMutableData *arrayData = [typeDict valueForKey:attribute];
	NSValueTransformer *transformer = [NSValueTransformer valueTransformerForName:NSKeyedUnarchiveFromDataTransformerName];
	return [transformer transformedValue:arrayData];
}

-(void)loadTokens {
	NSDictionary *format = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"format"];
	if (!format) format = [NSDictionary dictionary];
	
	NSArray *types = @[formattingTypes];
	NSArray *attributes = @[formattingAttributes];
	
	NSMutableDictionary *dictBuild = [NSMutableDictionary dictionaryWithCapacity:[types count]];
	[types enumerateObjectsUsingBlock:^(id type, NSUInteger typeIDX, BOOL *typeStop) {
		NSMutableDictionary *mutableValue = nil;
		NSDictionary *immutableValue = [format objectForKey:type];
		
		if (immutableValue) {
			mutableValue = AUTORELEASE([immutableValue mutableCopy]);
		} else {
			mutableValue = AUTORELEASE([[NSMutableDictionary alloc] init]);
		}
		
		[attributes enumerateObjectsUsingBlock:^(id attribute, NSUInteger attributeIDX, BOOL *attributeStop) {
			NSMutableData *mutableAttribute = nil;
			NSData *immutableAttribute = [mutableValue objectForKey:attribute];
			
			if (immutableAttribute) {
				mutableAttribute = AUTORELEASE([immutableAttribute mutableCopy]);
			} else {
				mutableAttribute = AUTORELEASE([[NSMutableData alloc] init]);
				NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:mutableAttribute];
				NSMutableArray *emptyArray = [NSMutableArray array];
				[archiver encodeRootObject:emptyArray];
				[archiver finishEncoding];
				RELEASE(archiver);
			}
			
			[mutableValue setValue:mutableAttribute forKey:attribute];
		}];
		
		//Replace with localized type
		[mutableValue setObject:type forKey:@"formatType"];
		[dictBuild setObject:mutableValue forKey:type];
	}];
	self.tokenDicts = dictBuild;
}

-(void)saveTokens {
	NSMutableDictionary *saveDict = [NSMutableDictionary dictionaryWithCapacity:[[_tokenDicts allKeys] count]];
	[_tokenDicts enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		[saveDict setValue:[obj dictionaryWithValuesForKeys:@[formattingAttributes]] forKey:key];
	}];
	[[NSUserDefaults standardUserDefaults] setValue:saveDict forKey:@"format"];
}

@end
