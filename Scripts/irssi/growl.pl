#!/usr/bin/env perl -w
#
# This is a simple irssi script to send out Growl notifications using
# Mac::Growl. Currently, it sends notifications when your name is
# highlighted, and when you receive private messages.
#

use strict;
use vars qw($VERSION %IRSSI $Notes $AppName);

use Irssi;
use Mac::Growl;

$VERSION = '0.02';
%IRSSI = (
	authors		=>	'Nelson Elhage, Toby Peterson',
	contact		=>	'Hanji@users.sourceforge.net, toby@opendarwin.org',
	name		=>	'growl',
	description	=>	'Sends out Growl notifications for Irssi',
	license		=>	'BSD',
	url			=>	'http://growl.info/',
	changed		=>	'$Date$',
);

$Notes = ["privmsg", "hilight"];
$AppName = "irssi";

Mac::Growl::RegisterNotifications($AppName, $Notes, $Notes);

sub sig_message_private {
	my ($server, $data, $nick, $address) = @_;

	Mac::Growl::PostNotification($AppName, "privmsg", "$nick", "$data");
}

sub sig_print_text {
	my ($dest, $text, $stripped) = @_;

	if ($dest->{level} & MSGLEVEL_HILIGHT) {
		Mac::Growl::PostNotification($AppName, "hilight", $dest->{target}, $stripped);
	}
}

Irssi::signal_add_last('message private', \&sig_message_private);
Irssi::signal_add_last('print text', \&sig_print_text);
