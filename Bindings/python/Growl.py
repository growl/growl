"""
A Python module that enables posting notifications to the Growl daemon.  
See <http://sourceforge.net/projects/growl/> for more information.

Requires PyObjC 1.1 <http://pyobjc.sourceforge.net/> and Python 2.3
<http://www.python.org/>.

Copyright 2003 Mark Rowe <bdash@users.sourceforge.net>
Released under the BSD license.
"""

from Foundation import NSArray, NSDistributedNotificationCenter, NSDictionary, NSNumber
from AppKit import NSWorkspace

class GrowlNotifier(object):
    """
    A class that abstracts the process of registering and posting
    notifications to the Growl daemon.
    
    You can either pass `applicationName', `notifications',
    `defaultNotifications' and `applicationIcon' to the constructor
    or you may define them as class-level variables in a sub-class.
    
    `defaultNotifications' is optional, and defaults to the value of
    `notifications'.  `applicationIcon' is also optional but defaults
    to a pointless icon so is better to be specified.
    """
    
    applicationName = 'GrowlNotifier'
    notifications = []
    defaultNotifications = None
    applicationIcon = None
    
    def __init__(self, applicationName=None, notifications=None, defaultNotifications=None, applicationIcon=None):
        if applicationName is not None:
            self.applicationName = applicationName
        if notifications is not None:
            self.notifications = notifications
        if defaultNotifications is not None:
            self.defaultNotifications = defaultNotifications
        if applicationIcon is not None:
            self.applicationIcon = applicationIcon
    
    def register(self):
        """
        Register this application with the Growl daemon.
        """
        if not self.applicationIcon:
            self.applicationIcon = NSWorkspace.sharedWorkspace().iconForFileType_("txt")
        if self.defaultNotifications is None:
            self.defaultNotifications = self.notifications
    
        regInfo = {'ApplicationName': self.applicationName,
                   'AllNotifications': NSArray.arrayWithArray_(self.notifications),
                   'DefaultNotifications': NSArray.arrayWithArray_(self.defaultNotifications),
                   'ApplicationIcon': self.applicationIcon.TIFFRepresentation()}
    
        d = NSDictionary.dictionaryWithDictionary_(regInfo)
        notCenter = NSDistributedNotificationCenter.defaultCenter()
        notCenter.postNotificationName_object_userInfo_deliverImmediately_("GrowlApplicationRegistrationNotification", None, d, True)
    
    def notify(self, noteType, title, description, icon=None, appicon=None, style=None, sticky=False):
        """
        Post a notification to the Growl daemon.
        
        `noteType' is the name of the notification that is being posted.
        `title' is the user-visible title for this notification.
        `description' is the user-visible description of this notification.
        `icon' is an optional icon for this notification.  It defaults to
            `self.applicationIcon'.
        `appicon' is an optional icon for the sending application.
        `sticky' is a boolean controlling whether the notification is sticky.
        """
        assert noteType in self.notifications
        if icon is None:
            icon = self.applicationIcon
        
        n = {'NotificationName': noteType,
             'ApplicationName': self.applicationName,
             'NotificationTitle': title,
             'NotificationDescription': description,
             'NotificationDefault': NSNumber.numberWithBool_(True),
             'NotificationIcon': icon.TIFFRepresentation()}
             
        if style is not None:
             n['NotificationDefault'] = NSNumber.numberWithBool_(False)
        
        if appicon is not None:
             n['NotificationAppIcon'] = appicon.TIFFRepresentation()
        
        if sticky:
             n['NotificationSticky'] = NSNumber.numberWithBool_(True)

        d = NSDictionary.dictionaryWithDictionary_(n)
        notCenter = NSDistributedNotificationCenter.defaultCenter()
        notCenter.postNotificationName_object_userInfo_deliverImmediately_('GrowlNotification', None, d, True)

def main():
    from Foundation import NSRunLoop, NSDate
    class TestGrowlNotifier(GrowlNotifier):
        applicationName = 'Test Growl Notifier'
        notifications = ['Foo']

    n = TestGrowlNotifier(applicationIcon=NSWorkspace.sharedWorkspace().iconForFileType_('unknown'))
    n.register()
    
    # A small delay to ensure our notification will be shown.
    NSRunLoop.currentRunLoop().runUntilDate_(NSDate.dateWithTimeIntervalSinceNow_(0.1))
    n.notify('Foo', 'Test Notification', 'Blah blah blah')

if __name__ == '__main__':
    main()
