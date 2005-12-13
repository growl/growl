/*
 
 BSD License
 
 Copyright (c) 2005, Jesper <wootest@gmail.com>
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 * Neither the name of Gmail+Growl or Jesper, nor the names of Gmail+Growl's contributors 
 may be used to endorse or promote products derived from this software without
 specific prior written permission.
 
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
 
 The name Gmail is owned by Google, Inc. Growl is owned by the Growl Development Team.
 Likewise, the logos of those services are owned and copyrighted to their owners.
 No ownership of any of these is assumed or implied, and no infringement is intended.
 
 For more info on this products or on the technologies on which it builds: 
 Growl: <http://growl.info/>
 Gmail: <http://gmail.com>
 Gmail Notifier: <http://toolbar.google.com/gmail-helper/index.html>
 
 Gmail+Growl: <http://wootest.net/gmailgrowl/>
 
 */

//
//  GMNGrowlInstaller.m
//  GMNGrowl
//
//  Created by Jesper on 2005-09-19.
//  Copyright 2005 Jesper. All rights reserved.
//  Contact: <wootest@gmail.com>.
//

#import "GMNGrowlInstaller.h"

#define GMNGrowlInstallerAppSupportPath		[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"]
#define GMNGrowlInstallerGMNPluginPath		[GMNGrowlInstallerAppSupportPath stringByAppendingPathComponent:@"Gmail Notifier"]
#define GMNGrowlInstallerDestPath			[GMNGrowlInstallerGMNPluginPath stringByAppendingPathComponent:@"GmailGrowl.plugin"]

@implementation GMNGrowlInstaller

- (void)awakeFromNib {
	hasInstalled = NO;
	NSSize minSize = [[self window] minSize];
	[[self window] setMaxSize:NSMakeSize(minSize.width,[[self window] maxSize].height)];
}

- (IBAction)install:(id)sender
{
	if (!hasInstalled) {
		[notice setHidden:YES];
		[installButton setHidden:YES];
		[installingProgress setHidden:NO];
		NSRect fr = [[self window] frame];
		NSSize minS = [[self window] minSize];
		NSSize maxS = [[self window] maxSize];
		float diff = maxS.height - minS.height;
		NSRect newFr = NSMakeRect(fr.origin.x,fr.origin.y+diff,minS.width,minS.height);
		[[self window] setFrame:newFr display:YES animate:YES];		
		[installingProgress setUsesThreadedAnimation:YES];
		[installingProgress startAnimation:self];
		
		BOOL isDir; BOOL exists;
		exists = [[NSFileManager defaultManager] fileExistsAtPath:GMNGrowlInstallerGMNPluginPath isDirectory:&isDir];
		if (!(exists) || !(isDir)) {
			NSLog(@"-WTF: Exists: %@, isDir: %@.", (exists ? @"YES" : @"NO"),  (isDir ? @"YES" : @"NO"));
			if (![[NSFileManager defaultManager] createDirectoryAtPath:GMNGrowlInstallerGMNPluginPath attributes:nil]) {
				[self showNotice:@"Can't install Gmail+Growl; can't create folder."];
				NSLog(@"-ERR: Installer can't create folder at %@.", GMNGrowlInstallerGMNPluginPath);
				return;
			}
		}
		if ([[NSFileManager defaultManager] fileExistsAtPath:GMNGrowlInstallerDestPath]) {
			NSLog(@"-WTF: Exists... remove it.");
			if(![[NSFileManager defaultManager] removeFileAtPath:GMNGrowlInstallerDestPath handler:nil]) {
				[self showNotice:@"Can't install Gmail+Growl; can't remove older version."];
				NSLog(@"-ERR: Installer can't remove older version at %@.", GMNGrowlInstallerDestPath);
				return;	
			}
		}
			
		if (![[NSFileManager defaultManager] copyPath:[[NSBundle mainBundle] pathForResource:@"GmailGrowl" ofType:@"plugin"] toPath:GMNGrowlInstallerDestPath handler:nil]) {
			[self showNotice:@"Can't install Gmail+Growl; can't copy plugin."];
			NSLog(@"-ERR: Installer can't copy plugin to %@.", [GMNGrowlInstallerGMNPluginPath stringByAppendingPathComponent:@"GmailGrowl.plugin"]);
			return;
		}
		[self showNotice:@"Gmail+Growl was installed."];
	} else {
		[[NSWorkspace sharedWorkspace] launchApplication:@"Gmail Notifier"];
		[[NSApplication sharedApplication] terminate:self];
	}
	
}

- (void)showNotice:(NSString *)str {
	[installingProgress stopAnimation:self];
	[installingProgress setHidden:YES];
	[notice setHidden:NO];
	[notice setStringValue:str];
	[installButton setTitle:@"OK"];
	
	NSRect fr = [[self window] frame];
	NSSize minS = [[self window] minSize];
	NSSize maxS = [[self window] maxSize];
	float diff = maxS.height - minS.height;	
	NSRect newFr = NSMakeRect(fr.origin.x,fr.origin.y-diff,maxS.width,maxS.height);
	[[self window] setFrame:newFr display:YES animate:YES];		
	[installButton setHidden:NO];
	
		hasInstalled = YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
	return YES;
}

@end
