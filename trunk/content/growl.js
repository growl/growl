//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

////////////////////////////////////////////////////////////////////////////////
//// Global Variables

const GROWL_EXTENSION_ID   = "growl@growl.info";
const GROWL_FRAMEWORK_NAME = "Growl-WithInstaller.framework";

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

    if (!this.frameworkInstalled) {
      this.installFramework();
    }
  },

  /**
   * Copies the framework over to the application.
   */
  installFramework: function installFramework()
  {
    var file = Components.classes["@mozilla.org/file/directory_service;1"]
                         .getService(Components.interfaces.nsIProperties)
                         .get("CurProcD", Components.interfaces.nsIFile);
    file = file.parent;
    file.append("Frameworks");
    if (!file.exists()) {
      file.create(Components.interfaces.nsIFile.DIRECTORY_TYPE, 0664);
    }

    var fwk = Components.classes["@mozilla.org/extensions/manager;1"]
                        .getService(Components.interfaces.nsIExtensionManager)
                        .getInstallLocation(GROWL_EXTENSION_ID)
                        .getItemLocation(GROWL_EXTENSION_ID);
    fwk.append(GROWL_FRAMEWORK_NAME);

    fwk.copyTo(file, GROWL_FRAMEWORK_NAME);

    //this.restartApp();
  },

  /**
   * Restarts the application
   */
  restartApp: function restartApp()
  {
    const nsIAppStartup = Components.interfaces.nsIAppStartup;

    var os = Components.classes["@mozilla.org/observer-service;1"]
                       .getService(Components.interfaces.nsIObserverService);
    var cancel = Components.classes["@mozilla.org/supports-PRBool;1"]
                           .createInstance(Components.interfaces.nsISupportsPRBool);
    os.notifyObservers(cancel, "quit-application-requested", null);

    if (cancel.data) return;

    os.notifyObservers(null, "quit-application-granted", null);

    var wm = Components.classes["@mozilla.org/appshell/window-mediator;1"]
                       .getService(Components.interfaces.nsIWindowMediator);
    var windows = wm.getEnumerator(null);
    while (windows.hasMoreElements()) {
      var win = windows.getNext();
      if (("tryToClose" in win) && !win.tryToClose()) return;
    }

    Components.classes["@mozilla.org/toolkit/app-startup;1"]
              .getService(nsIAppStartup)
              .quit(nsIAppStartup.eRestart | nsIAppStartup.eAttemptQuit);
  },

  //////////////////////////////////////////////////////////////////////////////
  //// Getters/Setters

  /**
   * Checks to see if the framework is found within the application.
   *
   * @return True if the framework is there, false otherwise.
   */
  get frameworkInstalled()
  {
    var file = Components.classes["@mozilla.org/file/directory_service;1"]
                         .getService(Components.interfaces.nsIProperties)
                         .get("CurProcD", Components.interfaces.nsIFile);
    file = file.parent;
    file.append("Frameworks");
    if (!file.exists()) return false;
    file.append(GROWL_FRAMEWORK_NAME);
    return file.exists() && file.isDirectory();
  }
};
