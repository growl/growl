/* FireWireNotifier */

#import <Cocoa/Cocoa.h>

extern	NSString		*NotifierFireWireConnectionNotification;
extern	NSString		*NotifierFireWireDisconnectionNotification;


@interface FireWireNotifier : NSObject
{
	IONotificationPortRef	ioKitNotificationPort;
	CFRunLoopSourceRef		notificationRunLoopSource;
}

-(void)ioKitSetUp;
-(void)ioKitTearDown;

-(void)registerForFireWireNotifications;
-(void)fwDeviceAdded: (io_iterator_t ) iterator; 
-(void)fwDeviceRemoved: (io_iterator_t ) iterator; 

-(NSString *)nameForFireWireObject: (io_object_t) thisObject;



	void fwDeviceAdded (void *refCon, io_iterator_t iter);
	void fwDeviceRemoved (void *refCon, io_iterator_t iter);

@end
