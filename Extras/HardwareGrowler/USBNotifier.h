/* USBNotifier */

#import <Cocoa/Cocoa.h>


#include <IOKit/IOKitLib.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/usb/IOUSBLib.h>
#include <IOKit/usb/USB.h>


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



	void usbDeviceAdded (void *refCon, io_iterator_t iter);
	void usbDeviceRemoved (void *refCon, io_iterator_t iter);

@end
