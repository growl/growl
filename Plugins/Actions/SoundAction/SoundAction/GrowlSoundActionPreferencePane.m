//
//  GrowlSoundActionPreferencePane.m
//  SoundAction
//
//  Created by Daniel Siemer on 3/15/12.
//  Copyright 2012 The Growl Project, LLC. All rights reserved.
//

#import "GrowlSoundActionPreferencePane.h"
#import "GrowlSoundActionDefines.h"

@implementation GrowlSoundActionPreferencePane

@synthesize sounds;
@synthesize soundTableView;

-(void)dealloc {
	[sounds release];
	[super dealloc];
}

-(NSString*)mainNibName {
	return @"GrowlSoundActionPrefPane";
}

- (NSSet*)bindingKeys {
	static NSSet *keys = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		keys = [[NSSet setWithObjects:@"soundName",
												@"sounds", nil] retain];
	});
	return keys;
}

-(void)updateConfigurationValues {
	[self updateSoundsList];
	[super updateConfigurationValues];
	if((![self soundName] || ![sounds containsObject:[self soundName]]) && [sounds count] > 0){
		[self setSoundName:[sounds objectAtIndex:0U]];
	}
	[soundTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[sounds indexOfObject:[self soundName]]] 
					byExtendingSelection:NO];
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification	{
	NSInteger selectedRow = [soundTableView selectedRow];
	if(selectedRow > 0 && selectedRow < [sounds count]){
		NSString *soundName = [sounds objectAtIndex:selectedRow];
		if([[self soundName] caseInsensitiveCompare:soundName] != NSOrderedSame){
			[self setSoundName:soundName];
			[[NSSound soundNamed:soundName] play];
		}
	}
}

-(void)setSoundName:(NSString *)soundName {
	[self setConfigurationValue:soundName forKey:SelectedSoundPref];
}

-(NSString*)soundName {
	return [self.configuration valueForKey:SelectedSoundPref];
}

-(void)updateSoundsList {
	NSMutableArray *soundNames = [NSMutableArray array];
	
	NSArray *paths = [NSArray arrayWithObjects:@"/System/Library/Sounds",
                     @"/Library/Sounds",
                     [NSString stringWithFormat:@"%@/Library/Sounds", NSHomeDirectory()],
                     nil];
   
	[paths enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		BOOL isDirectory = NO;
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:obj isDirectory:&isDirectory]) {
			if (isDirectory) {
				
				NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:obj error:nil];
				for (NSString *filename in files) {
					NSString *file = [filename stringByDeletingPathExtension];
               
					if (![file isEqualToString:@".DS_Store"])
						[soundNames addObject:file];
				}
			}
		}
	}];
	self.sounds = soundNames;
}

@end
