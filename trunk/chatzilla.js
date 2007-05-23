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
  plugin.major = 1;
  plugin.minor = 0;
  plugin.version = plugin.major + "." + plugin.minor;
  plugin.description = "Displays growl notifications for chatzilla."

  display(replaceColorCodes ('%B%C02') +
          plugin.id + ' plugin version ' + plugin.version + ' loaded.');

  // Registering handlers
  client.eventPump.addHook([{set: "user", type: "privmsg"}], growlPrivateMsg,
                           "grow-private-message-hook");
  client.eventPump.addHook([{set: "channel", type: "privmsg"}],
                           growlChannelMsg, "grow-channel-message-hook");
  client.eventPump.addHook([{set: "channel", type: "join"}],
                           growlChannelJoin, "grow-channel-join-hook");
  client.eventPump.addHook([{set: "channel", type: "part"}],
                           growlChannelPart, "grow-channel-part-hook");
  client.eventPump.addHook([{set: "server", type: "quit"}],
                           growlNetworkQuit, "grow-channel-quit-hook");
  client.eventPump.addHook([{set: "network", type: "invite"}],
                           growlChannelInvite, "grow-channel-invite-hook");
  client.eventPump.addHook([{set: "channel", type: "kick"}],
                           growlChannelKick, "grow-channel-kick-hook");
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

var growlObserver =
{
  observe: function observer(aSubject, aTopic, aData)
  {
    switch (aTopic) {
      case "alertclickcallback":
        var wm = Components.classes["@mozilla.org/appshell/window-mediator;1"]
                           .getService(Components.interfaces.nsIWindowMediator);
        var win = wm.getMostRecentWindow("irc:chatzilla");
        if (win)
          win.focus();

        var grn = Components.classes["@growl.info/notifications;1"]
                            .getService(Components.interfaces.grINotifications);
        grn.makeAppFocused();
        break;
      default:
    }
  }
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

  growlSendNotification(name, img, title, msg, growlObserver);
}

function growlChannelMsg(e)
{
  var evt = getObjectDetails(e.destObject);

  var name;
  if (msgIsImportant(e.msg, e.user.unicodeName, evt.network))
    name = growlGetString("irc.channel.imessage.name");
  else
    name = growlGetString("irc.channel.message.name");
  var img   = "chrome://chatzilla/skin/images/logo.png";
  var title = growlGetFormattedString("irc.channel.message.title",
                                      [evt.channelName, e.user.unicodeName]);
  var msg   = e.msg;

  growlSendNotification(name, img, title, msg, growlObserver);
}

function growlChannelJoin(e)
{
  var evt = getObjectDetails(e.destObject);

  var name  = growlGetString("irc.channel.join.name");
  var img   = "chrome://chatzilla/skin/images/logo.png";
  var title = evt.network.unicodeName;
  var msg   = growlGetFormattedString("irc.channel.join.msg",
                                      [e.user.unicodeName, evt.channelName]);

  growlSendNotification(name, img, title, msg, growlObserver);
}

function growlChannelPart(e)
{
  var evt = getObjectDetails(e.destObject);

  var name  = growlGetString("irc.channel.part.name");
  var img   = "chrome://chatzilla/skin/images/logo.png";
  var title = evt.network.unicodeName;
  var msg   = growlGetFormattedString("irc.channel.part.msg",
                                      [e.user.unicodeName, e.channel.unicodeName]);

  growlSendNotification(name, img, title, msg, growlObserver);
}

function growlNetworkQuit(e)
{
  var evt = getObjectDetails(e.destObject);

  var name  = growlGetString("irc.network.quit.name");
  var img   = "chrome://chatzilla/skin/images/logo.png";
  var title = "";//evt.server.unicodeName;
  var msg   = growlGetFormattedString("irc.network.quit.msg",
                                      [e.user.unicodeName, e.decodeParam(1)]);

  growlSendNotification(name, img, title, msg, growlObserver);
}

function growlChannelInvite(e)
{
  var evt = getObjectDetails(e.destObject);

  var name  = growlGetString("irc.channel.invite.name");
  var img   = "chrome://chatzilla/skin/images/logo.png";
  var title = evt.network.unicodeName;
  var msg   = growlGetFormattedString("irc.channel.invite.msg",
                                      [e.user.unicodeName, e.decodeParam(1),
                                       e.channel.unicodeName]);

  growlSendNotification(name, img, title, msg, growlObserver);
}

function growlChannelKick(e)
{
  var evt = getObjectDetails(e.destObject);

  var name  = growlGetString("irc.channel.kick.name");
  var img   = "chrome://chatzilla/skin/images/logo.png";
  var title = evt.network.unicodeName;
  var msg   = growlGetFormattedString("irc.channel.kick.msg",
                                      [e.user.unicodeName, e.lamer.unicodeName,
                                       e.channel.unicodeName, e.reason]);

  growlSendNotification(name, img, title, msg, growlObserver);
}
