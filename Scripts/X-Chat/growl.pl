#!/usr/bin/perl

# http://www.xchat.org/docs/xchat2-perl.html
package Xchat::Mac::Growl;

use strict;
BEGIN { # Foundation clashes with perl lib in X-Chat ...
	$Mac::Growl::base = 'Mac::Glue';
}

use Mac::Growl 0.62;
use Mac::Growl ':all';
use File::Spec::Functions qw(catfile tmpdir);
use File::Temp qw(tmpnam);

Xchat::register('growl', '1.0');
Xchat::print("Loading Growl interface ...\n");

my($appname, $notification) = ('X-Chat Aqua', 'notify');
RegisterNotifications($appname, [$notification], [$notification], $appname);
Xchat::hook_server('PRIVMSG', \&privmsg);
Xchat::hook_print('Channel Msg Hilight', \&hilight);

PostNotification(
	$appname, $notification,
	"$appname plugin loaded",
	"Growl interface loaded for perl $] and $Mac::Growl::base."
);

sub privmsg {
	my($msgs, $words) = @_;

	return if $msgs->[2] =~ /^[#@]/;

	my($user) = $msgs->[0] =~ /^:(.+)!/;
	(my $msg = $words->[3]) =~ s/^://;

	notify("Privmsg from $user", $msg, 0, 2);

	return Xchat::EAT_NONE;
}

sub hilight {
	my($msgs) = @_;

	notify("Msg from $msgs->[0]", $msgs->[1], 0, -2);

	return Xchat::EAT_NONE;
}

sub notify {
	my($title, $description, $sticky, $priority) = @_;
	PostNotification($appname, $notification, $title, $description, $sticky, $priority);
}

1;
