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

$VERSION = '0.03';
%IRSSI = (
	authors		=>	'Nelson Elhage, Toby Peterson',
	contact		=>	'Hanji@users.sourceforge.net, toby@opendarwin.org',
	name		=>	'growl',
	description	=>	'Sends out Growl notifications for Irssi',
	license		=>	'BSD',
	url			=>	'http://growl.info/',
);

sub cmd_growl ($$$) {
	Irssi::print('%G>>%n Growl can be configured using two settings:');
	Irssi::print('%G>>%n growl_show_privmsg : Notify about private messages.');
	Irssi::print('%G>>%n growl_show_hilight : Notify when your name is hilighted.');
}

$Notes = ["privmsg", "hilight"];
$AppName = "irssi";

Mac::Growl::RegisterNotifications($AppName, $Notes, $Notes);

sub sig_message_private ($$$$) {
	return unless Irssi::settings_get_bool('growl_show_privmsg');

	my ($server, $data, $nick, $address) = @_;

	Mac::Growl::PostNotification($AppName, "privmsg", "$nick", "$data");
}

sub sig_print_text ($$$) {
	return unless Irssi::settings_get_bool('growl_show_hilight');

	my ($dest, $text, $stripped) = @_;

	if ($dest->{level} & MSGLEVEL_HILIGHT) {
		Mac::Growl::PostNotification($AppName, "hilight", $dest->{target}, $stripped);
	}
}

Irssi::command_bind('growl', 'cmd_growl');

Irssi::signal_add_last('message private', \&sig_message_private);
Irssi::signal_add_last('print text', \&sig_print_text);

Irssi::settings_add_bool($IRSSI{'name'}, 'growl_show_privmsg', 1);
Irssi::settings_add_bool($IRSSI{'name'}, 'growl_show_hilight', 1);

Irssi::print('%G>>%n '.$IRSSI{name}.' '.$VERSION.' loaded (/growl for help)');
