//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

////////////////////////////////////////////////////////////////////////////////
//// Global Variables

const GROWL_EXTENSION_ID   = "growl@growl.info";
const GROWL_FRAMEWORK_NAME = "Growl.framework";

var gGrowl;

////////////////////////////////////////////////////////////////////////////////
//// Ininilization/Destruction

window.addEventListener("load", Growl_init, false);

function Growl_init()
{
  gGrowl = new GrowlNotifications();
  gGrowl.init();
}

////////////////////////////////////////////////////////////////////////////////
//// Class GrowlNotifications

function GrowlNotifications()
{
}
GrowlNotifications.prototype =
{
  //////////////////////////////////////////////////////////////////////////////
  //// Methods

  /**
   * Sets up our environment to ensure that everything will work.
   */
  init: function init()
  {
    // check for mac first!
    if (!/Mac/.test(navigator.platform)) {
      Components.utils.reportError("Growl Notifications only works on OSX!");
      Components.classes["@mozilla.org/extensions/manager;1"]
                .getService(Components.interfaces.nsIExtensionManager)
                .uninstallItem(GROWL_EXTENSION_ID);
      return;
    }

    var gab = Components.classes["@growl.info/application-bridge;1"]
                        .getService(Components.interfaces.grIApplicationBridge);
    if (!gab.growlInstalled) {
      window.setTimeout(this.promptForGrowlDownload, 5000);
    }
  },

  promptForGrowlDownload: function promptForGrowlDownload()
  {
    var out = { accepted: false };
    window.openDialog("chrome://growl/content/download.xul", "DownloadPrompt",
                      "chrome,modal,centerscreen", out);

    if (out.accepted) {
      // when this is called from setTimeout, this doesn't point to the object
      gGrowl.sendToGrowlHomepage();
    }
  },

  sendToGrowlHomepage: function sendToGrowlHomepage()
  {
    const HOMEPAGE = "http://growl.info/";

    if (gBrowser && ("addTab" in gBrowser)) {
      gBrowser.selectedTab = gBrowser.addTab(HOMEPAGE);
    } else {
      var uri = Components.classes["@mozilla.org/network/io-service;1"]
                          .getService(Components.interfaces.nsIIOService)
                          .newURI(HOMEPAGE, null, null);
      var eps = Components.classes["@mozilla.org/uriloader/external-helper-app-service;1"]
                          .createInstance(Components.interfaces.nsIExternalProtocolService);

      eps.loadUrl(uri);
    }
  }
};
