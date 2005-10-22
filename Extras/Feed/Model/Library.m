/*

BSD License

Copyright (c) 2005, Keith Anderson
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

*	Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.
*	Redistributions in binary form must reproduce the above copyright notice,
	this list of conditions and the following disclaimer in the documentation
	and/or other materials provided with the distribution.
*	Neither the name of keeto.net or Keith Anderson nor the names of its
	contributors may be used to endorse or promote products derived
	from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


*/

#import "Library.h"


#define FeedLibDirectory @"Feed"
#define FeedCacheDirectory @"Cache"
#define FeedBackupFileExtension @".~bak"
#define FeedLibFilename @"Data.feed"

@implementation Library

static Library *				_sharedLibrary = nil;
+(id)sharedLibrary{
	if( ! _sharedLibrary ){
		_sharedLibrary = [[Library alloc] init];
	}
	return _sharedLibrary;
}

+(NSString *)defaultLibraryFolder{
	NSArray *					paths;
	NSFileManager *				fileManager = [NSFileManager defaultManager];
	
	paths = NSSearchPathForDirectoriesInDomains( NSLibraryDirectory, NSUserDomainMask, YES );
	if( [paths count] == 0 ){
		KNDebug(@"Unable to locate users Library directory!");
		return nil;
	}
	
	if( ! [fileManager fileExistsAtPath: [paths objectAtIndex:0]] ){
		KNDebug(@"LIB: User Library directory doesn't exist!");
		return nil;
	}
	
	return [[paths objectAtIndex:0] stringByAppendingPathComponent: FeedLibDirectory];
}

+(NSString *)defaultStoragePath{
	return [[Library defaultLibraryFolder] stringByAppendingPathComponent: FeedLibFilename];
}

+(NSString *)cacheLocation{
	NSFileManager *			fileManager = [NSFileManager defaultManager];
	NSString *				currentPath = [[Library defaultLibraryFolder] stringByAppendingPathComponent: FeedCacheDirectory];
	
	if( ! [fileManager fileExistsAtPath: currentPath] ){
		KNDebug(@"LIB: No cache directory found at %@. Creating", currentPath);
		if( ! [fileManager createDirectoryAtPath: currentPath attributes: [NSDictionary dictionary]] ){
			KNDebug(@"LIB: Unable to create cache directory");
			return nil;
		}
	}
		
	return currentPath;
}


-(id)init{
	if( ! _sharedLibrary ){
		if( (self = [super init]) ){
			rootItem = [[KNItem alloc] init];
			storagePath = [[Library defaultStoragePath] retain];
			isDirty = NO;
			unreadFeedCount = 0;
			prefs = [[NSMutableDictionary alloc] init];
			cache = [[NSMutableDictionary alloc] init];
			
			activeReaders = [[NSMutableDictionary alloc] init];
			feedsToUpdate = [[NSMutableArray alloc] init];
			isUpdating = NO;
			
			saveTimer = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(timedSave:) userInfo:nil repeats: YES];
		}
		return self;
	}else{
		return _sharedLibrary;
	}
}

-(void)dealloc{
	[saveTimer invalidate];
	
	[rootItem release];
	[storagePath release];
	[prefs release];
	[cache release];
	[activeReaders release];
	[feedsToUpdate release];
	
	[super dealloc];
}

-(void)timedSave:(NSTimer *)aTimer{
#pragma unused( aTimer )
	[self save];
}

-(void)loadFromPath:(NSString *)aPath{
	
	[storagePath autorelease];
	storagePath = [aPath retain];
	
	NSFileManager *				fileManager = [NSFileManager defaultManager];
	
	// Make sure we have an existing file to load
	if( ! [fileManager fileExistsAtPath: storagePath] ){
		ItemThrow([NSString stringWithFormat: @"No file at %@", storagePath] );
	}
	
	NSData *					fileData = [fileManager contentsAtPath: storagePath];
	
	if( !fileData ){
		ItemThrow([NSString stringWithFormat: @"Unable to create data from %@", storagePath]);
	}
	
	[rootItem release];
	rootItem = [[NSKeyedUnarchiver unarchiveObjectWithData: fileData] retain];
	
	if( ! rootItem ){
		rootItem = [[KNItem alloc] init];
		ItemThrow([NSString stringWithFormat: @"Unable to unarchive data from %@", storagePath]);
	}
}

-(void)saveToPath:(NSString *)aPath{
	
	[storagePath autorelease];
	storagePath = [aPath retain];
	
	NSFileManager *				fileManager = [NSFileManager defaultManager];
	NSData *					fileData = nil;
	NSString *					libBackupLocation = [storagePath stringByAppendingString: FeedBackupFileExtension];
	
	// Archive our root object
	fileData = [NSKeyedArchiver archivedDataWithRootObject: rootItem];
	if( ! fileData ){
		ItemThrow([NSString stringWithFormat: @"Unable to archive data from %@", rootItem]);
	}
	
	// Back up any existing storage file
	if( [fileManager fileExistsAtPath: storagePath] ){
		if( ! [fileManager movePath: storagePath toPath: libBackupLocation handler: nil] ){
			ItemThrow([NSString stringWithFormat: @"Unable to move %@", storagePath]);
		}
	}
	
	// Write our data to the new file
	if( [fileManager createFileAtPath: storagePath contents: fileData attributes: [NSDictionary dictionary]] ){
		[fileManager removeFileAtPath: libBackupLocation handler: nil];
	}else{
		[fileManager movePath: libBackupLocation toPath: storagePath handler: nil];
		ItemThrow([NSString stringWithFormat: @"Unable to create save file %@", storagePath]);
	}
}

-(BOOL)save{
	BOOL			didSave = NO;
	
	NS_DURING
		if( isDirty && !isUpdating ){
			KNDebug(@"Actually Saving...");
			[self saveToPath: storagePath];
			isDirty = NO;
			didSave = YES;
		}
	NS_HANDLER
		KNDebug(@"Library save failed: %@", [localException reason]);
	NS_ENDHANDLER
	
	return didSave;
}

-(BOOL)load{
	BOOL			didLoad = NO;
	
	NS_DURING
		[self loadFromPath: storagePath];
		didLoad = YES;
		isDirty = NO;
	NS_HANDLER
		KNDebug(@"Library load failed: %@", [localException reason]);
	NS_ENDHANDLER
	
	return didLoad;
}

-(void)makeDirty{
	isDirty = YES;
}

-(KNItem *)rootItem{
	return rootItem;
}

-(void)articleIsStale:(KNArticle *)anArticle{
	[anArticle generateCache];
}

-(NSString *)previewCacheForArticle:(KNArticle *)anArticle{
	if( ! [[NSFileManager defaultManager] fileExistsAtPath: [anArticle previewCachePath]] ){
		[anArticle generateCache];
	}else{
		if( ![anArticle valueForKeyPath:@"prefs.articlePrefsVersion"] || 
			![[anArticle valueForKeyPath:@"prefs.articlePrefsVersion"] isEqual: ArticlePreviewCacheVersion]
		){
			[anArticle generateCache];
		}
	}
	return [anArticle previewCachePath];
}

@end
