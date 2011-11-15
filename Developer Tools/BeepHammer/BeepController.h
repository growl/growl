#ifdef GROWL_WITH_INSTALLER
	#import <Growl-WithInstaller/Growl.h>
#else
	#import <Growl/Growl.h>
#endif
/* BeepController */


@interface BeepController: NSObject<GrowlApplicationBridgeDelegate>

- (IBAction)removeAllNotifications:(id)sender;

- (IBAction)toggleGrowlLogging:(id)sender;
- (IBAction)editNotification:(id)sender;

- (IBAction)showAddSheet:(id)sender;
- (IBAction)showEditSheet:(id)sender;

//actions in sheet
- (IBAction)OKNotification:(id)sender;
- (IBAction)cancelNotification:(id)sender;
- (IBAction)clearImage:(id)sender;

//actions in main window
//- (IBAction)addNotification:(id)sender; //the + button
- (IBAction)removeNotification:(id)sender; //the - button
- (IBAction)sendNotification:(id)sender; //the Send button
//- (IBAction)endPanel:(id)sender;

@end

