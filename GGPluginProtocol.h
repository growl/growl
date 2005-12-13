//
//  GGPluginProtocol.h
//
//  Created by Greg Miller on 6/4/05.
//  Copyright 2005 Google, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/*!
    @protocol
 
    @abstract    Protocol describing the methods that must be implemented by 
                 any class that will be loaded as a Plugin by the Gmail Notifier.
 
    @discussion  Plugins may be installed in either/both of:
                 - /Library/Application Support/Gmail Notifier/
                 - ~/Library/Application Support/Gmail Notifier/
                 Plugins must have either a .bundle or .plugin extension.
 
                 Plugins will be allocated, then initialized using their -init method.
                 Multiple instances of the plugin class may be allocated and released
                 throughout the life of the program.
*/
@protocol GGPluginProtocol <NSObject>

/*!
    @method     
 
    @abstract   Called once the class has been loaded.
 
    @discussion This method is called when the class has been loaded by
                the runtime, but before any instances of the class have
                been created.  This method will be called exactly one time
                during the life of the application.
*/
+ (void)pluginLoaded;


/*!
    @method     

    @abstract   Called when the plugin is about to be unloaded.
    
    @discussion This method will be called when the application is shutting
                down.  This method will be called exactly one time during the
                life of the application.  The plugin will not receive any other
                messages after this one has been sent.
*/
+ (void)pluginWillUnload;


/*!
    @method     
 
    @abstract   Called everytime new mail is received.
 
    @discussion This method is called everytime new mail is received.  An
                instance of this class will be created with [[class alloc] init]
                immediately before calling this method, and it will be sent
                a -release immediately following the call to this method.
                The argument "messages" is an NSArray of NSDictionary objects.
                Each dictionary represents one message (NSLog() the messages argument
                to see the format of the array and dictionaries).  There is a max
                limit to the number of messages that can be in the messages array.
                Currently, the limit is 20, though this may change.
 
                The fullCount argument will be an integer representing the total 
                number of unread messages.  fullCount will be equal to [messages count]
                when there are less than the max number of messages (again, currently 20).
                If an account has 50 unread emails, the messages array will contain the 20
                newest unread messages ([messages count] == 20), and fullCount will be 50.
*/
- (void)newMessagesReceived:(NSArray *)messages
                  fullCount:(int)fullCount;

@end
