/* BeepController */

#import <Cocoa/Cocoa.h>

@interface BeepController : NSObject {
	//add notification sheet fields
	IBOutlet NSPanel		*_newNotificationPanel;				// The Add Panel
    IBOutlet NSButton		*_newNotificationDefault;			// Whether this note is on by default
    IBOutlet NSTextField	*_newNotificationDescription;		// The long description
    IBOutlet NSImageView	*_newNotificationImage;				// The associated image
    IBOutlet NSTextField	*_newNotificationTitle;				// The name of this note
	
	//main window
    IBOutlet NSTableView	*_notificationsTable;				// The table of notifications
    IBOutlet NSButton		*_registered;						// The magic button the registers/unregisters
    IBOutlet NSButton		*_removeNotification;				// The remove button (TBR)
	
	//data
	NSMutableArray			*_notifications;					// The Array of notifications
}

- (IBAction)addNotification:(id)sender;
- (IBAction)registerBeep:(id)sender;
- (IBAction)sendNotification:(id)sender;
@end
