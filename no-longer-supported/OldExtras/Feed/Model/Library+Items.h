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
#import <Cocoa/Cocoa.h>
#import "Library.h"

@interface Library (Items)

-(NSString *)typeForItem:(id)item;
-(BOOL)isFolderItem:(id)item;
-(BOOL)isFeedItem:(id)item;
-(BOOL)isArticleItem:(id)item;

-(BOOL)isItem:(id)item1 descendentOfItem:(id)item2;

-(id)newFolderNamed:(NSString *)name inItem:(id)item atIndex:(int)index;
-(id)newFeed:(KNFeed *)feed inItem:(id)item atIndex:(int)index;
-(id)newArticle:(KNArticle *)article inItem:(id)item atIndex:(int)index;

-(void)removeItem:(id)item;
-(void)removeItem:(id)item fromItem:(id)parentItem;
-(void)moveItem:(id)item toParent:(id)parent index:(int)index;

-(NSString *)nameForItem:(id)item;
-(NSString *)keyForItem:(id)item;
-(id)itemForKey:(NSString *)key;
-(void)setName:(NSString *)name forItem:(id)item;
-(KNFeed *)feedForItem:(id)item;
-(KNArticle *)articleForItem:(id)item;

-(id)child:(int)index ofItem:(id)item;
-(BOOL)hasChildren:(id)item;
-(int)childCountOfItem:(id)item;

-(unsigned)unreadCountForItem:(id)item;

@end
