//
//  SGHotKeyCenterAppDelegate.h
//  SGHotKeyCenter
//
//  Created by Justin Williams on 7/26/09.
//  Copyright 2009 Second Gear. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ShortcutRecorder/ShortcutRecorder.h>
#import "SGHotKey.h"

extern NSString *kGlobalHotKey;

@interface SGHotKeyCenterAppDelegate : NSObject {
  NSWindow *window;
  SRRecorderControl *hotKeyControl;
  NSTextField *resultsTextField;
  
  SGHotKey *hotKey;
}

@property (nonatomic, retain) IBOutlet NSWindow *window;
@property (nonatomic, retain) IBOutlet SRRecorderControl *hotKeyControl;
@property (nonatomic, retain) IBOutlet NSTextField *resultsTextField;
@property (nonatomic, retain) SGHotKey *hotKey;

@end
