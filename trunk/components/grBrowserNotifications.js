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
const nsIObserver = Components.interfaces.nsIObserver;
const nsICategoryManager = Components.interfaces.nsICategoryManager;
const nsIObserverService = Components.interfaces.nsIObserverService;
const nsIStringBundleService = Components.interfaces.nsIStringBundleService;
const nsIDownload = Components.interfaces.nsIDownload;

const CLASS_ID = Components.ID("81777557-253a-43bc-bb54-7727af7b9980");
const CLASS_NAME = "Browser Notifications";
const CONTRACT_ID = "@growl.info/browser-notifications;1";

const FIREFOX_ID = "{ec8030f7-c20a-464f-9b0e-13a3a9e97384}";
const FLOCK_ID = "{a463f10c-3994-11da-9945-000d60ca027b}";

const GROWL_BUNDLE_LOCATION = "chrome://growl/locale/notifications.properties";

////////////////////////////////////////////////////////////////////////////////
//// Implementation

function grBrowserNotifications()
{
  this.grn = Components.classes["@growl.info/notifications;1"]
                       .getService(Components.interfaces.grINotifications);

  this.mObserverService = Components.classes["@mozilla.org/observer-service;1"]
                                    .getService(nsIObserverService);

  var sbs = Components.classes["@mozilla.org/intl/stringbundle;1"]
                      .getService(nsIStringBundleService);
  this.mBundle = sbs.createBundle(GROWL_BUNDLE_LOCATION);

  this.mObserverService.addObserver(this, "quit-application-granted", false);
  this.mObserverService.addObserver(this, "profile-after-change", false);

  this.mObserverService.notifyObservers(null, "growl-Wait for me to register",
                                        null);
}

grBrowserNotifications.prototype = {
  // nsIObserver
  observe: function observer(aSubject, aTopic, aData)
  {
    switch (aTopic) {
      case "profile-after-change":
        this.mObserverService.removeObserver(this, "profile-after-change");

        const notifications = ["download.start.title",
                               "download.finished.title",
                               "download.canceled.title",
                               "download.failed.title"];

        for (var i = notifications.length - 1; i >= 0; i--) {
          var name = this.mBundle.GetStringFromName(notifications[i]);
          this.grn.addNotification(name);
        }

        // Adding observers
        this.mObserverService.addObserver(this, "dl-start", false);
        this.mObserverService.addObserver(this, "dl-done", false);
        this.mObserverService.addObserver(this, "dl-cancel", false);
        this.mObserverService.addObserver(this, "dl-failed", false);

        // we need to tell everyone that we've done all we need to do with
        // registering
        this.mObserverService.notifyObservers(null, "growl-I'm done registering",
                                              null);
        break;
      case "quit-application-granted":
        this.mObserverService.removeObserver(this, "quit-application-granted");

        this.mObserverService.removeObserver(this, "dl-start");
        this.mObserverService.removeObserver(this, "dl-done");
        this.mObserverService.removeObserver(this, "dl-cancel");
        this.mObserverService.removeObserver(this, "dl-failed");
        break;
      case "dl-start":
        var name = this.mBundle.GetStringFromName("download.start.title");
        var img  = "chrome://growl/content/downloadIcon.png";
        var msg  = aSubject.QueryInterface(nsIDownload).displayName;
        this.grn.sendNotification(name, img, name, msg, null);
        break;
      case "dl-done":
        var name = this.mBundle.GetStringFromName("download.finished.title");
        var img  = "chrome://growl/content/downloadIcon.png";
        var msg  = aSubject.QueryInterface(nsIDownload).displayName;
        this.grn.sendNotification(name, img, name, msg, null);
        break;
      case "dl-cancel":
        var name = this.mBundle.GetStringFromName("download.canceled.title");
        var img  = "chrome://growl/content/downloadIcon.png";
        var msg  = aSubject.QueryInterface(nsIDownload).displayName;
        this.grn.sendNotification(name, img, name, msg, null);
        break;
      case "dl-failed":
        var name = this.mBundle.GetStringFromName("download.failed.title");
        var img  = "chrome://growl/content/downloadIcon.png";
        var msg  = aSubject.QueryInterface(nsIDownload).displayName;
        this.grn.sendNotification(name, img, name, msg, null);
        break;
      default:
    }
  },

  QueryInterface: function(aIID)
  {
    if (aIID.equals(nsISupports) || aIID.equals(nsIObserver))
      return this;

    throw Components.results.NS_ERROR_NO_INTERFACE;
  }
}

var grBrowserNotificationsFactory = {
  singleton: null,
  createInstance: function (aOuter, aIID)
  {
    if (aOuter != null)
      throw Components.results.NS_ERROR_NO_AGGREGATION;
    if (this.singleton == null)
      this.singleton = new grBrowserNotifications();
    return this.singleton.QueryInterface(aIID);
  }
};

var grBrowserNotificationsModule = {
  registerSelf: function(aCompMgr, aFileSpec, aLocation, aType)
  {
    aCompMgr = aCompMgr.QueryInterface(nsIComponentRegistrar);
    aCompMgr.registerFactoryLocation(CLASS_ID, CLASS_NAME, CONTRACT_ID,
                                     aFileSpec, aLocation, aType);

    var appInfo = Components.classes["@mozilla.org/xre/app-info;1"]
                            .getService(Components.interfaces.nsIXULAppInfo);
    if (appInfo.ID != FIREFOX_ID && appInfo.ID != FLOCK_ID)
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
      return grBrowserNotificationsFactory;

    throw Components.results.NS_ERROR_NO_INTERFACE;
  },

  canUnload: function(aCompMgr)
  {
    return true;
  }
};

function NSGetModule(aCompMgr, aFileSpec)
{
  return grBrowserNotificationsModule;
}
