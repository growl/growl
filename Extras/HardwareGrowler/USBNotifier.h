/* USBNotifier */

#import <Cocoa/Cocoa.h>
#import <IOKit/IOKitLib.h>


extern	NSString		*NotifierUSBConnectionNotification;
extern	NSString		*NotifierUSBDisconnectionNotification;


@interface USBNotifier : NSObject
{
	IONotificationPortRef	ioKitNotificationPort;
	CFRunLoopSourceRef		notificationRunLoopSource;
}

-(void)ioKitSetUp;
-(void)ioKitTearDown;

-(void)registerForUSBNotifications;
-(void)usbDeviceAdded: (io_iterator_t ) iterator; 
-(void)usbDeviceRemoved: (io_iterator_t ) iterator; 

@end
