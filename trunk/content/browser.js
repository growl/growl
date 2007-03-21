//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

////////////////////////////////////////////////////////////////////////////////
//// Global Variables

var gGrowlBrowser;

////////////////////////////////////////////////////////////////////////////////
//// Ininilization/Destruction

window.addEventListener("load", GrowlBrowser_init, false);

function GrowlBrowser_init()
{
  gGrowlBrowser = new GrowlBrowserNotifications();
  gGrowlBrowser.init();
}

////////////////////////////////////////////////////////////////////////////////
//// Class GrowlBrowserNotifications

function GrowlBrowserNotifications()
{
  const nsIObserverService = Components.interfaces.nsIObserverService;
  const nsIStringBundleService = Components.interfaces.nsIStringBundleService;

  this.mObserverService = Components.classes["@mozilla.org/observer-service;1"]
                                    .getService(nsIObserverService);

  var sbs = Components.classes["@mozilla.org/intl/stringbundle;1"]
                      .getService(nsIStringBundleService);
  this.mBundle = sbs.createBundle(GROWL_BUNDLE_LOCATION);
}
GrowlBrowserNotifications.prototype =
{
  init: function init()
  {
    var prefs = Components.classes["@mozilla.org/preferences-service;1"]
                          .getService(Components.interfaces.nsIPrefBranch);
    var init = prefs.getBoolPref("extensions.growl.initialized.browser");
    if (init) return; // we already did this, so exit gracefully

    this.mObserverService.addObserver(this, "quit-application-granted", false);

    const notifications = ["download.start.title",
                           "download.finished.title",
                           "download.canceled.title",
                           "download.failed.title"];

    var grn = Components.classes["@growl.info/notifications;1"]
                        .getService(Components.interfaces.grINotifications);
    for (var i = notifications.length - 1; i >= 0; i--)
      grn.addNotification(this.mBundle.GetStringFromName(notifications[i]));

    this.addObservers();

    grn.registerAppWithGrowl();
    prefs.setBoolPref("extensions.growl.initialized.browser", true);
  },

  addObservers: function addObservers()
  {
    this.mObserverService.addObserver(this, "dl-start", false);
    this.mObserverService.addObserver(this, "dl-done", false);
    this.mObserverService.addObserver(this, "dl-cancel", false);
    this.mObserverService.addObserver(this, "dl-failed", false);
  },

  observe: function observe(aSubject, aTopic, aData)
  {
    const nsIDownload = Components.interfaces.nsIDownload;

    var grn = Components.classes["@growl.info/notifications;1"]
                        .getService(Components.interfaces.grINotifications);

    switch (aTopic) {
      case "quit-application-granted":
        var prefs = Components.classes["@mozilla.org/preferences-service;1"]
                              .getService(Components.interfaces.nsIPrefBranch);
        prefs.setBoolPref("extensions.growl.initialized.browser", false);

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
        grn.sendNotification(name, img, name, msg, null);
        break;
      case "dl-done":
        var name = this.mBundle.GetStringFromName("download.finished.title");
        var img  = "chrome://growl/content/downloadIcon.png";
        var msg  = aSubject.QueryInterface(nsIDownload).displayName;
        grn.sendNotification(name, img, name, msg, null);
        break;
      case "dl-cancel":
        var name = this.mBundle.GetStringFromName("download.canceled.title");
        var img  = "chrome://growl/content/downloadIcon.png";
        var msg  = aSubject.QueryInterface(nsIDownload).displayName;
        grn.sendNotification(name, img, name, msg, null);
        break;
      case "dl-failed":
        var name = this.mBundle.GetStringFromName("download.failed.title");
        var img  = "chrome://growl/content/downloadIcon.png";
        var msg  = aSubject.QueryInterface(nsIDownload).displayName;
        grn.sendNotification(name, img, name, msg, null);
        break;
      default:
        Components.utils.reportError("Unexpected topic for browser - " + aTopic);
    }
  }
};
