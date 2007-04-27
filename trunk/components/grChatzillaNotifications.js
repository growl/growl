//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

////////////////////////////////////////////////////////////////////////////////
//// Constants

const nsISupports = Components.interfaces.nsISupports;
const nsIObserver = Components.interfaces.nsIObserver;
const nsIComponentRegistrar = Components.interfaces.nsIComponentRegistrar;
const nsICategoryManager = Components.interfaces.nsICategoryManager;
const nsIObserverService = Components.interfaces.nsIObserverService;
const nsIStringBundleService = Components.interfaces.nsIStringBundleService;
const nsIInstallLocation = Components.interfaces.nsIInstallLocation;
const grINotificationsList = Components.interfaces.grINotificationsList;

const CLASS_ID = Components.ID("07127806-ff59-413b-85c0-ccf9bca9a30c");
const CLASS_NAME = "Chatzilla Notifications";
const CONTRACT_ID = "@growl.info/chatzilla-notifications;1";

const CHATZILLA_ID = "{59c81df5-4b7a-477b-912d-4e0fdf64e5f2}";

const GROWL_BUNDLE_LOCATION = "chrome://growl/locale/notifications.properties";

////////////////////////////////////////////////////////////////////////////////
//// Implementation

function grChatzillaNotifications()
{
  this.grn = Components.classes["@growl.info/notifications;1"]
                      .getService(Components.interfaces.grINotifications);

  var sbs = Components.classes["@mozilla.org/intl/stringbundle;1"]
                      .getService(nsIStringBundleService);
  this.mBundle = sbs.createBundle(GROWL_BUNDLE_LOCATION);

  this.mObserverService = Components.classes["@mozilla.org/observer-service;1"]
                                    .getService(nsIObserverService);
  this.mObserverService.addObserver(this, "before-growl-registration", false);
}

grChatzillaNotifications.prototype = {
  // Chatzilla pref functions
  stringToArray: function pm_s2a(string)
  {
    if (string.search(/\S/) == -1)
      return [];

    var ary = string.split(/\s*;\s*/);
    for (var i = 0; i < ary.length; ++i)
      ary[i] = unescape(ary[i]);

     return ary;
  },
  arrayToString: function pm_a2s(ary)
  {
    var escapedAry = new Array()
    for (var i = 0; i < ary.length; ++i)
      escapedAry[i] = escape(ary[i]);

    return escapedAry.join("; ");
  },

  // nsIObserver
  observe: function observe(aSubject, aTopic, aData)
  {
    if (aTopic == "before-growl-registration") {
      this.mObserverService.removeObserver(this, "before-growl-registration");
      var appInfo = Components.classes["@mozilla.org/xre/app-info;1"]
                              .getService(Components.interfaces.nsIXULAppInfo);
      var em = Components.classes["@mozilla.org/extensions/manager;1"]
                         .getService(Components.interfaces.nsIExtensionManager);

      var installed = em.getInstallLocation(CHATZILLA_ID);
      if (appInfo.ID != CHATZILLA_ID && !installed)
        return; // we don't want to register anymore!

      this.registerHook();

      var nl = aSubject.QueryInterface(grINotificationsList);

      const notifications = [{key:"irc.pm.name", enabled:true},
                             {key:"irc.channel.imessage.name", enabled:true},
                             {key:"irc.channel.message.name", enabled:false},
                             {key:"irc.channel.join.name", enabled:true},
                             {key:"irc.channel.part.name", enabled:true},
                             {key:"irc.channel.quit.name", enabled:true},
                             {key:"irc.channel.invite.name", enabled:true},
                             {key:"irc.channel.kick.name", enabled:true}];

      for (var i = notifications.length - 1; i >= 0; i--) {
        var name = this.mBundle.GetStringFromName(notifications[i].key);
        nl.addNotification(name, notifications[i].enabled);
      }
    }
  },

  registerHook: function registerHook()
  {
    const ID = "growl@growl.info";
    const PREF = "extensions.irc.initialScripts";
    var file = Components.classes["@mozilla.org/extensions/manager;1"]
                         .getService(Components.interfaces.nsIExtensionManager)
                         .getInstallLocation(ID).getItemLocation(ID);
    file.append("chatzilla.js");
    var fph = Components.classes["@mozilla.org/network/protocol;1?name=file"]
                        .getService(Components.interfaces.nsIFileProtocolHandler);
    var path = fph.getURLSpecFromFile(file);

    var prefs = Components.classes["@mozilla.org/preferences-service;1"]
                          .getService(Components.interfaces.nsIPrefBranch);
    var value;
    try {
      value = prefs.getCharPref(PREF);
    } catch (e) {
      // it doesn't exist, so there is nothing
      value = "";
    }
    var arr = this.stringToArray(value);

    for (var i = arr.length - 1; i >= 0; i--) {
      if (arr[i] == path)
        return; // already registered
    }

    arr.push(path);
    prefs.setCharPref(PREF, this.arrayToString(arr));
  },

  QueryInterface: function(aIID)
  {
    if (aIID.equals(nsISupports) || aIID.equals(nsIObserver))
      return this;

    throw Components.results.NS_ERROR_NO_INTERFACE;
  }
}

var grChatzillaNotificationsFactory = {
  singleton: null,
  createInstance: function (aOuter, aIID)
  {
    if (aOuter != null)
      throw Components.results.NS_ERROR_NO_AGGREGATION;
    if (this.singleton == null)
      this.singleton = new grChatzillaNotifications();
    return this.singleton.QueryInterface(aIID);
  }
};

var grChatzillaNotificationsModule = {
  registerSelf: function(aCompMgr, aFileSpec, aLocation, aType)
  {
    aCompMgr = aCompMgr.QueryInterface(nsIComponentRegistrar);
    aCompMgr.registerFactoryLocation(CLASS_ID, CLASS_NAME, CONTRACT_ID,
                                     aFileSpec, aLocation, aType);

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
      return grChatzillaNotificationsFactory;

    throw Components.results.NS_ERROR_NO_INTERFACE;
  },

  canUnload: function(aCompMgr)
  {
    return true;
  }
};

function NSGetModule(aCompMgr, aFileSpec)
{
  return grChatzillaNotificationsModule;
}
