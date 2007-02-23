//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

////////////////////////////////////////////////////////////////////////////////
//// Global Variables

const GROWL_EXTENSION_ID = "growl@growl.info";

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
    fwk.append("Growl.framework");

    fwk.copyTo(file, "Growl.framework");
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
    file.append("Growl.framework");
    return file.exists() && file.isDirectory();
  }
};
