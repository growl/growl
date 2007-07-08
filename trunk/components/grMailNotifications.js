//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

////////////////////////////////////////////////////////////////////////////////
//// Constants

const nsISupports = Components.interfaces.nsISupports;
const nsIComponentRegistrar = Components.interfaces.nsIComponentRegistrar;
const nsICategoryManager = Components.interfaces.nsICategoryManager;
const nsIObserverService = Components.interfaces.nsIObserverService;
const nsIObserver = Components.interfaces.nsIObserver;
const nsIStringBundleService = Components.interfaces.nsIStringBundleService;
const nsIFolderListener = Components.interfaces.nsIFolderListener;
const grINotificationsList = Components.interfaces.grINotificationsList;
const nsIWindowWatcher = Components.interfaces.nsIWindowWatcher;
const nsIMsgFolder = Components.interfaces.nsIMsgFolder;

const CLASS_ID = Components.ID("33f659ee-9334-4f28-a742-344d95a520c4");
const CLASS_NAME = "Mail Notifications";
const CONTRACT_ID = "@growl.info/mail-notifications;1";

const THUNDERBIRD_ID = "{3550f703-e582-4d05-9a08-453d09bdfdc6}";

const GROWL_BUNDLE_LOCATION = "chrome://growl/locale/notifications.properties";

const MSG_FLAG_NEW = 0x10000;
const FLR_FLAG_TRASH = 0x0100;
const FLR_FLAG_JUNK = 0x40000000;
const FLR_FLAG_SENTMAIL = 0x0200;
const FLR_FLAG_IMAP_NOSELECT = 0x1000000;
const FLR_FLAG_CHECK_NEW = 0x20000000;
const SRV_RSS = "rss";

////////////////////////////////////////////////////////////////////////////////
//// Implementation

function grMailNotifications()
{
  this.grn = Components.classes["@growl.info/notifications;1"]
                       .getService(Components.interfaces.grINotifications);

  this.mObserverService = Components.classes["@mozilla.org/observer-service;1"]
                                    .getService(nsIObserverService);

  var sbs = Components.classes["@mozilla.org/intl/stringbundle;1"]
                      .getService(nsIStringBundleService);
  this.mBundle = sbs.createBundle(GROWL_BUNDLE_LOCATION);
    
  var as = Components.classes["@mozilla.org/atom-service;1"]
                     .getService(Components.interfaces.nsIAtomService);
  this.BiffStateAtom = as.getAtom("BiffState");

  this.mObserverService.addObserver(this, "before-growl-registration", false);
}

grMailNotifications.prototype = {
  //////////////////////////////////////////////////////////////////////////////
  //// nsIObserver
  observe: function observer(aSubject, aTopic, aData)
  {
    switch (aTopic) {
      case "before-growl-registration":
        this.mObserverService.removeObserver(this, "before-growl-registration");

        var nl = aSubject.QueryInterface(grINotificationsList);

        const notifications = [{key:"mail.new.title", enabled:true}];

        for (var i = notifications.length - 1; i >= 0; i--) {
          var name = this.mBundle.GetStringFromName(notifications[i].key);
          nl.addNotification(name, notifications[i].enabled);
        }

        // registering listeners
        var mms = Components.classes["@mozilla.org/messenger/services/session;1"]
                            .getService(Components.interfaces.nsIMsgMailSession);
        mms.AddFolderListener(this, nsIFolderListener.added);

        break;
      case "alertclickcallback":
        var wm = Components.classes["@mozilla.org/appshell/window-mediator;1"]
                           .getService(Components.interfaces.nsIWindowMediator);
        var win = wm.getMostRecentWindow("mail:3pane");
        if (win) {
          win.focus();
        } else {
          var ww = Components.classes["@mozilla.org/embedcomp/window-watcher;1"]
                             .getService(nsIWindowWatcher);
          ww.openWindow(null, "chrome://messenger/content/messenger.xul",
                        "_blank", "chrome,dialog=no,resizable", null);
        }

        this.grn.makeAppFocused();
        break;
      default:
    }
  },

  //////////////////////////////////////////////////////////////////////////////
  //// nsIFolderListener
  OnItemAdded: function OnItemAdded(aParentItem, aItem)
  {
    var header = aItem.QueryInterface(Components.interfaces.nsIMsgDBHdr);
    var folder = header.folder;

    if (!this.checkFolder(folder))
      return;

    if (header.flags & MSG_FLAG_NEW) {
      var name = this.mBundle.GetStringFromName("mail.new.title");
      var ttle = name + " - " + folder.prettiestName;
      var data = [header.mime2DecodedSubject, header.mime2DecodedAuthor];
      var msg  = this.mBundle.formatStringFromName("mail.new.text", data, 2);
      var img  = "chrome://growl/content/new-mail-alert.png";

      this.grn.sendNotification(name, img, ttle, msg, "", this);
    }
  },

  OnItemBoolPropertyChanged: function OnItemBoolPropertyChanged(aItem,
                                                                aProperty,
                                                                aOldValue,
                                                                aNewValue)
  {
  },

  OnItemEvent: function OnItemEvent(aItem, aEvent)
  {
  },

  OnItemIntPropertyChanged: function OnItemIntPropertyChanged(aItem, aProperty,
                                                              aOldValue,
                                                              aNewValue)
  {
    if (this.BiffStateAtom != aProperty) return;
    if (aNewValue != nsIMsgFolder.nsMsgBiffState_NewMail) return;

    var folder = aItem.QueryInterface(nsIMsgFolder);
    if (!folder.server.performingBiff) return;
  },

  OnItemPropertyChanged: function OnItemPropertyChanged(aItem, aProperty,
                                                        aOldValue, aNewValue)
  {
  },

  OnItemPropertyFlagChanged: function OnItemPropertyFlagChanged(aItem,
                                                                aProperty,
                                                                aOldFlag,
                                                                aNewFlag)
  {
  },

  OnItemRemoved: function OnItemRemoved(aParentItem, aItem)
  {
  },

  OnItemUnicharPropertyChanged: function OnItemUnicharPropertyChanged(aItem,
                                                                      aProperty,
                                                                      aOldValue,
                                                                      aNewValue)
  {
  },

  //////////////////////////////////////////////////////////////////////////////
  //// Helper Methods

  /**
   * This determines if this folder should even be checked to send a
   * notification to growl.
   *
   * @param aFolder The folder that we are checking
   * @return True if we need to check this folder, false otherwise.
   */
  checkFolder: function checkFolder(aFolder)
  {
    // XXX at least until I come up with some kind of message queue that slowly
    // displays messages, we ignore RSS feeds.
    
    // We don't check certain folders because they don't contain useful stuff
    if ((aFolder.flags & FLR_FLAG_TRASH) == FLR_FLAG_TRASH ||
        (aFolder.flags & FLR_FLAG_JUNK) == FLR_FLAG_JUNK ||
        (aFolder.flags & FLR_FLAG_SENTMAIL) == FLR_FLAG_SENTMAIL ||
        aFolder.server.type == SRV_RSS))
      return false;

    return true;
  },

  QueryInterface: function(aIID)
  {
    if (aIID.equals(nsISupports) || aIID.equals(nsIObserver) ||
        aIID.equals(nsIFolderListener))
      return this;

    throw Components.results.NS_ERROR_NO_INTERFACE;
  }
}

var grMailNotificationsFactory = {
  singleton: null,
  createInstance: function (aOuter, aIID)
  {
    if (aOuter != null)
      throw Components.results.NS_ERROR_NO_AGGREGATION;
    if (this.singleton == null)
      this.singleton = new grMailNotifications();
    return this.singleton.QueryInterface(aIID);
  }
};

var grMailNotificationsModule = {
  registerSelf: function(aCompMgr, aFileSpec, aLocation, aType)
  {
    aCompMgr = aCompMgr.QueryInterface(nsIComponentRegistrar);
    aCompMgr.registerFactoryLocation(CLASS_ID, CLASS_NAME, CONTRACT_ID,
                                     aFileSpec, aLocation, aType);

    var appInfo = Components.classes["@mozilla.org/xre/app-info;1"]
                            .getService(Components.interfaces.nsIXULAppInfo);
    if (appInfo.ID != THUNDERBIRD_ID)
      return; // we don't want to register here!

    var cm = Components.classes["@mozilla.org/categorymanager;1"]
                       .getService(nsICategoryManager);
    cm.addCategoryEntry("app-startup", CLASS_NAME, "service," + CONTRACT_ID,
                        true, true);
  },

  unregisterSelf: function(aCompMgr, aLocation, aType)
  {
    aCompMgr = aCompMgr.QueryInterface(nsIComponentRegistrar);
    aCompMgr.unregisterFactoryLocation(CLASS_ID, aLocation);
  },

  getClassObject: function(aCompMgr, aCID, aIID)
  {
    if (!aIID.equals(Components.interfaces.nsIFactory))
      throw Components.results.NS_ERROR_NOT_IMPLEMENTED;

    if (aCID.equals(CLASS_ID))
      return grMailNotificationsFactory;

    throw Components.results.NS_ERROR_NO_INTERFACE;
  },

  canUnload: function(aCompMgr)
  {
    return true;
  }
};

function NSGetModule(aCompMgr, aFileSpec)
{
  return grMailNotificationsModule;
}
