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
const nsIStringBundleService = Components.interfaces.nsIStringBundleService;
const nsIFolderListener = Components.interfaces.nsIFolderListener;

const CLASS_ID = Components.ID("33f659ee-9334-4f28-a742-344d95a520c4");
const CLASS_NAME = "Mail Notifications";
const CONTRACT_ID = "@growl.info/mail-notifications;1";

const THUNDERBIRD_ID = "{3550f703-e582-4d05-9a08-453d09bdfdc6}";

const GROWL_BUNDLE_LOCATION = "chrome://growl/locale/notifications.properties";
const MSG_FLAG_NEW = 0x10000;

////////////////////////////////////////////////////////////////////////////////
//// Implementation

function grMailNotifications()
{
  this.grn = Components.classes["@growl.info/notifications;1"]
                      .getService(Components.interfaces.grINotifications);

  var sbs = Components.classes["@mozilla.org/intl/stringbundle;1"]
                      .getService(nsIStringBundleService);
  this.mBundle = sbs.createBundle(GROWL_BUNDLE_LOCATION);

  const notifications = ["mail.new.title"];

  for (var i = notifications.length - 1; i >= 0; i--)
    this.grn.addNotification(this.mBundle.GetStringFromName(notifications[i]));

  // registering listeners
  var mms = Components.classes["@mozilla.org/messenger/services/session;1"]
                      .getService(Components.interfaces.nsIMsgMailSession);
  mms.AddFolderListener(this, nsIFolderListener.added);

  this.grn.registerAppWithGrowl();
}

grMailNotifications.prototype = {
  // nsIFolderListener
  OnItemAdded: function OnItemAdded(aParentItem, aItem)
  {
    var header = aItem.QueryInterface(Components.interfaces.nsIMsgDBHdr);
    var folder = header.folder;

    if (header.flags & MSG_FLAG_NEW) {
      var name = this.mBundle.GetStringFromName("mail.new.title");
      var ttle = name + " - " + folder.prettiestName;
      var data = [header.subject, header.author];
      var msg  = this.mBundle.formatStringFromName("mail.new.text", data, 2);
      var img  = "chrome://growl/content/new-mail-alert.png";

      this.grn.sendNotification(name, img, ttle, msg, null);
    }
  },

  QueryInterface: function(aIID)
  {
    if (aIID.equals(nsISupports) || aIID.equals(nsIFolderListener))
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
