//
//  JKServiceBrowserDelegate.h
//  Rawr-endezvous
//
//  Created by Jeremy Knope on 9/25/04.
//  Copyright 2004 Jeremy Knope. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface JKServiceBrowserDelegate : NSObject {
	IBOutlet NSBrowser *serviceBrowser;
	NSMutableArray *services;
	NSMutableDictionary *serviceTypes;
    
    //IBOutlet NSTextField *nameField;
    //IBOutlet NSTextField *serviceField;
    //IBOutlet NSTextField *addressField;
    
	// sucky
	NSString *resAddress;
	NSString *resPort;
	NSNetService *serviceBeingResolved;
}

- (void)awakeFromNib;

- (void)addService:(NSNotification *)note;
- (void)removeService:(NSNotification *)note;
@end
