#!/usr/bin/perl

# Just install Growl and Mac::Growl, put this script in the
# X-Chat Aqua/Plugins/ folder, make sure the correct perl plugin is
# also in there, and then start X-Chat (or reload the perl plugin)

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

# this is a bad idea ... just proof of concept
my $image = 0;
my $uri_finder;
our $IMAGE;
if ($image) {
	eval 'require LWP::Simple; require URI::Find;';
	$image = $@ ? 0 : 1;
	$uri_finder = URI::Find->new(\&uri_finder) if $image;
}

# put hosts in here that you can talk to via remote Apple events,
# and get simple distributed messages
my @hosts = qw();

my $version;
if ($Mac::Growl::glue) {
	$Mac::Growl::glue->TIMEOUT(5);
	$version = $Mac::Growl::glue->prop('version');
}

sub _gethost {
	return unless $Mac::Growl::glue;
	my $found = 0;
	for my $host (@hosts) {
		$Mac::Growl::glue->ADDRESS(eppc => GrowlHelperApp => $host);
		$found = 1, last if &_alive;
	}
	$Mac::Growl::glue->ADDRESS if !$found;
}

sub _alive {
	return unless $Mac::Growl::glue;
	return defined $version->get;
}



Xchat::register('growl', '1.0');
Xchat::print("Loading Growl interface ...\n");

my($appname, $notification) = ('X-Chat Aqua', 'notify');
RegisterNotifications($appname, [$notification], [$notification], $appname);
Xchat::hook_server('PRIVMSG', \&privmsg);
Xchat::hook_print('Channel Msg Hilight', \&hilight);

for my $host (undef, @hosts) {
	if ($host) {
		$Mac::Growl::glue->ADDRESS(eppc => GrowlHelperApp => $host);
		next unless &_alive;
	}

	PostNotification(
		$appname, $notification,
		"$appname plugin loaded",
		"Growl interface loaded for perl $] and $Mac::Growl::base."
	);
}

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

	_gethost();

	my($filename);
	if ($image && $description) {
		if ($uri_finder->find(\$description)) {
			$filename = tmpnam();
			LWP::Simple::getstore($IMAGE, $filename);
			undef $IMAGE;
		}
	}

	PostNotification($appname, $notification, $title, $description, $sticky, $priority, $filename);
}

sub uri_finder {
	my($uri, $orig_uri) = @_;

	my @head = LWP::Simple::head($uri);
	if ($head[0] =~ /^image\//) {
		$IMAGE = $uri;
		return '[image]';
	} else {
		# auto-open URLs?  :-)
		return '[url]';
	}
}

1;
