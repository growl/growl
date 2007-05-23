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
const grINotificationsList = Components.interfaces.grINotificationsList;

const CLASS_ID = Components.ID(/* XXX YOUR UUID HERE */);
const CLASS_NAME = "The name you'd like to give the class";
const CONTRACT_ID = "Your contract ID";

////////////////////////////////////////////////////////////////////////////////
//// Implementation

function sampleNotifications()
{
  this.mObserverService = Components.classes["@mozilla.org/observer-service;1"]
                                    .getService(nsIObserverService);

  this.mObserverService.addObserver(this, "before-growl-registration", false);
}

sampleNotifications.prototype = {
  // nsIObserver
  observe: function observer(aSubject, aTopic, aData)
  {
    switch (aTopic) {
      case "before-growl-registration":
        this.mObserverService.removeObserver(this, "before-growl-registration");

        var nl = aSubject.QueryInterface(grINotificationsList);

        const notifications = [{name:"notification name1", enabled:true},
                               {name:"notification name2", enabled:false}];

        for (var i = notifications.length - 1; i >= 0; i--) {
          var name = notifications[i].name;
          nl.addNotification(name, notifications[i].enabled);
        }

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

var sampleNotificationsFactory = {
  singleton: null,
  createInstance: function (aOuter, aIID)
  {
    if (aOuter != null)
      throw Components.results.NS_ERROR_NO_AGGREGATION;
    if (this.singleton == null)
      this.singleton = new sampleNotifications();
    return this.singleton.QueryInterface(aIID);
  }
};

var sampleNotificationsModule = {
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
      return sampleNotificationsFactory;

    throw Components.results.NS_ERROR_NO_INTERFACE;
  },

  canUnload: function(aCompMgr)
  {
    return true;
  }
};

function NSGetModule(aCompMgr, aFileSpec)
{
  return sampleNotificationsModule;
}
