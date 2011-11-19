/*
 * iTunes.m
 */

#include "iTunes.h"




/*
 * Standard Suite
 */

@implementation iTunesPrintSettings


- (NSInteger) copies
{
	id v = [[self propertyWithCode:'lwcp'] get];
	return [v integerValue];
}

- (BOOL) collating
{
	id v = [[self propertyWithCode:'lwcl'] get];
	return [v boolValue];
}

- (NSInteger) startingPage
{
	id v = [[self propertyWithCode:'lwfp'] get];
	return [v integerValue];
}

- (NSInteger) endingPage
{
	id v = [[self propertyWithCode:'lwlp'] get];
	return [v integerValue];
}

- (NSInteger) pagesAcross
{
	id v = [[self propertyWithCode:'lwla'] get];
	return [v integerValue];
}

- (NSInteger) pagesDown
{
	id v = [[self propertyWithCode:'lwld'] get];
	return [v integerValue];
}

- (iTunesEnum) errorHandling
{
	id v = [[self propertyWithCode:'lweh'] get];
	return [v enumCodeValue];
}

- (NSDate *) requestedPrintTime
{
	return [[self propertyWithCode:'lwqt'] get];
}

- (NSArray *) printerFeatures
{
	return [[self propertyWithCode:'lwpf'] get];
}

- (NSString *) faxNumber
{
	return [[self propertyWithCode:'faxn'] get];
}

- (NSString *) targetPrinter
{
	return [[self propertyWithCode:'trpr'] get];
}


- (void) printPrintDialog:(BOOL)printDialog withProperties:(iTunesPrintSettings *)withProperties kind:(iTunesEKnd)kind theme:(NSString *)theme
{
	[self sendEvent:'aevt' id:'pdoc' parameters:'pdlg', [NSNumber numberWithBool:printDialog], 'prdt', withProperties, 'pKnd', [NSAppleEventDescriptor descriptorWithEnumCode:kind], 'pThm', theme, 0];
}

- (void) close
{
	[self sendEvent:'core' id:'clos' parameters:0];
}

- (void) delete
{
	[self sendEvent:'core' id:'delo' parameters:0];
}

- (SBObject *) duplicateTo:(SBObject *)to
{
	id result__ = [self sendEvent:'core' id:'clon' parameters:'insh', to, 0];
	return result__;
}

- (BOOL) exists
{
	id result__ = [self sendEvent:'core' id:'doex' parameters:0];
	return [result__ boolValue];
}

- (void) open
{
	[self sendEvent:'aevt' id:'odoc' parameters:0];
}

- (void) playOnce:(BOOL)once
{
	[self sendEvent:'hook' id:'Play' parameters:'POne', [NSNumber numberWithBool:once], 0];
}


@end




/*
 * iTunes Suite
 */

@implementation iTunesApplication

typedef struct { __unsafe_unretained NSString *name; FourCharCode code; } classForCode_t;
static const classForCode_t classForCodeData__[] = {
	{ @"iTunesApplication", 'capp' },
	{ @"iTunesArtwork", 'cArt' },
	{ @"iTunesAudioCDPlaylist", 'cCDP' },
	{ @"iTunesAudioCDTrack", 'cCDT' },
	{ @"iTunesBrowserWindow", 'cBrW' },
	{ @"iTunesDevicePlaylist", 'cDvP' },
	{ @"iTunesDeviceTrack", 'cDvT' },
	{ @"iTunesEQPreset", 'cEQP' },
	{ @"iTunesEQWindow", 'cEQW' },
	{ @"iTunesEncoder", 'cEnc' },
	{ @"iTunesFileTrack", 'cFlT' },
	{ @"iTunesFolderPlaylist", 'cFoP' },
	{ @"iTunesItem", 'cobj' },
	{ @"iTunesLibraryPlaylist", 'cLiP' },
	{ @"iTunesPlaylist", 'cPly' },
	{ @"iTunesPlaylistWindow", 'cPlW' },
	{ @"iTunesPrintSettings", 'pset' },
	{ @"iTunesRadioTunerPlaylist", 'cRTP' },
	{ @"iTunesSharedTrack", 'cShT' },
	{ @"iTunesSource", 'cSrc' },
	{ @"iTunesTrack", 'cTrk' },
	{ @"iTunesURLTrack", 'cURT' },
	{ @"iTunesUserPlaylist", 'cUsP' },
	{ @"iTunesVisual", 'cVis' },
	{ @"iTunesWindow", 'cwin' },
	{ nil, 0 } 
};

- (NSDictionary *) classNamesForCodes
{
	static NSMutableDictionary *dict__;

	if (!dict__) @synchronized([self class]) {
	if (!dict__) {
		dict__ = [[NSMutableDictionary alloc] init];
		const classForCode_t *p;
		for (p = classForCodeData__; p->name != nil; ++p)
			[dict__ setObject:p->name forKey:[NSNumber numberWithInt:p->code]];
	} }
	return dict__;
}

typedef struct { FourCharCode code; __unsafe_unretained NSString *name; } codeForPropertyName_t;
static const codeForPropertyName_t codeForPropertyNameData__[] = {
	{ 'pEQp', @"EQ" },
	{ 'pEQ ', @"EQEnabled" },
	{ 'pURL', @"address" },
	{ 'pAlb', @"album" },
	{ 'pAlA', @"albumArtist" },
	{ 'pAlR', @"albumRating" },
	{ 'pARk', @"albumRatingKind" },
	{ 'pArt', @"artist" },
	{ 'pEQ1', @"band1" },
	{ 'pEQ0', @"band10" },
	{ 'pEQ2', @"band2" },
	{ 'pEQ3', @"band3" },
	{ 'pEQ4', @"band4" },
	{ 'pEQ5', @"band5" },
	{ 'pEQ6', @"band6" },
	{ 'pEQ7', @"band7" },
	{ 'pEQ8', @"band8" },
	{ 'pEQ9', @"band9" },
	{ 'pBRt', @"bitRate" },
	{ 'pBkt', @"bookmark" },
	{ 'pBkm', @"bookmarkable" },
	{ 'pbnd', @"bounds" },
	{ 'pBPM', @"bpm" },
	{ 'capa', @"capacity" },
	{ 'pCat', @"category" },
	{ 'hclb', @"closeable" },
	{ 'pWSh', @"collapseable" },
	{ 'wshd', @"collapsed" },
	{ 'lwcl', @"collating" },
	{ 'pCmt', @"comment" },
	{ 'pAnt', @"compilation" },
	{ 'pCmp', @"composer" },
	{ 'ctnr', @"container" },
	{ 'lwcp', @"copies" },
	{ 'pEQP', @"currentEQPreset" },
	{ 'pEnc', @"currentEncoder" },
	{ 'pPla', @"currentPlaylist" },
	{ 'pStT', @"currentStreamTitle" },
	{ 'pStU', @"currentStreamURL" },
	{ 'pTrk', @"currentTrack" },
	{ 'pVis', @"currentVisual" },
	{ 'pPCT', @"data" },
	{ 'pDID', @"databaseID" },
	{ 'pAdd', @"dateAdded" },
	{ 'pDsC', @"discCount" },
	{ 'pDsN', @"discNumber" },
	{ 'pDlA', @"downloaded" },
	{ 'pDur', @"duration" },
	{ 'enbl', @"enabled" },
	{ 'lwlp', @"endingPage" },
	{ 'pEpD', @"episodeID" },
	{ 'pEpN', @"episodeNumber" },
	{ 'lweh', @"errorHandling" },
	{ 'faxn', @"faxNumber" },
	{ 'pStp', @"finish" },
	{ 'pFix', @"fixedIndexing" },
	{ 'pFmt', @"format" },
	{ 'frsp', @"freeSpace" },
	{ 'pisf', @"frontmost" },
	{ 'pFSc', @"fullScreen" },
	{ 'pGpl', @"gapless" },
	{ 'pGen', @"genre" },
	{ 'pGrp', @"grouping" },
	{ 'ID  ', @"id" },
	{ 'pidx', @"index" },
	{ 'pKnd', @"kind" },
	{ 'pLoc', @"location" },
	{ 'pLds', @"longDescription" },
	{ 'pLyr', @"lyrics" },
	{ 'pMin', @"minimized" },
	{ 'pMod', @"modifiable" },
	{ 'asmo', @"modificationDate" },
	{ 'pMut', @"mute" },
	{ 'pnam', @"name" },
	{ 'pDes', @"objectDescription" },
	{ 'lwla', @"pagesAcross" },
	{ 'lwld', @"pagesDown" },
	{ 'pPlP', @"parent" },
	{ 'pPIS', @"persistentID" },
	{ 'pPlC', @"playedCount" },
	{ 'pPlD', @"playedDate" },
	{ 'pPos', @"playerPosition" },
	{ 'pPlS', @"playerState" },
	{ 'pTPc', @"podcast" },
	{ 'ppos', @"position" },
	{ 'pEQA', @"preamp" },
	{ 'lwpf', @"printerFeatures" },
	{ 'pRte', @"rating" },
	{ 'pRtk', @"ratingKind" },
	{ 'pRaw', @"rawData" },
	{ 'pRlD', @"releaseDate" },
	{ 'lwqt', @"requestedPrintTime" },
	{ 'prsz', @"resizable" },
	{ 'pSRt', @"sampleRate" },
	{ 'pSeN', @"seasonNumber" },
	{ 'sele', @"selection" },
	{ 'pShr', @"shared" },
	{ 'pShw', @"show" },
	{ 'pSfa', @"shufflable" },
	{ 'pShf', @"shuffle" },
	{ 'pSiz', @"size" },
	{ 'pSkC', @"skippedCount" },
	{ 'pSkD', @"skippedDate" },
	{ 'pSmt', @"smart" },
	{ 'pRpt', @"songRepeat" },
	{ 'pSAl', @"sortAlbum" },
	{ 'pSAA', @"sortAlbumArtist" },
	{ 'pSAr', @"sortArtist" },
	{ 'pSCm', @"sortComposer" },
	{ 'pSNm', @"sortName" },
	{ 'pSSN', @"sortShow" },
	{ 'pVol', @"soundVolume" },
	{ 'pSpK', @"specialKind" },
	{ 'pStr', @"start" },
	{ 'lwfp', @"startingPage" },
	{ 'trpr', @"targetPrinter" },
	{ 'pTim', @"time" },
	{ 'pTrC', @"trackCount" },
	{ 'pTrN', @"trackNumber" },
	{ 'pUnp', @"unplayed" },
	{ 'pUTC', @"updateTracks" },
	{ 'vers', @"version" },
	{ 'pVdK', @"videoKind" },
	{ 'pPly', @"view" },
	{ 'pvis', @"visible" },
	{ 'pVSz', @"visualSize" },
	{ 'pVsE', @"visualsEnabled" },
	{ 'pAdj', @"volumeAdjustment" },
	{ 'pYr ', @"year" },
	{ 'iszm', @"zoomable" },
	{ 'pzum', @"zoomed" },
	{ 0, nil } 
};

- (NSDictionary *) codesForPropertyNames
{
	static NSMutableDictionary *dict__;

	if (!dict__) @synchronized([self class]) {
	if (!dict__) {
		dict__ = [[NSMutableDictionary alloc] init];
		const codeForPropertyName_t *p;
		for (p = codeForPropertyNameData__; p->name != nil; ++p)
			[dict__ setObject:[NSNumber numberWithInt:p->code] forKey:p->name];
	} }
	return dict__;
}


- (SBElementArray *) browserWindows
{
	return [self elementArrayWithCode:'cBrW'];
}


- (SBElementArray *) encoders
{
	return [self elementArrayWithCode:'cEnc'];
}


- (SBElementArray *) EQPresets
{
	return [self elementArrayWithCode:'cEQP'];
}


- (SBElementArray *) EQWindows
{
	return [self elementArrayWithCode:'cEQW'];
}


- (SBElementArray *) playlistWindows
{
	return [self elementArrayWithCode:'cPlW'];
}


- (SBElementArray *) sources
{
	return [self elementArrayWithCode:'cSrc'];
}


- (SBElementArray *) visuals
{
	return [self elementArrayWithCode:'cVis'];
}


- (SBElementArray *) windows
{
	return [self elementArrayWithCode:'cwin'];
}



- (iTunesEncoder *) currentEncoder
{
	return (iTunesEncoder *) [self propertyWithClass:[iTunesEncoder class] code:'pEnc'];
}

- (void) setCurrentEncoder: (iTunesEncoder *) currentEncoder
{
	[[self propertyWithClass:[iTunesEncoder class] code:'pEnc'] setTo:currentEncoder];
}

- (iTunesEQPreset *) currentEQPreset
{
	return (iTunesEQPreset *) [self propertyWithClass:[iTunesEQPreset class] code:'pEQP'];
}

- (void) setCurrentEQPreset: (iTunesEQPreset *) currentEQPreset
{
	[[self propertyWithClass:[iTunesEQPreset class] code:'pEQP'] setTo:currentEQPreset];
}

- (iTunesPlaylist *) currentPlaylist
{
	return (iTunesPlaylist *) [self propertyWithClass:[iTunesPlaylist class] code:'pPla'];
}

- (NSString *) currentStreamTitle
{
	return [[self propertyWithCode:'pStT'] get];
}

- (NSString *) currentStreamURL
{
	return [[self propertyWithCode:'pStU'] get];
}

- (iTunesTrack *) currentTrack
{
	return (iTunesTrack *) [self propertyWithClass:[iTunesTrack class] code:'pTrk'];
}

- (iTunesVisual *) currentVisual
{
	return (iTunesVisual *) [self propertyWithClass:[iTunesVisual class] code:'pVis'];
}

- (void) setCurrentVisual: (iTunesVisual *) currentVisual
{
	[[self propertyWithClass:[iTunesVisual class] code:'pVis'] setTo:currentVisual];
}

- (BOOL) EQEnabled
{
	id v = [[self propertyWithCode:'pEQ '] get];
	return [v boolValue];
}

- (void) setEQEnabled: (BOOL) EQEnabled
{
	id v = [NSNumber numberWithBool:EQEnabled];
	[[self propertyWithCode:'pEQ '] setTo:v];
}

- (BOOL) fixedIndexing
{
	id v = [[self propertyWithCode:'pFix'] get];
	return [v boolValue];
}

- (void) setFixedIndexing: (BOOL) fixedIndexing
{
	id v = [NSNumber numberWithBool:fixedIndexing];
	[[self propertyWithCode:'pFix'] setTo:v];
}

- (BOOL) frontmost
{
	id v = [[self propertyWithCode:'pisf'] get];
	return [v boolValue];
}

- (void) setFrontmost: (BOOL) frontmost
{
	id v = [NSNumber numberWithBool:frontmost];
	[[self propertyWithCode:'pisf'] setTo:v];
}

- (BOOL) fullScreen
{
	id v = [[self propertyWithCode:'pFSc'] get];
	return [v boolValue];
}

- (void) setFullScreen: (BOOL) fullScreen
{
	id v = [NSNumber numberWithBool:fullScreen];
	[[self propertyWithCode:'pFSc'] setTo:v];
}

- (NSString *) name
{
	return [[self propertyWithCode:'pnam'] get];
}

- (BOOL) mute
{
	id v = [[self propertyWithCode:'pMut'] get];
	return [v boolValue];
}

- (void) setMute: (BOOL) mute
{
	id v = [NSNumber numberWithBool:mute];
	[[self propertyWithCode:'pMut'] setTo:v];
}

- (NSInteger) playerPosition
{
	id v = [[self propertyWithCode:'pPos'] get];
	return [v integerValue];
}

- (void) setPlayerPosition: (NSInteger) playerPosition
{
	id v = [NSNumber numberWithInteger:playerPosition];
	[[self propertyWithCode:'pPos'] setTo:v];
}

- (iTunesEPlS) playerState
{
	id v = [[self propertyWithCode:'pPlS'] get];
	return [v enumCodeValue];
}

- (SBObject *) selection
{
	return (SBObject *) [self propertyWithClass:[SBObject class] code:'sele'];
}

- (NSInteger) soundVolume
{
	id v = [[self propertyWithCode:'pVol'] get];
	return [v integerValue];
}

- (void) setSoundVolume: (NSInteger) soundVolume
{
	id v = [NSNumber numberWithInteger:soundVolume];
	[[self propertyWithCode:'pVol'] setTo:v];
}

- (NSString *) version
{
	return [[self propertyWithCode:'vers'] get];
}

- (BOOL) visualsEnabled
{
	id v = [[self propertyWithCode:'pVsE'] get];
	return [v boolValue];
}

- (void) setVisualsEnabled: (BOOL) visualsEnabled
{
	id v = [NSNumber numberWithBool:visualsEnabled];
	[[self propertyWithCode:'pVsE'] setTo:v];
}

- (iTunesEVSz) visualSize
{
	id v = [[self propertyWithCode:'pVSz'] get];
	return [v enumCodeValue];
}

- (void) setVisualSize: (iTunesEVSz) visualSize
{
	id v = [NSAppleEventDescriptor descriptorWithEnumCode:visualSize];
	[[self propertyWithCode:'pVSz'] setTo:v];
}


- (void) printPrintDialog:(BOOL)printDialog withProperties:(iTunesPrintSettings *)withProperties kind:(iTunesEKnd)kind theme:(NSString *)theme
{
	[self sendEvent:'aevt' id:'pdoc' parameters:'pdlg', [NSNumber numberWithBool:printDialog], 'prdt', withProperties, 'pKnd', [NSAppleEventDescriptor descriptorWithEnumCode:kind], 'pThm', theme, 0];
}

- (void) run
{
	[self sendEvent:'aevt' id:'oapp' parameters:0];
}

- (void) quit
{
	[self sendEvent:'aevt' id:'quit' parameters:0];
}

- (iTunesTrack *) add:(NSArray *)x to:(SBObject *)to
{
	id result__ = [self sendEvent:'hook' id:'Add ' parameters:'----', x, 'insh', to, 0];
	return result__;
}

- (void) backTrack
{
	[self sendEvent:'hook' id:'Back' parameters:0];
}

- (iTunesTrack *) convert:(NSArray *)x
{
	id result__ = [self sendEvent:'hook' id:'Conv' parameters:'----', x, 0];
	return result__;
}

- (void) fastForward
{
	[self sendEvent:'hook' id:'Fast' parameters:0];
}

- (void) nextTrack
{
	[self sendEvent:'hook' id:'Next' parameters:0];
}

- (void) pause
{
	[self sendEvent:'hook' id:'Paus' parameters:0];
}

- (void) playOnce:(BOOL)once
{
	[self sendEvent:'hook' id:'Play' parameters:'POne', [NSNumber numberWithBool:once], 0];
}

- (void) playpause
{
	[self sendEvent:'hook' id:'PlPs' parameters:0];
}

- (void) previousTrack
{
	[self sendEvent:'hook' id:'Prev' parameters:0];
}

- (void) resume
{
	[self sendEvent:'hook' id:'Resu' parameters:0];
}

- (void) rewind
{
	[self sendEvent:'hook' id:'Rwnd' parameters:0];
}

- (void) stop
{
	[self sendEvent:'hook' id:'Stop' parameters:0];
}

- (void) update
{
	[self sendEvent:'hook' id:'Updt' parameters:0];
}

- (void) eject
{
	[self sendEvent:'hook' id:'Ejct' parameters:0];
}

- (void) subscribe:(NSString *)x
{
	[self sendEvent:'hook' id:'pSub' parameters:'----', x, 0];
}

- (void) updateAllPodcasts
{
	[self sendEvent:'hook' id:'Updp' parameters:0];
}

- (void) updatePodcast
{
	[self sendEvent:'hook' id:'Upd1' parameters:0];
}

- (void) openLocation:(NSString *)x
{
	[self sendEvent:'GURL' id:'GURL' parameters:'----', x, 0];
}


@end


@implementation iTunesItem


- (SBObject *) container
{
	return (SBObject *) [self propertyWithClass:[SBObject class] code:'ctnr'];
}

- (NSInteger) id
{
	id v = [[self propertyWithCode:'ID  '] get];
	return [v integerValue];
}

- (NSInteger) index
{
	id v = [[self propertyWithCode:'pidx'] get];
	return [v integerValue];
}

- (NSString *) name
{
	return [[self propertyWithCode:'pnam'] get];
}

- (void) setName: (NSString *) name
{
	[[self propertyWithCode:'pnam'] setTo:name];
}

- (NSString *) persistentID
{
	return [[self propertyWithCode:'pPIS'] get];
}


- (void) printPrintDialog:(BOOL)printDialog withProperties:(iTunesPrintSettings *)withProperties kind:(iTunesEKnd)kind theme:(NSString *)theme
{
	[self sendEvent:'aevt' id:'pdoc' parameters:'pdlg', [NSNumber numberWithBool:printDialog], 'prdt', withProperties, 'pKnd', [NSAppleEventDescriptor descriptorWithEnumCode:kind], 'pThm', theme, 0];
}

- (void) close
{
	[self sendEvent:'core' id:'clos' parameters:0];
}

- (void) delete
{
	[self sendEvent:'core' id:'delo' parameters:0];
}

- (SBObject *) duplicateTo:(SBObject *)to
{
	id result__ = [self sendEvent:'core' id:'clon' parameters:'insh', to, 0];
	return result__;
}

- (BOOL) exists
{
	id result__ = [self sendEvent:'core' id:'doex' parameters:0];
	return [result__ boolValue];
}

- (void) open
{
	[self sendEvent:'aevt' id:'odoc' parameters:0];
}

- (void) playOnce:(BOOL)once
{
	[self sendEvent:'hook' id:'Play' parameters:'POne', [NSNumber numberWithBool:once], 0];
}

- (void) reveal
{
	[self sendEvent:'hook' id:'Revl' parameters:0];
}


@end


@implementation iTunesArtwork


- (NSImage *) data
{
	return [[self propertyWithCode:'pPCT'] get];
}

- (void) setData: (NSImage *) data
{
	[[self propertyWithCode:'pPCT'] setTo:data];
}

- (NSString *) objectDescription
{
	return [[self propertyWithCode:'pDes'] get];
}

- (void) setObjectDescription: (NSString *) objectDescription
{
	[[self propertyWithCode:'pDes'] setTo:objectDescription];
}

- (BOOL) downloaded
{
	id v = [[self propertyWithCode:'pDlA'] get];
	return [v boolValue];
}

- (NSNumber *) format
{
	return [[self propertyWithCode:'pFmt'] get];
}

- (NSInteger) kind
{
	id v = [[self propertyWithCode:'pKnd'] get];
	return [v integerValue];
}

- (void) setKind: (NSInteger) kind
{
	id v = [NSNumber numberWithInteger:kind];
	[[self propertyWithCode:'pKnd'] setTo:v];
}

- (NSData *) rawData
{
	id v = [[self propertyWithCode:'pRaw'] get];
	return [v data];
}

- (void) setRawData: (NSData *) rawData
{
	id v = [NSAppleEventDescriptor descriptorWithDescriptorType:'tdta' data:rawData];
	[[self propertyWithCode:'pRaw'] setTo:v];
}



@end


@implementation iTunesEncoder


- (NSString *) format
{
	return [[self propertyWithCode:'pFmt'] get];
}



@end


@implementation iTunesEQPreset


- (double) band1
{
	id v = [[self propertyWithCode:'pEQ1'] get];
	return [v doubleValue];
}

- (void) setBand1: (double) band1
{
	id v = [NSNumber numberWithDouble:band1];
	[[self propertyWithCode:'pEQ1'] setTo:v];
}

- (double) band2
{
	id v = [[self propertyWithCode:'pEQ2'] get];
	return [v doubleValue];
}

- (void) setBand2: (double) band2
{
	id v = [NSNumber numberWithDouble:band2];
	[[self propertyWithCode:'pEQ2'] setTo:v];
}

- (double) band3
{
	id v = [[self propertyWithCode:'pEQ3'] get];
	return [v doubleValue];
}

- (void) setBand3: (double) band3
{
	id v = [NSNumber numberWithDouble:band3];
	[[self propertyWithCode:'pEQ3'] setTo:v];
}

- (double) band4
{
	id v = [[self propertyWithCode:'pEQ4'] get];
	return [v doubleValue];
}

- (void) setBand4: (double) band4
{
	id v = [NSNumber numberWithDouble:band4];
	[[self propertyWithCode:'pEQ4'] setTo:v];
}

- (double) band5
{
	id v = [[self propertyWithCode:'pEQ5'] get];
	return [v doubleValue];
}

- (void) setBand5: (double) band5
{
	id v = [NSNumber numberWithDouble:band5];
	[[self propertyWithCode:'pEQ5'] setTo:v];
}

- (double) band6
{
	id v = [[self propertyWithCode:'pEQ6'] get];
	return [v doubleValue];
}

- (void) setBand6: (double) band6
{
	id v = [NSNumber numberWithDouble:band6];
	[[self propertyWithCode:'pEQ6'] setTo:v];
}

- (double) band7
{
	id v = [[self propertyWithCode:'pEQ7'] get];
	return [v doubleValue];
}

- (void) setBand7: (double) band7
{
	id v = [NSNumber numberWithDouble:band7];
	[[self propertyWithCode:'pEQ7'] setTo:v];
}

- (double) band8
{
	id v = [[self propertyWithCode:'pEQ8'] get];
	return [v doubleValue];
}

- (void) setBand8: (double) band8
{
	id v = [NSNumber numberWithDouble:band8];
	[[self propertyWithCode:'pEQ8'] setTo:v];
}

- (double) band9
{
	id v = [[self propertyWithCode:'pEQ9'] get];
	return [v doubleValue];
}

- (void) setBand9: (double) band9
{
	id v = [NSNumber numberWithDouble:band9];
	[[self propertyWithCode:'pEQ9'] setTo:v];
}

- (double) band10
{
	id v = [[self propertyWithCode:'pEQ0'] get];
	return [v doubleValue];
}

- (void) setBand10: (double) band10
{
	id v = [NSNumber numberWithDouble:band10];
	[[self propertyWithCode:'pEQ0'] setTo:v];
}

- (BOOL) modifiable
{
	id v = [[self propertyWithCode:'pMod'] get];
	return [v boolValue];
}

- (double) preamp
{
	id v = [[self propertyWithCode:'pEQA'] get];
	return [v doubleValue];
}

- (void) setPreamp: (double) preamp
{
	id v = [NSNumber numberWithDouble:preamp];
	[[self propertyWithCode:'pEQA'] setTo:v];
}

- (BOOL) updateTracks
{
	id v = [[self propertyWithCode:'pUTC'] get];
	return [v boolValue];
}

- (void) setUpdateTracks: (BOOL) updateTracks
{
	id v = [NSNumber numberWithBool:updateTracks];
	[[self propertyWithCode:'pUTC'] setTo:v];
}



@end


@implementation iTunesPlaylist


- (SBElementArray *) tracks
{
	return [self elementArrayWithCode:'cTrk'];
}



- (NSInteger) duration
{
	id v = [[self propertyWithCode:'pDur'] get];
	return [v integerValue];
}

- (NSString *) name
{
	return [[self propertyWithCode:'pnam'] get];
}

- (void) setName: (NSString *) name
{
	[[self propertyWithCode:'pnam'] setTo:name];
}

- (iTunesPlaylist *) parent
{
	return (iTunesPlaylist *) [self propertyWithClass:[iTunesPlaylist class] code:'pPlP'];
}

- (BOOL) shuffle
{
	id v = [[self propertyWithCode:'pShf'] get];
	return [v boolValue];
}

- (void) setShuffle: (BOOL) shuffle
{
	id v = [NSNumber numberWithBool:shuffle];
	[[self propertyWithCode:'pShf'] setTo:v];
}

- (long long) size
{
	id v = [[self propertyWithCode:'pSiz'] get];
	return [v longLongValue];
}

- (iTunesERpt) songRepeat
{
	id v = [[self propertyWithCode:'pRpt'] get];
	return [v enumCodeValue];
}

- (void) setSongRepeat: (iTunesERpt) songRepeat
{
	id v = [NSAppleEventDescriptor descriptorWithEnumCode:songRepeat];
	[[self propertyWithCode:'pRpt'] setTo:v];
}

- (iTunesESpK) specialKind
{
	id v = [[self propertyWithCode:'pSpK'] get];
	return [v enumCodeValue];
}

- (NSString *) time
{
	return [[self propertyWithCode:'pTim'] get];
}

- (BOOL) visible
{
	id v = [[self propertyWithCode:'pvis'] get];
	return [v boolValue];
}


- (void) moveTo:(SBObject *)to
{
	[self sendEvent:'core' id:'move' parameters:'insh', to, 0];
}

- (iTunesTrack *) searchFor:(NSString *)for_ only:(iTunesESrA)only
{
	id result__ = [self sendEvent:'hook' id:'Srch' parameters:'pTrm', for_, 'pAre', [NSAppleEventDescriptor descriptorWithEnumCode:only], 0];
	return result__;
}


@end


@implementation iTunesAudioCDPlaylist


- (SBElementArray *) audioCDTracks
{
	return [self elementArrayWithCode:'cCDT'];
}



- (NSString *) artist
{
	return [[self propertyWithCode:'pArt'] get];
}

- (void) setArtist: (NSString *) artist
{
	[[self propertyWithCode:'pArt'] setTo:artist];
}

- (BOOL) compilation
{
	id v = [[self propertyWithCode:'pAnt'] get];
	return [v boolValue];
}

- (void) setCompilation: (BOOL) compilation
{
	id v = [NSNumber numberWithBool:compilation];
	[[self propertyWithCode:'pAnt'] setTo:v];
}

- (NSString *) composer
{
	return [[self propertyWithCode:'pCmp'] get];
}

- (void) setComposer: (NSString *) composer
{
	[[self propertyWithCode:'pCmp'] setTo:composer];
}

- (NSInteger) discCount
{
	id v = [[self propertyWithCode:'pDsC'] get];
	return [v integerValue];
}

- (void) setDiscCount: (NSInteger) discCount
{
	id v = [NSNumber numberWithInteger:discCount];
	[[self propertyWithCode:'pDsC'] setTo:v];
}

- (NSInteger) discNumber
{
	id v = [[self propertyWithCode:'pDsN'] get];
	return [v integerValue];
}

- (void) setDiscNumber: (NSInteger) discNumber
{
	id v = [NSNumber numberWithInteger:discNumber];
	[[self propertyWithCode:'pDsN'] setTo:v];
}

- (NSString *) genre
{
	return [[self propertyWithCode:'pGen'] get];
}

- (void) setGenre: (NSString *) genre
{
	[[self propertyWithCode:'pGen'] setTo:genre];
}

- (NSInteger) year
{
	id v = [[self propertyWithCode:'pYr '] get];
	return [v integerValue];
}

- (void) setYear: (NSInteger) year
{
	id v = [NSNumber numberWithInteger:year];
	[[self propertyWithCode:'pYr '] setTo:v];
}



@end


@implementation iTunesDevicePlaylist


- (SBElementArray *) deviceTracks
{
	return [self elementArrayWithCode:'cDvT'];
}




@end


@implementation iTunesLibraryPlaylist


- (SBElementArray *) fileTracks
{
	return [self elementArrayWithCode:'cFlT'];
}


- (SBElementArray *) URLTracks
{
	return [self elementArrayWithCode:'cURT'];
}


- (SBElementArray *) sharedTracks
{
	return [self elementArrayWithCode:'cShT'];
}




@end


@implementation iTunesRadioTunerPlaylist


- (SBElementArray *) URLTracks
{
	return [self elementArrayWithCode:'cURT'];
}




@end


@implementation iTunesSource


- (SBElementArray *) audioCDPlaylists
{
	return [self elementArrayWithCode:'cCDP'];
}


- (SBElementArray *) devicePlaylists
{
	return [self elementArrayWithCode:'cDvP'];
}


- (SBElementArray *) libraryPlaylists
{
	return [self elementArrayWithCode:'cLiP'];
}


- (SBElementArray *) playlists
{
	return [self elementArrayWithCode:'cPly'];
}


- (SBElementArray *) radioTunerPlaylists
{
	return [self elementArrayWithCode:'cRTP'];
}


- (SBElementArray *) userPlaylists
{
	return [self elementArrayWithCode:'cUsP'];
}



- (long long) capacity
{
	id v = [[self propertyWithCode:'capa'] get];
	return [v longLongValue];
}

- (long long) freeSpace
{
	id v = [[self propertyWithCode:'frsp'] get];
	return [v longLongValue];
}

- (iTunesESrc) kind
{
	id v = [[self propertyWithCode:'pKnd'] get];
	return [v enumCodeValue];
}


- (void) update
{
	[self sendEvent:'hook' id:'Updt' parameters:0];
}

- (void) eject
{
	[self sendEvent:'hook' id:'Ejct' parameters:0];
}


@end


@implementation iTunesTrack


- (SBElementArray *) artworks
{
	return [self elementArrayWithCode:'cArt'];
}



- (NSString *) album
{
	return [[self propertyWithCode:'pAlb'] get];
}

- (void) setAlbum: (NSString *) album
{
	[[self propertyWithCode:'pAlb'] setTo:album];
}

- (NSString *) albumArtist
{
	return [[self propertyWithCode:'pAlA'] get];
}

- (void) setAlbumArtist: (NSString *) albumArtist
{
	[[self propertyWithCode:'pAlA'] setTo:albumArtist];
}

- (NSInteger) albumRating
{
	id v = [[self propertyWithCode:'pAlR'] get];
	return [v integerValue];
}

- (void) setAlbumRating: (NSInteger) albumRating
{
	id v = [NSNumber numberWithInteger:albumRating];
	[[self propertyWithCode:'pAlR'] setTo:v];
}

- (iTunesERtK) albumRatingKind
{
	id v = [[self propertyWithCode:'pARk'] get];
	return [v enumCodeValue];
}

- (NSString *) artist
{
	return [[self propertyWithCode:'pArt'] get];
}

- (void) setArtist: (NSString *) artist
{
	[[self propertyWithCode:'pArt'] setTo:artist];
}

- (NSInteger) bitRate
{
	id v = [[self propertyWithCode:'pBRt'] get];
	return [v integerValue];
}

- (double) bookmark
{
	id v = [[self propertyWithCode:'pBkt'] get];
	return [v doubleValue];
}

- (void) setBookmark: (double) bookmark
{
	id v = [NSNumber numberWithDouble:bookmark];
	[[self propertyWithCode:'pBkt'] setTo:v];
}

- (BOOL) bookmarkable
{
	id v = [[self propertyWithCode:'pBkm'] get];
	return [v boolValue];
}

- (void) setBookmarkable: (BOOL) bookmarkable
{
	id v = [NSNumber numberWithBool:bookmarkable];
	[[self propertyWithCode:'pBkm'] setTo:v];
}

- (NSInteger) bpm
{
	id v = [[self propertyWithCode:'pBPM'] get];
	return [v integerValue];
}

- (void) setBpm: (NSInteger) bpm
{
	id v = [NSNumber numberWithInteger:bpm];
	[[self propertyWithCode:'pBPM'] setTo:v];
}

- (NSString *) category
{
	return [[self propertyWithCode:'pCat'] get];
}

- (void) setCategory: (NSString *) category
{
	[[self propertyWithCode:'pCat'] setTo:category];
}

- (NSString *) comment
{
	return [[self propertyWithCode:'pCmt'] get];
}

- (void) setComment: (NSString *) comment
{
	[[self propertyWithCode:'pCmt'] setTo:comment];
}

- (BOOL) compilation
{
	id v = [[self propertyWithCode:'pAnt'] get];
	return [v boolValue];
}

- (void) setCompilation: (BOOL) compilation
{
	id v = [NSNumber numberWithBool:compilation];
	[[self propertyWithCode:'pAnt'] setTo:v];
}

- (NSString *) composer
{
	return [[self propertyWithCode:'pCmp'] get];
}

- (void) setComposer: (NSString *) composer
{
	[[self propertyWithCode:'pCmp'] setTo:composer];
}

- (NSInteger) databaseID
{
	id v = [[self propertyWithCode:'pDID'] get];
	return [v integerValue];
}

- (NSDate *) dateAdded
{
	return [[self propertyWithCode:'pAdd'] get];
}

- (NSString *) objectDescription
{
	return [[self propertyWithCode:'pDes'] get];
}

- (void) setObjectDescription: (NSString *) objectDescription
{
	[[self propertyWithCode:'pDes'] setTo:objectDescription];
}

- (NSInteger) discCount
{
	id v = [[self propertyWithCode:'pDsC'] get];
	return [v integerValue];
}

- (void) setDiscCount: (NSInteger) discCount
{
	id v = [NSNumber numberWithInteger:discCount];
	[[self propertyWithCode:'pDsC'] setTo:v];
}

- (NSInteger) discNumber
{
	id v = [[self propertyWithCode:'pDsN'] get];
	return [v integerValue];
}

- (void) setDiscNumber: (NSInteger) discNumber
{
	id v = [NSNumber numberWithInteger:discNumber];
	[[self propertyWithCode:'pDsN'] setTo:v];
}

- (double) duration
{
	id v = [[self propertyWithCode:'pDur'] get];
	return [v doubleValue];
}

- (BOOL) enabled
{
	id v = [[self propertyWithCode:'enbl'] get];
	return [v boolValue];
}

- (void) setEnabled: (BOOL) enabled
{
	id v = [NSNumber numberWithBool:enabled];
	[[self propertyWithCode:'enbl'] setTo:v];
}

- (NSString *) episodeID
{
	return [[self propertyWithCode:'pEpD'] get];
}

- (void) setEpisodeID: (NSString *) episodeID
{
	[[self propertyWithCode:'pEpD'] setTo:episodeID];
}

- (NSInteger) episodeNumber
{
	id v = [[self propertyWithCode:'pEpN'] get];
	return [v integerValue];
}

- (void) setEpisodeNumber: (NSInteger) episodeNumber
{
	id v = [NSNumber numberWithInteger:episodeNumber];
	[[self propertyWithCode:'pEpN'] setTo:v];
}

- (NSString *) EQ
{
	return [[self propertyWithCode:'pEQp'] get];
}

- (void) setEQ: (NSString *) EQ
{
	[[self propertyWithCode:'pEQp'] setTo:EQ];
}

- (double) finish
{
	id v = [[self propertyWithCode:'pStp'] get];
	return [v doubleValue];
}

- (void) setFinish: (double) finish
{
	id v = [NSNumber numberWithDouble:finish];
	[[self propertyWithCode:'pStp'] setTo:v];
}

- (BOOL) gapless
{
	id v = [[self propertyWithCode:'pGpl'] get];
	return [v boolValue];
}

- (void) setGapless: (BOOL) gapless
{
	id v = [NSNumber numberWithBool:gapless];
	[[self propertyWithCode:'pGpl'] setTo:v];
}

- (NSString *) genre
{
	return [[self propertyWithCode:'pGen'] get];
}

- (void) setGenre: (NSString *) genre
{
	[[self propertyWithCode:'pGen'] setTo:genre];
}

- (NSString *) grouping
{
	return [[self propertyWithCode:'pGrp'] get];
}

- (void) setGrouping: (NSString *) grouping
{
	[[self propertyWithCode:'pGrp'] setTo:grouping];
}

- (NSString *) kind
{
	return [[self propertyWithCode:'pKnd'] get];
}

- (NSString *) longDescription
{
	return [[self propertyWithCode:'pLds'] get];
}

- (void) setLongDescription: (NSString *) longDescription
{
	[[self propertyWithCode:'pLds'] setTo:longDescription];
}

- (NSString *) lyrics
{
	return [[self propertyWithCode:'pLyr'] get];
}

- (void) setLyrics: (NSString *) lyrics
{
	[[self propertyWithCode:'pLyr'] setTo:lyrics];
}

- (NSDate *) modificationDate
{
	return [[self propertyWithCode:'asmo'] get];
}

- (NSInteger) playedCount
{
	id v = [[self propertyWithCode:'pPlC'] get];
	return [v integerValue];
}

- (void) setPlayedCount: (NSInteger) playedCount
{
	id v = [NSNumber numberWithInteger:playedCount];
	[[self propertyWithCode:'pPlC'] setTo:v];
}

- (NSDate *) playedDate
{
	return [[self propertyWithCode:'pPlD'] get];
}

- (void) setPlayedDate: (NSDate *) playedDate
{
	[[self propertyWithCode:'pPlD'] setTo:playedDate];
}

- (BOOL) podcast
{
	id v = [[self propertyWithCode:'pTPc'] get];
	return [v boolValue];
}

- (NSInteger) rating
{
	id v = [[self propertyWithCode:'pRte'] get];
	return [v integerValue];
}

- (void) setRating: (NSInteger) rating
{
	id v = [NSNumber numberWithInteger:rating];
	[[self propertyWithCode:'pRte'] setTo:v];
}

- (iTunesERtK) ratingKind
{
	id v = [[self propertyWithCode:'pRtk'] get];
	return [v enumCodeValue];
}

- (NSDate *) releaseDate
{
	return [[self propertyWithCode:'pRlD'] get];
}

- (NSInteger) sampleRate
{
	id v = [[self propertyWithCode:'pSRt'] get];
	return [v integerValue];
}

- (NSInteger) seasonNumber
{
	id v = [[self propertyWithCode:'pSeN'] get];
	return [v integerValue];
}

- (void) setSeasonNumber: (NSInteger) seasonNumber
{
	id v = [NSNumber numberWithInteger:seasonNumber];
	[[self propertyWithCode:'pSeN'] setTo:v];
}

- (BOOL) shufflable
{
	id v = [[self propertyWithCode:'pSfa'] get];
	return [v boolValue];
}

- (void) setShufflable: (BOOL) shufflable
{
	id v = [NSNumber numberWithBool:shufflable];
	[[self propertyWithCode:'pSfa'] setTo:v];
}

- (NSInteger) skippedCount
{
	id v = [[self propertyWithCode:'pSkC'] get];
	return [v integerValue];
}

- (void) setSkippedCount: (NSInteger) skippedCount
{
	id v = [NSNumber numberWithInteger:skippedCount];
	[[self propertyWithCode:'pSkC'] setTo:v];
}

- (NSDate *) skippedDate
{
	return [[self propertyWithCode:'pSkD'] get];
}

- (void) setSkippedDate: (NSDate *) skippedDate
{
	[[self propertyWithCode:'pSkD'] setTo:skippedDate];
}

- (NSString *) show
{
	return [[self propertyWithCode:'pShw'] get];
}

- (void) setShow: (NSString *) show
{
	[[self propertyWithCode:'pShw'] setTo:show];
}

- (NSString *) sortAlbum
{
	return [[self propertyWithCode:'pSAl'] get];
}

- (void) setSortAlbum: (NSString *) sortAlbum
{
	[[self propertyWithCode:'pSAl'] setTo:sortAlbum];
}

- (NSString *) sortArtist
{
	return [[self propertyWithCode:'pSAr'] get];
}

- (void) setSortArtist: (NSString *) sortArtist
{
	[[self propertyWithCode:'pSAr'] setTo:sortArtist];
}

- (NSString *) sortAlbumArtist
{
	return [[self propertyWithCode:'pSAA'] get];
}

- (void) setSortAlbumArtist: (NSString *) sortAlbumArtist
{
	[[self propertyWithCode:'pSAA'] setTo:sortAlbumArtist];
}

- (NSString *) sortName
{
	return [[self propertyWithCode:'pSNm'] get];
}

- (void) setSortName: (NSString *) sortName
{
	[[self propertyWithCode:'pSNm'] setTo:sortName];
}

- (NSString *) sortComposer
{
	return [[self propertyWithCode:'pSCm'] get];
}

- (void) setSortComposer: (NSString *) sortComposer
{
	[[self propertyWithCode:'pSCm'] setTo:sortComposer];
}

- (NSString *) sortShow
{
	return [[self propertyWithCode:'pSSN'] get];
}

- (void) setSortShow: (NSString *) sortShow
{
	[[self propertyWithCode:'pSSN'] setTo:sortShow];
}

- (NSInteger) size
{
	id v = [[self propertyWithCode:'pSiz'] get];
	return [v integerValue];
}

- (double) start
{
	id v = [[self propertyWithCode:'pStr'] get];
	return [v doubleValue];
}

- (void) setStart: (double) start
{
	id v = [NSNumber numberWithDouble:start];
	[[self propertyWithCode:'pStr'] setTo:v];
}

- (NSString *) time
{
	return [[self propertyWithCode:'pTim'] get];
}

- (NSInteger) trackCount
{
	id v = [[self propertyWithCode:'pTrC'] get];
	return [v integerValue];
}

- (void) setTrackCount: (NSInteger) trackCount
{
	id v = [NSNumber numberWithInteger:trackCount];
	[[self propertyWithCode:'pTrC'] setTo:v];
}

- (NSInteger) trackNumber
{
	id v = [[self propertyWithCode:'pTrN'] get];
	return [v integerValue];
}

- (void) setTrackNumber: (NSInteger) trackNumber
{
	id v = [NSNumber numberWithInteger:trackNumber];
	[[self propertyWithCode:'pTrN'] setTo:v];
}

- (BOOL) unplayed
{
	id v = [[self propertyWithCode:'pUnp'] get];
	return [v boolValue];
}

- (void) setUnplayed: (BOOL) unplayed
{
	id v = [NSNumber numberWithBool:unplayed];
	[[self propertyWithCode:'pUnp'] setTo:v];
}

- (iTunesEVdK) videoKind
{
	id v = [[self propertyWithCode:'pVdK'] get];
	return [v enumCodeValue];
}

- (void) setVideoKind: (iTunesEVdK) videoKind
{
	id v = [NSAppleEventDescriptor descriptorWithEnumCode:videoKind];
	[[self propertyWithCode:'pVdK'] setTo:v];
}

- (NSInteger) volumeAdjustment
{
	id v = [[self propertyWithCode:'pAdj'] get];
	return [v integerValue];
}

- (void) setVolumeAdjustment: (NSInteger) volumeAdjustment
{
	id v = [NSNumber numberWithInteger:volumeAdjustment];
	[[self propertyWithCode:'pAdj'] setTo:v];
}

- (NSInteger) year
{
	id v = [[self propertyWithCode:'pYr '] get];
	return [v integerValue];
}

- (void) setYear: (NSInteger) year
{
	id v = [NSNumber numberWithInteger:year];
	[[self propertyWithCode:'pYr '] setTo:v];
}



@end


@implementation iTunesAudioCDTrack


- (NSURL *) location
{
	return [[self propertyWithCode:'pLoc'] get];
}



@end


@implementation iTunesDeviceTrack



@end


@implementation iTunesFileTrack


- (NSURL *) location
{
	return [[self propertyWithCode:'pLoc'] get];
}

- (void) setLocation: (NSURL *) location
{
	[[self propertyWithCode:'pLoc'] setTo:location];
}


- (void) refresh
{
	[self sendEvent:'hook' id:'Rfrs' parameters:0];
}


@end


@implementation iTunesSharedTrack



@end


@implementation iTunesURLTrack


- (NSString *) address
{
	return [[self propertyWithCode:'pURL'] get];
}

- (void) setAddress: (NSString *) address
{
	[[self propertyWithCode:'pURL'] setTo:address];
}


- (void) download
{
	[self sendEvent:'hook' id:'Dwnl' parameters:0];
}


@end


@implementation iTunesUserPlaylist


- (SBElementArray *) fileTracks
{
	return [self elementArrayWithCode:'cFlT'];
}


- (SBElementArray *) URLTracks
{
	return [self elementArrayWithCode:'cURT'];
}


- (SBElementArray *) sharedTracks
{
	return [self elementArrayWithCode:'cShT'];
}



- (BOOL) shared
{
	id v = [[self propertyWithCode:'pShr'] get];
	return [v boolValue];
}

- (void) setShared: (BOOL) shared
{
	id v = [NSNumber numberWithBool:shared];
	[[self propertyWithCode:'pShr'] setTo:v];
}

- (BOOL) smart
{
	id v = [[self propertyWithCode:'pSmt'] get];
	return [v boolValue];
}



@end


@implementation iTunesFolderPlaylist



@end


@implementation iTunesVisual



@end


@implementation iTunesWindow


- (NSRect) bounds
{
	id v = [[self propertyWithCode:'pbnd'] get];
	return [v rectValue];
}

- (void) setBounds: (NSRect) bounds
{
	id v = [NSValue valueWithRect:bounds];
	[[self propertyWithCode:'pbnd'] setTo:v];
}

- (BOOL) closeable
{
	id v = [[self propertyWithCode:'hclb'] get];
	return [v boolValue];
}

- (BOOL) collapseable
{
	id v = [[self propertyWithCode:'pWSh'] get];
	return [v boolValue];
}

- (BOOL) collapsed
{
	id v = [[self propertyWithCode:'wshd'] get];
	return [v boolValue];
}

- (void) setCollapsed: (BOOL) collapsed
{
	id v = [NSNumber numberWithBool:collapsed];
	[[self propertyWithCode:'wshd'] setTo:v];
}

- (NSPoint) position
{
	id v = [[self propertyWithCode:'ppos'] get];
	return [v pointValue];
}

- (void) setPosition: (NSPoint) position
{
	id v = [NSValue valueWithPoint:position];
	[[self propertyWithCode:'ppos'] setTo:v];
}

- (BOOL) resizable
{
	id v = [[self propertyWithCode:'prsz'] get];
	return [v boolValue];
}

- (BOOL) visible
{
	id v = [[self propertyWithCode:'pvis'] get];
	return [v boolValue];
}

- (void) setVisible: (BOOL) visible
{
	id v = [NSNumber numberWithBool:visible];
	[[self propertyWithCode:'pvis'] setTo:v];
}

- (BOOL) zoomable
{
	id v = [[self propertyWithCode:'iszm'] get];
	return [v boolValue];
}

- (BOOL) zoomed
{
	id v = [[self propertyWithCode:'pzum'] get];
	return [v boolValue];
}

- (void) setZoomed: (BOOL) zoomed
{
	id v = [NSNumber numberWithBool:zoomed];
	[[self propertyWithCode:'pzum'] setTo:v];
}



@end


@implementation iTunesBrowserWindow


- (BOOL) minimized
{
	id v = [[self propertyWithCode:'pMin'] get];
	return [v boolValue];
}

- (void) setMinimized: (BOOL) minimized
{
	id v = [NSNumber numberWithBool:minimized];
	[[self propertyWithCode:'pMin'] setTo:v];
}

- (SBObject *) selection
{
	return (SBObject *) [self propertyWithClass:[SBObject class] code:'sele'];
}

- (iTunesPlaylist *) view
{
	return (iTunesPlaylist *) [self propertyWithClass:[iTunesPlaylist class] code:'pPly'];
}

- (void) setView: (iTunesPlaylist *) view
{
	[[self propertyWithClass:[iTunesPlaylist class] code:'pPly'] setTo:view];
}



@end


@implementation iTunesEQWindow


- (BOOL) minimized
{
	id v = [[self propertyWithCode:'pMin'] get];
	return [v boolValue];
}

- (void) setMinimized: (BOOL) minimized
{
	id v = [NSNumber numberWithBool:minimized];
	[[self propertyWithCode:'pMin'] setTo:v];
}



@end


@implementation iTunesPlaylistWindow


- (SBObject *) selection
{
	return (SBObject *) [self propertyWithClass:[SBObject class] code:'sele'];
}

- (iTunesPlaylist *) view
{
	return (iTunesPlaylist *) [self propertyWithClass:[iTunesPlaylist class] code:'pPly'];
}



@end


