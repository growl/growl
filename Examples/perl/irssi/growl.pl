use strict;
use warnings;

use vars qw($VERSION %IRSSI $Notes $AppName);

use Mac::Growl;

use Irssi;


$VERSION = 0.01;
%IRSSI = (
	authors		=>	'Nelson Elhage',
	contact		=>	'Hanji@users.sourceforge.net',
	name			=>	'Growl',
	description	=>	'Sends out Growl notifications for irssi.',
	license		=>	'BSD'
);

#This is a simple irssi script to send out Growl notifications using
#Mac::Growl. At the moment, it just sends out notifications for every
#privmsg you receive.

$Notes = ["irssi-privmsg"];
$AppName = "irssi";

Mac::Growl::RegisterNotifications($AppName,$Notes,$Notes);

sub event_privmsg
{
	my ($server, $data, $nick, $address) = @_;
	Mac::Growl::PostNotification($AppName,"irssi-privmsg","$nick","$data");
}

Irssi::signal_add_last("message private","event_privmsg");


#sub away_hilight_notice is what we need for away hilight notices
