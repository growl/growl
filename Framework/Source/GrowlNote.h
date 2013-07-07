//
//  GrowlNote.h
//  Growl
//
//  Created by Daniel Siemer on 5/7/13.
//  Copyright (c) 2013 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GrowlCommunicationAttempt, GrowlNote;

/*!
 * @enum GrowlNoteStatus
 * Values for the final status of a notification
 * Not all values will be sent with all versions of Growl.
 * Older versions will only do TimedOut and Clicked
 */

enum GrowlNoteStatus {
   GrowlNoteCanceled = -3,
   GrowlNoteNotDisplayed = -2,
   GrowlNoteClosed = -1,
   GrowlNoteTimedOut = 0,
   GrowlNoteClicked = 1,
   GrowlNoteActionClicked = 2,
   GrowlNoteOtherClicked = 3,
};
typedef enum GrowlNoteStatus GrowlNoteStatus;

typedef void(^GrowlNoteStatusUpdateBlock)(GrowlNoteStatus status, GrowlNote *note);

/*!
 * @protocol GrowlNoteDelegate used to send an update on the final status of a notification
 * @method note:statusUpdate: a status update 
 */
@protocol GrowlNoteDelegate <NSObject>

-(void)note:(GrowlNote*)note statusUpdate:(GrowlNoteStatus)status;

@end

@interface GrowlNote : NSObject {
   NSString *_noteUUID;
   
   NSString *_noteName;
   NSString *_title;
   NSString *_description;
   NSData *_iconData;
   id _clickContext;
   NSURL *_clickCallbackURL;
   NSString *_overwriteIdentifier;
   BOOL _sticky;
   NSInteger _priority;
   
   NSDictionary *_otherKeysDict;
   
   id<GrowlNoteDelegate> _delegate;
   GrowlNoteStatusUpdateBlock _statusUpdateBlock;
   
   @private
   GrowlCommunicationAttempt *_firstAttempt;
   GrowlCommunicationAttempt *_secondAttempt;
   
   NSInteger _status;
   BOOL _localDisplayed;
}

/*!
 * @property nonatomic, assign, delegate
 * @discussion The delegate for this note, must conform to <code>GrowlNoteDelegate</code>
 *  Used if statusUpdateBlock not defined
 *  If neither are set, GrowlApplicationBridge is used as its delegate, ultimately calling GAB's delegate
 *  This or the statusUpdateBlock will only be called once per note
 *  Called on the main thread/queue
 */
@property (nonatomic, assign) id<GrowlNoteDelegate> delegate;
/*!
 * @property nonatomic, assign, statusUpdateBlock
 * @discussion A block for informing you of the final status of a notification
 *  If neither are set, GrowlApplicationBridge is used as its delegate, ultimately calling GAB's delegate
 *  This or the delegate will only be called once per note
 *  Called on the main thread/queue
 */
@property (nonatomic, copy) GrowlNoteStatusUpdateBlock statusUpdateBlock;

/*!
 * @property the note's UUID, used to handle cancelation of a delivered notification, readonly, you can grab a reference to it before using <code>notifyWithNote:</code>
 */
@property (nonatomic, readonly) NSString *noteUUID;

/*!
 * @discussion These properties are adjustable after sending for now,
 * however adjusting them won't reflect in any notification already delivered
 * @property (nonatomic, retain) NSString *noteName;
 * @property (nonatomic, retain) NSString *title;
 * @property (nonatomic, retain) NSString *description;
 * @property (nonatomic, retain) NSData *iconData;
 * @property (nonatomic, retain) id clickContext;
 * @property (nonatomic, retain) NSURL *clickCallbackURL;
 * @property (nonatomic, retain) NSString *overwriteIdentifier;
 * @property (nonatomic, assign) BOOL sticky;
 * @property (nonatomic, assign) NSInteger priority;
 */
@property (nonatomic, retain) NSString *noteName;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSData *iconData;
@property (nonatomic, retain) id clickContext;
@property (nonatomic, retain) NSURL *clickCallbackURL;
@property (nonatomic, retain) NSString *overwriteIdentifier;
@property (nonatomic, assign) BOOL sticky;
@property (nonatomic, assign) NSInteger priority;

/*!
 * @property (nonatomic, readonly) NSDictionary noteDictionary
 * @discussion Not settable or adjustable at present, methods will be introduced that can set/remove custom values in a future framework
 */
@property (nonatomic, readonly) NSDictionary *noteDictionary;

/*!@brief Initialize a notification using a dictionary
 *  requires values for GROWL_NOTIFICATION_NAME and either GROWL_NOTIFICATION_TITLE or GROWL_NOTIFICATION_DESCRIPTION
 *	@param dictionary, the dictionary to initialize with.
 *	@return A GrowlNote initialized using the given dictionary
 *	@discussion	This function serves as a way of initializing with a dictionary, whose keys are defined in GrowlDefines.h
 *
 *	@since Growl.framework 3.0
 */
-(id)initWithDictionary:(NSDictionary*)dictionary;

/*!@brief Initialize a notification using a dictionary
 *  requires values for GROWL_NOTIFICATION_NAME and either GROWL_NOTIFICATION_TITLE or GROWL_NOTIFICATION_DESCRIPTION
 *	@param dictionary, the dictionary to initialize with.
 *	@return A GrowlNote initialized using the given dictionary, autoreleased
 *	@discussion	This function serves as a way of initializing with a dictionary, whose keys are defined in GrowlDefines.h
 *
 *	@since Growl.framework 3.0
 */
+(GrowlNote*)noteWithDictionary:(NSDictionary*)dict;

/*!
 *	@abstract Initialize a notification.
 *	@discussion This is the preferred means for initializing a Growl notification.
 *	 The notification name and at least one of the title and description are
 *	 required (all three are preferred).  All other parameters may be
 *	 <code>nil</code> (or 0 or NO as appropriate) to accept default values.
 *
 *	@param title		The title of the notification displayed to the user.
 *	@param description	The full description of the notification displayed to the user.
 *	@param notifName	The internal name of the notification. Should be human-readable, as it will be displayed in the Growl preference pane.
 *	@param iconData		<code>NSData</code> object to show with the notification as its icon. If <code>nil</code>, the application's icon will be used instead.
 *	@param priority		The priority of the notification. The default value is 0; positive values are higher priority and negative values are lower priority. Not all Growl displays support priority.
 *	@param isSticky		If YES, the notification will remain on screen until clicked. Not all Growl displays support sticky notifications.
 *	@param clickContext	A context passed back to the Growl delegate if it implements -(void)growlNotificationWasClicked: and the notification is clicked. Not all display plugins support clicking. The clickContext must be plist-encodable (completely of <code>NSString</code>, <code>NSArray</code>, <code>NSNumber</code>, <code>NSDictionary</code>, and <code>NSData</code> types).
 * @param actionButtonTitle a string to use as the action button title in NSUserNotificationCenter
 * @param cancelButtonTitle a string to use as the cancel button title in NSUserNotificationCenter
 *	@param identifier	An identifier for this notification. Notifications with equal identifiers are coalesced.
 */
-(id)initWithTitle:(NSString *)title
       description:(NSString *)description
  notificationName:(NSString *)notifName
          iconData:(NSData *)iconData
          priority:(NSInteger)priority
          isSticky:(BOOL)isSticky
      clickContext:(id)clickContext
 actionButtonTitle:(NSString *)actionTitle
 cancelButtonTitle:(NSString *)cancelTitle
        identifier:(NSString *)identifier;

/*!
 * @discussion Returns an autoreleased note, see the initializer for more information
 * @see initWithTitle:description:notificationName:iconData:priority:isSticky:clickContext:actionButtonTitle:cancelButtonTitle:identifier:
 */
+(GrowlNote*)noteWithTitle:(NSString *)title
               description:(NSString *)description
          notificationName:(NSString *)notifName
                  iconData:(NSData *)iconData
                  priority:(NSInteger)priority
                  isSticky:(BOOL)isSticky
              clickContext:(id)clickContext
         actionButtonTitle:(NSString *)actionTitle
         cancelButtonTitle:(NSString *)cancelTitle
                identifier:(NSString *)identifier;

@end
