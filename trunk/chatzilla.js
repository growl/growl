//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

plugin.id = 'growl';

const GROWL_BUNDLE_LOCATION = "chrome://growl/locale/notifications.properties";

plugin.init =
function init(glob)
{
  /* This function is called when Chatzilla first loads the plugin. */
  plugin.major = 0;
  plugin.minor = 1;
  plugin.version = plugin.major + "." + plugin.minor;
  plugin.description = "Displays growl notifications for chatzilla."

  display(replaceColorCodes ('%B%C02') +
          plugin.id + ' plugin version ' + plugin.version + ' loaded.');

  // Registering handlers
  client.eventPump.addHook([{set: "user", type: "privmsg"}], growlPrivateMsg,
                           "grow-private-message-hook");
  client.eventPump.addHook([{set: "channel", type: "privmsg"}],
                           growlChannelMsg, "grow-channel-message-hook");
}


plugin.enable =
function enable()
{
  /* This function is called by Chatzilla when the
     command "/enable-plugin plugin-name" is issued. */
  display (plugin.id + ' enabled.');
  return true;
}

plugin.disable =
function disable()
{
  /* This function is called by Chatzilla when the
      command "/disable-plugin plugin-name" is issued. */
  display (plugin.id + ' disabled.');
  return true;
}

function growlGetString(aName)
{
  const nsIStringBundleService = Components.interfaces.nsIStringBundleService;
  var sbs = Components.classes["@mozilla.org/intl/stringbundle;1"]
                      .getService(nsIStringBundleService);
  var bundle = sbs.createBundle(GROWL_BUNDLE_LOCATION);
  return bundle.GetStringFromName(aName);
}

function growlGetFormattedString(aName, aValues)
{
  const nsIStringBundleService = Components.interfaces.nsIStringBundleService;
  var sbs = Components.classes["@mozilla.org/intl/stringbundle;1"]
                      .getService(nsIStringBundleService);
  var bundle = sbs.createBundle(GROWL_BUNDLE_LOCATION);
  return bundle.formatStringFromName(aName, aValues, aValues.length);
}

function growlSendNotification(aName, aImg, aTitle, aMsg, aObserver)
{
  var grn = Components.classes["@growl.info/notifications;1"]
                      .getService(Components.interfaces.grINotifications);
  grn.sendNotification(aName, aImg, aTitle, aMsg, aObserver);
}

function growlPrivateMsg(e)
{
  var evt = getObjectDetails(e.destObject);

  var name  = growlGetString("irc.pm.name");
  var img   = "chrome://chatzilla/skin/images/logo.png";
  var title = growlGetFormattedString("irc.pm.title", [evt.user.unicodeName]);
  var msg   = e.msg;

  growlSendNotification(name, img, title, msg, null);
}

function growlChannelMsg(e)
{
  var evt = getObjectDetails(e.destObject);

  var name  = growlGetString("irc.channel.message.name");
  var img   = "chrome://chatzilla/skin/images/logo.png";
  var title = growlGetFormattedString("irc.channel.message.title",
                                      [evt.channelName, e.user.unicodeName]);
  var msg   = e.msg;

  growlSendNotification(name, img, title, msg, null);
}
