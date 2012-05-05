//
//  StatusDisplayer.h
//  Status Checker
//
//  Created by Peter Hosey on 2009-08-07.
//  Copyright 2009 Peter Hosey. All rights reserved.
//

@interface StatusDisplayer : NSObject {
	IBOutlet NSWindow *window;

	BOOL isGrowlInstalled;
	BOOL isGrowlRunning;
}

@property(assign) BOOL isGrowlInstalled;
@property(assign) BOOL isGrowlRunning;

@end
