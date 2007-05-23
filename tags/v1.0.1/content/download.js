//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

////////////////////////////////////////////////////////////////////////////////
//// Global Variables

var dialog;

////////////////////////////////////////////////////////////////////////////////
//// Ininilization/Destruction

window.addEventListener("load", Download_init, false);

function Download_init()
{
  dialog = new DownloadGrowlPrompt();
}

////////////////////////////////////////////////////////////////////////////////
//// Class DownloadGrowlPrompt

function DownloadGrowlPrompt()
{
  this.mData = window.arguments[0];
}
DownloadGrowlPrompt.prototype =
{
  accept: function accept()
  {
    this.mData.accepted = true;
    return true;
  }
};
