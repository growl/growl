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
		[buildArray sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
			return [[obj1 displayString] caseInsensitiveCompare:[obj2 displayString]];
		}];
		_tokenCloud = [buildArray copy];
	});
	return _tokenCloud;
}

-(NSArray*)allTokenDicts {
	return [[_tokenDicts allValues] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		return [[obj1 valueForKey:@"formatTypeReadable"] caseInsensitiveCompare:[obj2 valueForKey:@"formatTypeReadable"]];
	}];
}

-(NSArray*)tokensForType:(NSString*)type andAttribute:(NSString*)attribute {
	NSDictionary *typeDict = [_tokenDicts valueForKey:type];
	return [typeDict valueForKey:attribute];
}

- (id)localizedStringsController
{
	id returnValue = [[NSApp delegate] performSelector:@selector(localizedStringsController)];
	return returnValue;
}

-(void)loadTokens {
	NSDictionary *format = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"format"];
	if (!format) format = [NSDictionary dictionary];
	
	NSArray *types = @[formattingTypes];
	NSDictionary *readableDict = [NSDictionary dictionaryWithObjects:@[[[self localizedStringsController] stringForKey:@"PodcastFormatTitle"],[[self localizedStringsController] stringForKey:@"StreamFormatTitle"],[[self localizedStringsController] stringForKey:@"ShowFormatTitle"],[[self localizedStringsController] stringForKey:@"MovieFormatTitle"],[[self localizedStringsController] stringForKey:@"MusicVideoFormatTitle"],[[self localizedStringsController] stringForKey:@"MusicFormatTitle"]] forKeys:types];
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
			NSArray *attributeArray = [mutableValue objectForKey:attribute];
			NSMutableArray *buildArray = [NSMutableArray arrayWithCapacity:[attributeArray count]];
			[attributeArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				FormattingToken *token = [FormattingToken tokenWithEditingString:obj];
				[buildArray addObject:token];
			}];
			[mutableValue setValue:buildArray forKey:attribute];
		}];
		
		NSArray *fileNames = @[typeFileNames];
		NSUInteger typeIndex = [types indexOfObject:type];
		NSString *resourceName = [NSString stringWithFormat:@"Notifications-%@", [fileNames objectAtIndex:typeIndex]];
		NSURL *urlForIcon = ([[NSBundle mainBundle] URLForImageResource:resourceName]?:[[NSBundle mainBundle] URLForImageResource:@"GrowlTunes.icns"]);

		//Replace with localized type
		[mutableValue setObject:type forKey:@"formatType"];
		[mutableValue setObject:[readableDict valueForKey:type] forKey:@"formatTypeReadable"];
		[mutableValue setObject:urlForIcon forKey:@"formatIconURL"];
		[dictBuild setObject:mutableValue forKey:type];
	}];
	self.tokenDicts = dictBuild;
}

-(void)saveTokens {
	NSMutableDictionary *saveDict = [NSMutableDictionary dictionaryWithCapacity:[[_tokenDicts allKeys] count]];
	[_tokenDicts enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		NSMutableDictionary *typeDict = [NSMutableDictionary dictionary];
		[typeDict setValue:[obj valueForKey:@"enabled"] forKey:@"enabled"];
		[@[formattingAttributes] enumerateObjectsUsingBlock:^(id attribute, NSUInteger idx, BOOL *attributeStop) {
			NSMutableArray *tokenArray = [obj valueForKey:attribute];
			NSMutableArray *buildArray = [NSMutableArray arrayWithCapacity:[tokenArray count]];
			[tokenArray enumerateObjectsUsingBlock:^(id token, NSUInteger tokenIdx, BOOL *tokenStop) {
				[buildArray addObject:[token editingString]];
			}];
			[typeDict setObject:buildArray forKey:attribute];
		}];
		[saveDict setValue:typeDict forKey:key];
	}];
	[[NSUserDefaults standardUserDefaults] setValue:saveDict forKey:@"format"];
}

-(BOOL)isFormatTypeEnabled:(NSString*)type {
	return [[[_tokenDicts valueForKey:type] valueForKey:@"enabled"] boolValue];
}

@end
