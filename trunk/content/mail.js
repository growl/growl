//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

////////////////////////////////////////////////////////////////////////////////
//// Global Variables

const GROWL_MSG_FLAG_NEW = 0x10000;

var gGrowlMail;

////////////////////////////////////////////////////////////////////////////////
//// Ininilization/Destruction

window.addEventListener("load", GrowlMail_init, false);

function GrowlMail_init()
{
  gGrowlMail = new GrowlMailNotifications();
  gGrowlMail.init();
}

////////////////////////////////////////////////////////////////////////////////
//// Class GrowlMailNotifications

function GrowlMailNotifications()
{
  const nsIObserverService = Components.interfaces.nsIObserverService;
  const nsIStringBundleService = Components.interfaces.nsIStringBundleService;

  this.mObserverService = Components.classes["@mozilla.org/observer-service;1"]
                                    .getService(nsIObserverService);

  var sbs = Components.classes["@mozilla.org/intl/stringbundle;1"]
                      .getService(nsIStringBundleService);
  this.mBundle = sbs.createBundle(GROWL_BUNDLE_LOCATION);
}
GrowlMailNotifications.prototype =
{
  init: function init()
  {
    const nsIFolderListener = Components.interfaces.nsIFolderListener;
    var mms = Components.classes["@mozilla.org/messenger/services/session;1"]
                        .getService(Components.interfaces.nsIMsgMailSession);
    mms.AddFolderListener(this, nsIFolderListener.added);

    this.mObserverService.addObserver(this, "quit-application-granted", false);

    var grn = Components.classes["@growl.info/notifications;1"]
                        .getService(Components.interfaces.grINotifications);
    grn.addNotification(this.mBundle.GetStringFromName("mail.new.title"));
    grn.registerAppWithGrowl();

    var prefs = Components.classes["@mozilla.org/preferences-service;1"]
                          .getService(Components.interfaces.nsIPrefBranch);
    prefs.setBoolPref("extensions.growl.initialized.mail", true);
  },

  OnItemAdded: function OnItemAdded(aParentItem, aItem)
  {
    var header = aItem.QueryInterface(Components.interfaces.nsIMsgDBHdr);
    var folder = header.folder;

    if (header.flags & GROWL_MSG_FLAG_NEW) {
      var name = this.mBundle.GetStringFromName("mail.new.title");
      var ttle = name + " - " + folder.prettiestName;
      var data = [header.subject, header.author];
      var msg  = this.mBundle.formatStringFromName("mail.new.text", data, 2);
      var img  = "chrome://growl/content/new-mail-alert.png";

      var grn = Components.classes["@growl.info/notifications;1"]
                          .getService(Components.interfaces.grINotifications);
      grn.sendNotification(name, img, ttle, msg, null);
    }
  },

  observe: function observer(aSubject, aTopic, aData)
  {
    if (aSubject == "quit-application-granted") {
      var prefs = Components.classes["@mozilla.org/preferences-service;1"]
                            .getService(Components.interfaces.nsIPrefBranch);
      prefs.setBoolPref("extensions.growl.initialized.mail", false);

      this.mObserverService.removeObserver(this, "quit-application-granted");
    }
  }
};
